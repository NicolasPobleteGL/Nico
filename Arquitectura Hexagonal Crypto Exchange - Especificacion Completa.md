# CryptoHub Exchange — Arquitectura Hexagonal

## 1. Overview

CryptoHub es un exchange de criptomonedas decentralizado que permite a usuarios trading en tiempo real, gestión de wallets, y consulta de balances. La arquitectura sigue **Hexagonal Architecture (Ports & Adapters)** con énfasis en comunicación WebSocket para updates en tiempo real de precios, órdenes, y notificaciones.

**Stack Tecnológico:**
- **Lenguaje:** TypeScript / Node.js (v20+)
- **Runtime:** Node.js con ts-node para desarrollo, compiled para producción
- **Base de Datos:** PostgreSQL 15 (persistencia) + Redis 7 (cache & pub/sub)
- **WebSocket:** Native WebSocket Server (ws library) con JSON-RPC 2.0
- **API REST:** Express.js para operaciones no-críticas y webhooks
- **Cola de eventos:** Redis Pub/Sub para distribuir eventos internos
- **Testing:** Jest + Supertest

---

## 2. Capas de la Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          INPUT ADAPTERS                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐              │
│  │ WS       │  │ REST API │  │ Admin    │  │ Webhook      │              │
│  │ Gateway  │  │ Server   │  │ Panel    │  │ Receiver     │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘              │
│       │            │            │               │                      │
└───────┼────────────┼────────────┼───────────────┼──────────────────────┘
        │            │            │               │
        ▼            ▼            ▼               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            PORTS (INPUT)                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐              │
│  │OrderPort │  │WalletPort│ │QueryPort │  │AdminPort    │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘              │
└───────┼────────────┼────────────┼───────────────┼──────────────────────┘
        │            │            │               │
        ▼            ▼            ▼               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           CORE / DOMAIN                                  │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │
│  │  TradeEngine   │  │   OrderBook    │  │  PriceTicker   │             │
│  ├────────────────┤  ├────────────────┤  ├────────────────┤             │
│  │ MatchingEngine │  │  OrderTracker  │  │  PriceAggregator│            │
│  │ FeeCalculator  │  │  TradeExecutor │  │  VolumeTracker │             │
│  │ RiskManager   │  │  BalanceManager│  │  24hStats      │             │
│  └────────────────┘  └────────────────┘  └────────────────┘             │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │
│  │    Wallet      │  │     User       │  │   Notification │             │
│  ├────────────────┤  ├────────────────┤  ├────────────────┤             │
│  │ BalanceManager │  │   UserService  │  │  AlertManager  │             │
│  │ TransferEngine │  │  KYCManager   │  │  EmailService │             │
│  │ DepositManager │  │  SessionMgr   │  │  PushNotifier │             │
│  └────────────────┘  └────────────────┘  └────────────────┘             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
        │            │            │               │
        ▼            ▼            ▼               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           PORTS (OUTPUT)                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐              │
│  │PersistPort│ │ CachePort │ │NotifyPort│  │ExternalPort  │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘              │
└───────┼────────────┼────────────┼───────────────┼──────────────────────┘
        │            │            │               │
        ▼            ▼            ▼               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         OUTPUT ADAPTERS                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐              │
│  │PostgreSQL│  │  Redis   │  │ WS       │  │ External     │              │
│  │Adapter   │  │ Adapter  │  │ Publisher│  │ Feed Adapter │              │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘              │
│  ┌──────────┐  ┌──────────┐                                            │
│  │EmailSvc  │  │ SMS svc  │                                            │
│  └──────────┘  └──────────┘                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. INPUT ADAPTERS (Driving Adapters)

Son los puntos de entrada externos que reciben solicitudes de los clientes.

### 3.1 WSGateway
- **Propósito:** Servidor WebSocket principal para comunicación bidireccional en tiempo real
- **Puerto:** 8080 (WSS)
- **Protocolo:** JSON-RPC 2.0 sobre WebSocket
- **Autenticación:** JWT token en el handshake inicial
- **Funciones:**
  - `subscribe(channel)` — Suscribirse a canales (ticker, orderbook, trades, orders)
  - `unsubscribe(channel)` — Desuscribirse
  - `place_order` — Crear orden de compra/venta
  - `cancel_order` — Cancelar orden
  - `get_balance` — Consultar balance de wallet
  - `get_orderbook` — Obtener libro de órdenes
  - `get_open_orders` — Listar órdenes abiertas
- **Canales de eventos salientes:**
  - `ticker:{pair}` — Updates de precio en tiempo real (ej: `ticker:BTC-USD`)
  - `orderbook:{pair}` — Actualizaciones del libro de órdenes
  - `trade:{pair}` — Ejecutar trades
  - `order:{userId}` — Status de órdenes del usuario
  - `wallet:{userId}` — Updates de balance

