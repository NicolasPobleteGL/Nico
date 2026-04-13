# Endpoint-Scraper-Patentes

> Scraping de información vehicular con Puppeteer + Express
> Vinculado desde [[Permisodecirculacion.cl]]

## Situación Actual

### Stack
- **Backend:** Express.js (Node.js)
- **Scraper:** Puppeteer (headless Chrome)
- **Proxy:** Residencial rotativo
- **Frontend:** Un botón "Buscar Patente"
- **Objetivo:** Extraer datos vehiculares de servicios externos

### Problema
- El consumo se triplicará en 1 mes
- Latencia actual elevada (Puppeteer es lento)
- Proxy residencial tiene límites de requests/hora
- Disponibilidad comprometida bajo carga alta

---

## Soluciones Propuestas

### 1. Caché Inteligente (Prioridad ALTA)

**¿Por qué?**
- El 70% de las búsquedas son patentes repetidas
- Reduce llamadas al proxy/servicio externo drásticamente

**Implementación:**
```javascript
// Redis como caché
const redis = require('redis');
const client = redis.createClient();

async function buscarPatente(patente) {
  const cacheKey = `patente:${patente}`;
  const cached = await client.get(cacheKey);
  if (cached) return JSON.parse(cached); // < 5ms respuesta
  
  const data = await scraperService(patente);
  await client.setex(cacheKey, 3600, JSON.stringify(data)); // TTL 1h
  return data;
}
```

**TTL sugerido:**
- Patentes vigentes: 24 horas (los datos cambian poco)
- Patentes históricas: 7 días

---

### 2. Proxy Residencial → Proxy de Centro de Datos

**Comparativa:**

| Factor | Residencial | Data Center |
|--------|-------------|-------------|
| Costo por GB | $8-15 USD | $1-3 USD |
| Velocidad | 1-3 Mbps | 100 Mbps+ |
| Confiabilidad | Variable | 99.9% |
| Requests/hora | 100-500 | 10,000+ |
| Bloqueos | Menos | Algunos |

**Opción recomendada:**
- **BrightData** (Luminati) — proxy residencial + data center
- **SmartProxy** — económico y rápido
- **Oxylabs** — proxy de datos con rotación automática

**Arquitectura sugerida:**
```
Frontend → Express API → Proxy Rotativo → Servicio Externo
                ↓
           Redis Cache
```

---

### 3. Puppeteer → Playwright o Splinter

**Playwright vs Puppeteer:**

| Característica | Puppeteer | Playwright |
|----------------|-----------|------------|
| Velocidad | Lento | 2x más rápido |
| Recursos | Alto | 30% menor |
| Stabilidad | Media | Alta |
| Soporte | Google | Microsoft |
| API | Promises | Async/Await moderno |

**Cambio mínimo de código** — API similar

---

### 4. Servidor Local (Dedicated)

**¿Cuándo?**
- Cuando el tráfico triplicado supera los 10,000 requests/día
- Cuando el costo del proxy > costo del servidor

**Specs recomendadas:**
```
CPU: 8 cores (Ryzen 7 o Xeon)
RAM: 16 GB
Storage: 500 GB NVMe
Red: 1 Gbps
OS: Ubuntu 22.04
```

**Ejecutable:**
- 3x instancias regionales
- Round-robin DNS
- Health checks cada 30s

---

### 5. Cluster de Balanceo Horizontal (Escala Crítica)

**Arquitectura:**

```
                    [Load Balancer]
                    (Nginx/HAProxy)
                           |
        ┌────────────────┴────────────────┐
        ↓               ↓                ↓
  [Node-1]        [Node-2]          [Node-3]
  Express+Pupp  Express+Pupp      Express+Pupp
        |               |                |
        └───────────────┴────────────────┘
                       ↓
               [Redis Cache]
                       ↓
              [Base de Datos]
            (PostgreSQL/MySQL)
```

**Tecnología:**
- **PM2** para clustering local: `pm2 start server.js -i 3`
- **Nginx** como reverse proxy + load balancer
- **Redis** compartido para caché y sesiones
- **Docker Swarm** para orchestrar múltiples nodos

**Estrategia:**
1. Escalar horizontalmente añadiendo nodos
2. Cada nodo tiene su propia instancia de Puppeteer
3. Redis centraliza caché para evitar duplicados
4. Nginx distribuye requests por least_connections

---

### 6. Pre-warming (Anticipación de Carga)

**Estrategia:**
```javascript
// Job nocturno: precargar patentes más buscadas
cron.schedule('2 * * * *', async () => {
  const topPatentes = await db.query(
    'SELECT patente FROM busquedas GROUP BY patente ORDER BY COUNT(*) DESC LIMIT 100'
  );
  for (patente of topPatentes) {
    // Pre-cachear silenciosamente
    await buscarPatente(patente.patente);
  }
});
```

**Beneficio:** A las 8AM las patentes populares ya están en caché.

---

### 7. Rate Limiting por IP (Protección)

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100, // 100 requests por IP
  message: 'Demasiadas solicitudes. Intenta en 15 min.'
});

app.use('/api/buscar', limiter);
```

**Beneficio:**
- Previene abuso
- Protege el proxy de bans
- Asegura disponibilidad

---

## Roadmap de Implementación

### Fase 1 (Semana 1-2) — Inmediato
- [ ] Implementar Redis cache
- [ ] Cambiar TTL según tipo de patente
- [ ] Añadir rate limiting

### Fase 2 (Semana 3-4) — Escalabilidad Media
- [ ] Migrar a Playwright
- [ ] Evaluar proxy de data center
- [ ] Instalar segundo servidor

### Fase 3 (Mes 2) — Escala Completa
- [ ] Configurar PM2 cluster
- [ ] Implementar Nginx load balancer
- [ ] Deploy multi-nodo
- [ ] Pre-warming job

---

## Métricas a Monitorear

| Métrica | Objetivo |
|---------|----------|
| Latencia p95 | < 500ms (cache), < 3s (scraping) |
| Throughput | 1000 req/min |
| Error rate | < 1% |
| Cache hit rate | > 70% |
| Uptime | 99.9% |

---

## Relacionado con
- [[Permisodecirculacion.cl]]
- [[GearLabs]]
- [[AWS]]
- [[Patrones-de-Diseño]]

---

*Creado: 2026-04-13*
*Revisar mensualmente*