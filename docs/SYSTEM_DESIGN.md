# SYSTEM_DESIGN.md - Diseño del Sistema

## Principios de Diseño

### 1. Modularidad
Cada sistema es independiente pero puede combinarse. Missile.j funciona sin otras librerías pero se integra con Table, TimerUtils, y DummyCaster.

### 2. Filosofía "Compiler Writes Code"
Missile implementa código opcional basado en constantes booleanas:
- `USE_COLLISION_Z_FILTER` - Filtro de eje Z
- `WRITE_DELAYED_MISSILE_RECYCLING` - Reciclaje diferido
- Si es `true` → código se incluye
- Si es `false` → código se ignora

### 3. Pattern MissileStruct
Los spells implementan lógica mediante un struct que implementa `MissileStruct`:
```jass
private struct MiSpell extends array
    implement MissileStruct
endstruct
```

### 4. Callbacks Disponibles
- `onLaunch` - Cuando el missile se lanza
- `onUpdate` - Cada frame del missile
- `onCollide` - Cuando colisiona con una unidad
- `onFinish` - Cuando alcanza su destino
- `onRemove` - Cuando se destruye el missile

## Patrones de Spell

### Spell Simple (Fireball)
1. Registrar evento con `RegisterSpellEffectEvent`
2. Crear Missile con `Missile.create`
3. Configurar propiedades (speed, damage, model)
4. Asignar source y owner
5. Llamar `launch()`

### Spell Complejo (Guided Arrow)
1. Usar SpellIndex para tracking
2. Implementar búsqueda de objetivo
3. Manejar múltiples fases
4. Usar enableHitAfter para pierce

## Manejo de Errores
- SimError para mensajes al jugador
- Tabla de errores en SpellIndex para debugging
- Validación de units antes de daño
