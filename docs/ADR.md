# ADR.md - Architecture Decision Records

## ADR-001: Sistema de Proyectiles Core

**Estado**: Aprobado
**Fecha**: Basado en Missile.j existente

### Contexto
Necesidad de un sistema de proyectiles flexible para Warcraft III.

### Decisión
Usar Missile.j como sistema core con configuración opcional.

### Consecuencias
- Positivas: Flexibilidad, modularidad, rendimiento
- Negativas: Curva de aprendizaje para nuevos desarrolladores

---

## ADR-002: SpellIndex para Tracking

**Estado**: Aprobado
**Fecha**: Basado en SpellIndex.j existente

### Contexto
Necesidad de rastrear spells activos con datos asociados.

### Decisión
Struct dedicado con auto-limpieza de handles.

### Consecuencias
- Positivas: API limpia, prevención de leaks
- Negativas: Una estructura fija puede ser limitante

---

## ADR-003: Tabla por Jugador para Loadout

**Estado**: Aprobado
**Fecha**: Basado en PlayerMissileLoadout existente

### Contexto
Sistema multiplayer requiere configuración por jugador.

### Decisión
Table con clave de handle de jugador + array de configuración.

### Consecuencias
- Positivas: Configuración individual, extensible
- Negativas: Más código que solución global
