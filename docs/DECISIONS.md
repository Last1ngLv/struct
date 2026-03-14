# DECISIONS.md - Decisiones Técnicas

## Decisiones Principales

### 1. Arquitectura de Missile
**Decisión**: Sistema de proyectiles como librería core independiente.
**Razón**: Permite uso sin otras dependencias, máxima flexibilidad.

### 2. Filosofía "Compiler Writes Code"
**Decisión**: Código opcional basado en constantes booleanas.
**Razón**: Optimización por proyecto, solo incluye código necesario.

### 3. SpellIndex para Tracking
**Decisión**: Usar struct dedicado para tracking de spells.
**Razón**: API limpia, auto-limpieza de handles, extensible.

### 4. PlayerMissileLoadout
**Decisión**: Sistema de configuración por jugador.
**Razón**: Permite personalización de missiles por jugador en sistemas multiplayer.

### 5. Sistema de Eventos
**Decisión**: Múltiples sistemas de eventos (SpellEffectEvent, SpellFinishEvent).
**Razón**: Diferentes puntos de interceptación para diferentes necesidades.

## Alternativas Consideradas

### Sistema de Daño
- **Alternativa**: Sistema de daño centralizado
- **Descartado**: Acoplamiento muy fuerte, difícil de mantener

### Unit Indexing
- **Alternativa**: Indexar todas las unidades
- **Descartado**: Overhead innecesario, usar handle id directamente

### Hashtable
- **Alternativa**: Hashtable nativa
- **Elegido**: Table de Bribe - mejor API, más rápido