### 3.2 RESTServer
- **Propósito:** API REST para operaciones no temps-critical y webhooks
- **Puerto:** 3000
- **Framework:** Express.js
- **Autenticación:** API Key (header `X-API-Key`) + HMAC signature
- **Endpoints principales:**
  - `POST /api/v1/webhook/trade` — Recebir trades externos
  - `GET /api/v1/health` — Health check
  - `GET /api/v1/pairs` — Listar pares de trading disponibles
  - `GET /api/v1/stats/24h` — Estadísticas 24h
  - `POST /api/v1/admin/reload-config` — Recargar config

### 3.3 AdminPanel
- **Propósito:** Panel administrativo para gestión de usuarios, pairs, y configuración
- **Puerto:** 3001 (solo localhost)
- **Funciones:**
  - Gestión de usuarios (enable/disable, KYC approval)
  - Crear/modificar pairs de trading
  - Adjustar fees y límites
  - Ver logs y métricas

### 3.4 WebhookReceiver
- **Propósito:** Recepc嫌弃 de eventos externos (confirmaciones de blockchain, etc)
- **Autenticación:** HMAC signature verification
- **Eventos recibidos:**
  - `deposit.confirmed` — Depósito confirmado en blockchain
  - `withdrawal.confirmed` — Retiro confirmado
  - `network.fee.updated` — Actualización de fees de red

---

## 4. CORE / DOMAIN

El núcleo de la aplicación. **No tiene dependencias externas**. Toda la lógica de negocio vive aquí.

### 4.1 TradeEngine
El motor de matching y ejecución de trades.

| Componente | Responsabilidad |
|------------|----------------|
| **MatchingEngine** | Emparejar órdenes buy/sell según precio y orden de llegada (FIFO). Recibe órdenes del OrderPort y genera trades. |
| **FeeCalculator** | Calcular fees de trading (maker/taker). Aplica descuentos por volumen. |
| **RiskManager** | Validar que el usuario tiene balance suficiente. Bloquear operaciones si hay sospecha de wash trading. |
| **TradeRecorder** | Registrar cada trade ejecutaddo en el evento `TradeExecuted` |

**Entidades:**
```typescript
interface Order {
  id: string;
  userId: string;
  pair: string;           // ej: "BTC-USD"
  side: 'buy' | 'sell';
  type: 'market' | 'limit';
  price?: number;         // solo para limit orders
  quantity: number;
  filled: number;
  status: 'pending' | 'open' | 'partial' | 'filled' | 'cancelled';
  createdAt: Date;
}
```

### 4.2 OrderBook
Gestión del libro de órdenes y tracking de estado.

| Componente | Responsabilidad |
|------------|----------------|
| **OrderTracker** | Mantener tracking de todas las órdenes activas por par. Indexado por precio. |
| **TradeExecutor** | Ejecutar el trade: debit balance del maker, credit al taker, generar evento. |
| **BalanceManager** | Gestionar locks de balance (fondos retenidos en órdenes abiertas). |

**Eventos del OrderBook:**
- `OrderPlaced` — Nueva orden agregada
- `OrderCancelled` — Orden cancelada
- `TradeExecuted` — Trade realizado
- `OrderBookUpdated` — Cambio en el libro (broadcast a subscribers)

### 4.3 PriceTicker
Agregación y distribución de datos de mercado.

| Componente | Responsabilidad |
|------------|----------------|
| **PriceAggregator** | Recibir trades ejecutados y actualizar precio actual, high, low, open. |
| **VolumeTracker** | Acumular volumen de trading en ventanas de tiempo. |
| **Stats24h** | Calcular estadísticas 24h (precio más alto, más bajo, volumen, % cambio). |
| **TickerBroadcaster** | Publicar updates de precio cada 100ms a subscribers via NotifyPort. |

### 4.4 Wallet
Gestión de wallets y balances.

| Componente | Responsabilidad |
|------------|----------------|
| **BalanceManager** | Mantener balances por usuario + currency. Actualizar en cada trade, depósito, retiro. |
| **TransferEngine** | Procesar transfers internos (sin comisiones). Validar disponibilidad de funds. |
| **DepositManager** | Procesar depósitos. Marcar como `pending` hasta confirmación de blockchain. |
| **WithdrawalManager** | Procesar retiros. Validar balance, generar transacción blockchain. |

