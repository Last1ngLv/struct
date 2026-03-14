# KNOWLEDGE.md - Conocimiento del Dominio

## Warcraft III vJASS

### Conceptos Fundamentales
- **Triggers**: Código ejecutable en respuesta a eventos
- **Librerías**: Código reutilizable con `library` y `endlibrary`
- **Módulos**: Código reusable con `module` (Vexorian's JASS)
- **Structs**: Tipos de datos personalizados (extienden arrays)

### Sistemas de Handles
- **Units**: Entidades en el mapa
- **Dummies**: Unidades temporales para efectos
- **Effects**: Modelos visuales
- **Timers**: Contadores
- **Hashtables**: Almacenamiento clave-valor

### Eventos de Spells
- `EVENT_PLAYER_UNIT_SPELL_CHANNEL` - Inicio de cast
- `EVENT_PLAYER_UNIT_SPELL_EFFECT` - Efecto del spell
- `EVENT_PLAYER_UNIT_SPELL_FINISH` - Spell terminado
- `EVENT_PLAYER_UNIT_SPELL_ENDCAST` - Cast finalizado

## Conceptos de Proyectiles

### Ciclo de Vida
1. **Creación**: `Missile.create()`
2. **Configuración**: Set de propiedades
3. **Lanzamiento**: `launch()`
4. **Movimiento**: Actualización por timer
5. **Colisión**: Callback onCollide
6. **Destrucción**: onRemove o destino alcanzado

### Tipos de Colisión
- **CIRCLE**: Para velocidad < colisión (precisión buena, rendimiento óptimo)
- **RECTANGLE**: Para velocidad >= colisión (mejor precisión)

### Velocidad
- Unidad de medida: por frame
- Con TIMER_TIMEOUT = 1/32: velocidad * 32 = unidades/segundo

## Integraciones

### Spell System
- SpellIndex tracking de spells activos
- DummyCaster para lanzamiento
- RegisterPlayerUnitEvent para detección

### Sistema de Daño
- UnitDamageTarget para aplicar daño
- attacktype y damagetype configurables
- Validación previa con FilterUnits
