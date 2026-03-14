# Quick Start para Agentes

Copia y pega este contexto al inicio de cada sesión:

---

## Proyecto: Warcraft III vJASS Missile System

**Ubicación**: `C:\Users\Leon\Documents\struct\`

### Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `skills/gameplay_systems.md` | Cómo crear spells con Missile |
| `knowledge/API_REFERENCE.md` | Lista completa de funciones |
| `docs/CONVENTIONS.md` | Estilo del código |
| `knowledge/DEPENDENCIES.md` | Qué librería usar |

### Commands Más Comunes

```jass
// Crear missile
local Missile m = Missile.create(x, y, z, angle, dist, endZ)
set m.speed = 20.
set m.damage = 100.
set m.source = GetTriggerUnit()
set m.owner = GetTriggerPlayer()
call MiSpell.launch(m)

// Tracking con SpellIndex
local SpellIndex dex = SpellIndex.create()
set dex.source = source
set dex.target = target
set missile.data = dex

// En callback onRemove
call SpellIndex(missile.data).destroy()

// Timer
local timer t = NewTimer()
call SetTimerData(t, dex)
call ReleaseTimer(t)

// Registro de evento
call RegisterSpellEffectEvent(ABILITY, function OnEffect)
```

### Errores Comunes a Evitar

- ❌ `Missile.create()` sin `launch()` → missile no se mueve
- ❌ `UnitDamageTarget()` sin `FilterUnits()` → daño a aliados
- ❌ `NewTimer()` sin `ReleaseTimer()` → memory leak
- ❌ `SpellIndex` sin `destroy()` → memory leak

---

**Al trabajar**: Consulta `SKILLS_INDEX.md` para encontrar rápidamente la skill correcta.