**Entidades:**
```typescript
interface Wallet {
  userId: string;
  currency: string;       // ej: "BTC", "USD"
  available: number;     // Fondos disponibles para trading
  locked: number;         // Fondos bloqueados en órdenes abiertas
  total: number;          // available + locked
}

interface Transaction {
  id: string;
  userId: string;
  type: 'deposit' | 'withdrawal' | 'trade' | 'transfer';
  currency: string;
  amount: number;
  status: 'pending' | 'confirmed' | 'failed';
  createdAt: Date;
}
```

### 4.5 User
Gestión de usuarios y autenticación.

| Componente | Responsabilidad |
|------------|----------------|
| **UserService** | CRUD de usuarios. Registration, login, password reset. |
| **KYCManager** | Manejo de verificación KYC. Estados: `none`, `pending`, `approved`, `rejected`. |
| **SessionManager** | Gestionar sesiones WebSocket. JWT generation y validation. |
| **APIKeyManager** | Generar y revocar API keys para trading algorítmico. |

### 4.6 Notification
Sistema de notificaciones.

| Componente | Responsabilidad |
|------------|----------------|
| **AlertManager** | Gestionar alerts de precio configurados por usuarios. |
| **EmailService** | Enviar emails transaccionales (confirmaciones, reset password). |
| **PushNotifier** | Enviar push notifications via Firebase/APNs. |
| **WSNotifier** | Enviar mensajes via WebSocket a usuarios específicos. |

---

## 5. OUTPUT PORTS (Driven Ports)

Interfaces (contracts) que el core define. Las implementaciones concretas están en los Output Adapters.

### 5.1 PersistPort
```typescript
interface PersistPort {
  saveOrder(order: Order): Promise<void>;
  getOrder(orderId: string): Promise<Order | null>;
  getOpenOrders(userId: string, pair?: string): Promise<Order[]>;
  
  saveTrade(trade: Trade): Promise<void>;
  getTradeHistory(userId: string, pair?: string, limit?: number): Promise<Trade[]>;
  
  saveUser(user: User): Promise<void>;
  getUser(userId: string): Promise<User | null>;
  
  saveWallet(wallet: Wallet): Promise<void>;
  getWallet(userId: string, currency: string): Promise<Wallet | null>;
  
  saveTransaction(tx: Transaction): Promise<void>;
}
```

### 5.2 CachePort
```typescript
interface CachePort {
  set(key: string, value: string, ttl?: number): Promise<void>;
  get(key: string): Promise<string | null>;
  del(key: string): Promise<void>;
  
  // Orderbook cache
  setOrderBook(pair: string, orderbook: OrderBook): Promise<void>;
  getOrderBook(pair: string): Promise<OrderBook | null>;
  
  // Ticker cache
  setTicker(pair: string, ticker: Ticker): Promise<void>;
  getTicker(pair: string): Promise<Ticker | null>;
  
  // Pub/Sub para distribución de eventos
  publish(channel: string, message: string): Promise<void>;
  subscribe(channel: string, callback: (msg: string) => void): void;
}
```

### 5.3 NotifyPort
```typescript
interface NotifyPort {
  // WebSocket broadcasting
  broadcast(channel: string, message: object): void;
  sendToUser(userId: string, message: object): void;
  
  // Notificaciones
  sendEmail(to: string, subject: string, body: string): Promise<void>;
  sendPush(userId: string, title: string, body: string): Promise<void>;
  
  // Alerts
  triggerAlert(userId: string, alertType: string, data: object): void;
}
```

### 5.4 ExternalPort
```typescript
interface ExternalPort {
  // Integración con blockchain
  broadcastWithdrawal(tx: Withdrawal): Promise<string>; // returns blockchain tx hash
  getDepositConfirmations(txHash: string): Promise<number>;
  
  // Fees de red
  getNetworkFee(currency: string): Promise<number>;
  
  // Precios externos (para oracle)
  getExternalPrice(currency: string): Promise<number>;
}
```

---

## 6. OUTPUT ADAPTERS

Implementaciones concretas de los Output Ports.

### 6.1 PostgreSQLAdapter
- **Persistencia principal**
- **Tablas:** `users`, `orders`, `trades`, `wallets`, `transactions`, `api_keys`, `sessions`
- **ORM:** Knex.js para queries y migrations
- **Pool:** 10-20 conexiones máximo

### 6.2 RedisAdapter
- **Cache:** OrderBooks, Tickers, 24h stats
- **Pub/Sub:** Distribución de eventos entre instancias
- **Locks:** Distributted locks para operaciones críticas (prevent double-spending)

### 6.3 WSPublisher
- **Gestión de subscriptions** de clientes WebSocket
- **Fan-out** de mensajes a channels relevantes
- **Heartbeat** para detectar conexiones muertas

