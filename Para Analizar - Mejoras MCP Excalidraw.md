# Ideas para Mejorar MCP de Obsidian / Excalidraw

Fecha: 2026-04-03

---

## Problema Identificado

El MCP actual de Obsidian solo tiene tools genéricas (read, write, search). No hay nada específico para Excalidraw. Crear diagrams a mano en JSON es lento y propenso a errores.

---

## Mejoras Posibles

### 1. Skill de Excalidraw más inteligente
- Un skill que entienda los componentes de Excalidraw (shapes, connectors, text, etc.)
- Crear el JSON más rápido con helpers

### 2. Templates pre-armados
- Diagramas comunes: flowchart, timeline, tree, matrix, hierarchy
- Solo le pasás datos y me encargo del JSON

### 3. Conversión mejorada
- Parsear JSON de Excalidraw y renderizar a PNG con ImageMagick
- Agregar íconos, badges, colores estandarizados

### 4. MCP tools custom para Excalidraw
- Crear tools específicas: `excalidraw_create_box`, `excalidraw_create_arrow`, `excalidraw_add_text`
- Encadenar llamadas para construir diagrams más fácil

### 5. Componentes reusables
- Headers estilizados
- Badges de estado (verde/rojo/amarillo)
- Iconos comunes (flechas, checkmarks, warnings)
- Conectores estándar

---

## Tareas Pendientes de Implementar

- [ ] Template de Excalidraw más robusto con helpers
- [ ] Script de conversión a PNG mejorado
- [ ] Nueva skill `excalidraw-helper`
- [ ] Componentes reusables (badges, headers, iconos)
- [ ] Tools MCP custom para Excalidraw

---

## Contexto Adicional

Nico mencionó que quiere que las 20 ideas de automation (diario automático, git activity digest, etc.) las pueda implementar sin su ayuda.

La idea es hacer el flujo de trabajo más autonomous.

---

## Notas

- Nico prefere que no envíe PNGs de Excalidraw a menos que lo pida
- Siempre agregar contenido DENTRO de los círculos en Excalidraw
- Texto centrado en nodos
