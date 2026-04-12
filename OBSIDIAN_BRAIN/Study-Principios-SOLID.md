# Principios-SOLID

> Los 5 principios fundamentales del diseño OOP
> Parte de [[Study-Carpeta-Estudio]]

## S — Single Responsibility Principle
> Una clase tiene una sola razón para cambiar
- Cada clase hace una cosa y la hace bien
- Facilita el mantenimiento y testing

## O — Open/Closed Principle  
> Abierto para extensión, cerrado para modificación
- Añadir funcionalidad sin cambiar código existente
- Usar herencia/interfaces

## L — Liskov Substitution Principle
> Los objetos de subclase deben poder sustituir a los de la clase padre
- Herencia correcta: "es un" verdadero
- No romper el contrato de la clase padre

## I — Interface Segregation Principle
> Mejor muchas interfaces específicas que una general
- No forzar a implementar métodos que no usa
- Clientes no dependen de métodos que no necesitan

## D — Dependency Inversion Principle
> Depender de abstracciones, no de concreciones
- Modulos de alto nivel no dependen de los de bajo
- Ambos dependen de abstracciones

## Relacionado con
- [[Study-Carpeta-Estudio]]
- [[Study-Clean-Architecture]]
- [[Study-Patrones-de-Diseño]]