### 6.4 ExternalFeedAdapter
- **Blockchain Connector:** Conexión a nodes de Bitcoin/Ethereum para broadcast y query
- **Oracle:** Recibe precios externos de fontes confiables

### 6.5 EmailAdapter / SMSAdapter
- **Integración con SendGrid/Mailgun** para email
- **Twilio** para SMS (2FA)

---

## 7. Flujo de Datos - Ejemplo Completo

### Flujo de una Orden de Compra

```
1. CLIENTE (App/Web)
   └─> WSGateway: { method: "place_order", params: { pair: "BTC-USD", side: "buy", type: "limit", price: 50000, quantity: 0.5 } }
   
2. WSGATEWAY (Input Adapter)
   └─> valida JWT, parsea JSON-RPC
   └─> OrderPort.placeOrder()
   
3. ORDERPORT (Input Port)
   └─> TradeEngine.placeOrder()
   
4. TRADE ENGINE (Domain)
   ├─ valida balance con RiskManager
   ├─ crea Order con status "open"
   └─ MarketEngine.match() si type=market
   
5. MARKET ENGINE (Domain)
   ├─ busca órdenes sell en OrderBook
   ├─ si encuentra match: TradeExecutor.executeTrade()
   └─ si no: Order queda abierta, OrderBookUpdated event
   
6. ORDERBOOK (Domain)
   ├─ TradeExecutor:
   │  ├─ debit wallet del seller
   │  ├─ credit wallet del buyer  
   │  └─ fee al exchange
   └─ emit: TradeExecuted, OrderBookUpdated
   
7. PRICE TICKER (Domain)
   ├─ PriceAggregator.update(trade)
   └─ emit: TickerUpdated → TickerBroadcaster
   
8. NOTIFY PORT (Output Port)
   ├─ WSPublisher.broadcast("orderbook:BTC-USD", ...)
   ├─ WSPublisher.broadcast("trade:BTC-USD", ...)
   ├─ WSPublisher.broadcast("ticker:BTC-USD", ...)
   └─ WSPublisher.sendToUser(buyerId, { type: "order", order: ... })
   
9. CACHE PORT (Output Port)
   ├─ RedisAdapter.setOrderBook("BTC-USD", ...)
   └─ RedisAdapter.setTicker("BTC-USD", ...)
   
10. PERSIST PORT (Output Port)
    └─ PostgreSQLAdapter.saveOrder()
    └─ PostgreSQLAdapter.saveTrade()
    └─ PostgreSQLAdapter.saveTransaction()
    
11. RESPONSE va de vuelta por el mismo camino hasta el cliente
```

---

## 8. Canales WebSocket

| Canal | Dirección | Descripción |
|-------|-----------|-------------|
| `ticker:{pair}` | Server → Client | Precio actual, 24h stats ( cada 100ms para pairs activos) |
| `orderbook:{pair}` | Server → Client | Libro de órdenes completo o delta updates |
| `trade:{pair}` | Server → Client | Trade executado en tiempo real |
| `order:{userId}` | Server → Client | Updates de órdenes específicas del usuario |
| `wallet:{userId}` | Server → Client | Cambio de balance |
| `alert:{userId}` | Server → Client | Alerts de precio ejecutaddos |

---

## 9. Seguridad

| Mecanismo | Capa | Descripción |
|-----------|------|-------------|
| JWT Auth | WS Gateway | Token válido en handshake, expira en 24h |
| HMAC Signature | REST API | Cada request firmado con secret del usuario |
| Rate Limiting | WS Gateway | Max 10 orders/segundo por usuario |
| Balance Check | RiskManager | Double-check de balance antes de ejecutar |
| Distributed Lock | Redis | Previene double-spending en race conditions |
| Input Validation | All Ports | Sanitización de todos los inputs del Domain |

---

## 10. deployment

```
┌─────────────────────────────────────────────┐
│                 LOAD BALANCER                │
│           (Nginx / CloudFlare)               │
└─────────────┬───────────────┬────────────────┘
              │               │
    ┌─────────▼───┐   ┌───────▼───────┐
    │  WS Server  │   │  REST Server  │
    │  (Node.js)  │   │  (Express)    │
    └──────┬──────┘   └───────┬───────┘
           │                   │
    ┌──────▼──────────────────▼──────┐
    │         REDIS PUB/SUB          │
    │   (Event Distribution Bus)     │
    └──────┬──────────────────────┬──┘
           │                      │
    ┌──────▼──────┐        ┌──────▼──────┐
    │ WS Server 2 │        │ WS Server N │
    └─────────────┘        └─────────────┘
```

---

*Documento creado por Joi — 2026-04-03*
