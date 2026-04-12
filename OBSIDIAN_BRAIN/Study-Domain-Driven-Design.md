# Domain-Driven-Design

> Enfoque de diseño basado en el dominio (Evans, 2003)
> Parte de [[Study-Carpeta-Estudio]]

## Conceptos Clave

### Bounded Context
- Límite donde un modelo específico aplica
- Cada contexto tiene su propio lenguaje ubuo

### Ubiquitous Language
- Lenguaje compartido entre devs y domain experts
- Se usa en código, tests, documentación

### Aggregates
- Grupo de objetos relacionados
- Se manipulan como una unidad

### Entities vs Value Objects
- Entity: Identidad propia (ej: Usuario)
- Value Object: Sin identidad (ej: Dirección, Dinero)

### Domain Events
- Eventos que representan cambios en el dominio
- Útil para Event-Driven

## Capas DDD
1. **Domain** — Entidades, value objects, servicios de dominio
2. **Application** — Casos de uso, servicios de aplicación
3. **Infrastructure** — Persistencia, servicios externos
4. **Presentation** — UI, API

## Relacionado con
- [[Study-Carpeta-Estudio]]
- [[Study-Clean-Architecture]]
- [[Event-Driven-Architecture]]