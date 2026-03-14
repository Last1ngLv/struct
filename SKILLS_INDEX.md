# Skills Index

Índice rápido de habilidades para consulta durante desarrollo.

## Por Tema

### vJASS
- **Library**: `library ... uses ... endlibrary` → `skills/vjass_core.md`
- **Module**: `implement MiModulo` → `skills/vjass_core.md`
- **Struct**: Tipos personalizados → `skills/vjass_core.md`
- **Textmacro**: `//! textmacro` → `skills/vjass_core.md`
- **Static if**: `static if LIBRARY_X` → `skills/vjass_core.md`

### Warcraft III
- **Coordenadas**: X, Y, Z → `skills/warcraft3_engine.md`
- **Unidades**: alive, enemy, structure → `skills/warcraft3_engine.md`
- **Efectos**: AddSpecialEffect → `skills/warcraft3_engine.md`
- **Pathability**: IsTerrainWalkable → `skills/warcraft3_engine.md`
- **Channeling**: IsUnitChanneling → `skills/warcraft3_engine.md`

### Triggers
- **Spell Effect**: RegisterSpellEffectEvent → `skills/triggers_system.md`
- **Spell Finish**: RegisterSpellFinishEvent → `skills/triggers_system.md`
- **Player Event**: RegisterPlayerUnitEvent → `skills/triggers_system.md`
- **Filter**: boolexpr → `skills/triggers_system.md`

### Gameplay
- **Missile**: Crear projectile → `skills/gameplay_systems.md`
- **SpellIndex**: Tracking → `skills/gameplay_systems.md`
- **Loadout**: Por jugador → `skills/gameplay_systems.md`
- **Damage**: UnitDamageTarget → `skills/gameplay_systems.md`
- **Text**: ShowCustomLoadoutText → `skills/gameplay_systems.md`

### Datos
- **Table**: Hashtable optimizado → `skills/data_structures.md`
- **Timer**: NewTimer, ReleaseTimer → `skills/data_structures.md`
- **Array**: Índices → `skills/data_structures.md`
- **Slot**: GetPlayerId + 1 → `skills/data_structures.md`

### Debug
- **Mensaje**: BJDebugMsg → `skills/debugging.md`
- **Error**: SimError → `skills/debugging.md`
- **Verificar**: Validación → `skills/debugging.md`

### Performance
- **Recycling**: Timer/Missile → `skills/performance.md`
- **Enum**: GroupEnumUnitsInRange → `skills/performance.md`
- **Filter**: Pre-crear → `skills/performance.md`
- **Constants**: constant function → `skills/performance.md`

## Por Caso de Uso

### "Quiero crear un spell nuevo"
→ `skills/gameplay_systems.md` + `skills/triggers_system.md`

### "Quiero hacer debug de un spell"
→ `skills/debugging.md` + `skills/gameplay_systems.md`

### "Quiero guardar datos por jugador"
→ `skills/data_structures.md` + `skills/gameplay_systems.md`

### "Quiero optimizar mi código"
→ `skills/performance.md` + `skills/data_structures.md`

### "No entiendo cómo funciona Missile"
→ `skills/gameplay_systems.md` + `knowledge/API_REFERENCE.md`

### "Qué dependencia necesito?"
→ `knowledge/DEPENDENCIES.md`

### "Cómo está estructurado el proyecto?"
→ `docs/ARCHITECTURE.md`

## Errores Comunes → Solución

| Error | Skill |
|-------|-------|
| Missile no se mueve | `gameplay_systems.md` - Olvidaste `launch()` |
| Daño a aliados | `gameplay_systems.md` - Falta `FilterUnits` |
| Memory leak | `performance.md` - No liberas recursos |
| Error de compilación | `vjass_core.md` - Revisa sintaxis |
| Spell no detecta | `triggers_system.md` - Revisa registro |

## Commandos de Referencia

```jass
// Crear missile
Missile.create(x, y, z, angle, distance, endZ)
missile.launch()

// Registrar spell
RegisterSpellEffectEvent(ABILITY, function OnEffect)

// Tracking
SpellIndex.create()
SpellIndex.destroy()

// Timer
NewTimer()
ReleaseTimer(t)

// Table
Table.create()
table[key] = value

// Debug
BJDebugMsg("msg")
SimError(player, "msg")
```
