# TECH_CHOICES.md - Elecciones Técnicas

## Lenguaje y Herramientas

### vJASS
- **Elección**: vJASS (JASS con extensiones)
- **Versión**: Compatible con JASShelper
- **Rationale**: Estándar para maps de Warcraft III

### Librerías Externas
| Librería | Versión | Propósito |
|----------|---------|-----------|
| Missile | 2.5.1 | Sistema de proyectiles |
| Table | 3.1.0.1 | Hashtable optimizado |
| TimerUtils | 2.0 | Reutilización de timers |
| DummyCaster | 2.0.0.1 | Lanzamiento de spells |
| RegisterPlayerUnitEvent | 5.1.0.1 | Eventos por jugador |

## Configuración de Missile

### Timer
```jass
public constant real TIMER_TIMEOUT = 1./32.
```

### Collision
```jass
public constant real MAXIMUM_COLLISION_SIZE = 197.
public constant integer COLLISION_TYPE_CIRCLE = 0
public constant integer COLLISION_TYPE_RECTANGLE = 1
```

### Opcionales Habilitadas
```jass
public constant boolean USE_COLLISION_Z_FILTER = true
public constant boolean WRITE_DELAYED_MISSILE_RECYCLING = true
```

## Formato de Datos

### Tabla de Jugadores
- Slot: `GetPlayerId(p) + 1`
- Rango: 1 a bj_MAX_PLAYER_SLOTS

### Store de Datos
- SpellIndex.data: Entero para referencia a SpellIndex
- Table: Para datos complejos por handle
