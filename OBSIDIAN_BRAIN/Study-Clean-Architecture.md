# Clean-Architecture

> Arquitectura en capas independientes propuesta por Robert C. Martin
> Parte de [[Study-Carpeta-Estudio]]

## Capas (de afuera hacia adentro)

### Entities (Núcleo)
- Reglas de negocio puras
- No dependen de nada externo

### Use Cases
- Casos de uso de la aplicación
- Orquestan el flujo de datos

### Interface Adapters
- Controllers, Gateways, Presenters
- Convierten datos entre externos y use cases

### Frameworks & Drivers
- DB, Web, UI, External Services
- Capa más externa, detalles de implementación

## Regla de Dependencias
- Las dependencias solo van hacia adentro
- El núcleo no conoce nada de afuera

## Beneficios
- Testeable independientemente
- Independiente de frameworks
- Independiente de UI
- Independiente de DB

## Relacionado con
- [[Study-Carpeta-Estudio]]
- [[Hexagonal-Architecture]]
- [[Study-Domain-Driven-Design]]