# CODING_RULES.md - Reglas de Código

## Reglas Generales

### Dependencias
- Declarar todas las dependencias en la línea `library`
- Usar `optional` para dependencias no obligatorias
- Verificar disponibilidad con `static if LIBRARY_Nombre`

### Validación
- Siempre verificar `GetUnitTypeId(u) == 0` antes de operaciones
- Usar `UnitAlive()` para verificar unidades vivas
- Validar parámetros antes de usarlos

### Manejo de Handles
- Siempre nullificar handles en `destroy()`
- Usar `SpellIndex.destroy()` que limpia automáticamente
- Destruir efectos, timers, lightnings en cleanup

### Reciclaje
- Respetar `WRITE_DELAYED_MISSILE_RECYCLING`
- No destruir dummies manualmente
- Usar el sistema de reciclaje de Missile

### Optimización
- Usar `SpellIndex.GLOBAL_GROUP` para enumeraciones
- Evitar创建 de boolexpr en loops
- Pre-calcular valores constantes
- Usar `constant function` para valores que no cambian

## Reglas Específicas

### Spells con Missile
1. Definir constantes de configuración al inicio
2. Crear función FilterUnits
3. Implementar struct con MissileStruct
4. Usar callbacks apropiados (onRemove, onCollide, etc.)
5. Registrar en Init

### Sistema de Loadout
1. Usar Table para almacenamiento por jugador
2. Slot calculation: `GetPlayerId(p) + 1`
3. Validar rangos (1 a MAX_PLAYER_SLOTS)
4. Proporcionar getters y setters

### Damage Text
1. Usar FormatLoadoutDamageText para formateo
2. Configurar color RGB
3. Velocidad y lifespan apropiados
