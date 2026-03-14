# DEPENDENCIES.md - Dependencias

## Dependencias del Proyecto

### Librerías Principales

```
Missile.j (Core)
├── Opcional: ErrorMessage (debug)
├── Opcional: WorldBounds (límites)
├── Opcional: MissileRecycler (reciclaje)
├── Opcional: Dummy (dummies)
├── Opcional: xedummy (dummies)
└── Opcional: UnitIndexer (indexación)
```

```
SpellIndex.j
├── Table
├── Missile
├── TimerUtils
├── DummyCaster
├── WorldBounds
├── SpellEffectEvent
└── RegisterPlayerUnitEvent
```

```
Loadout Control.j
├── SpellIndex
├── Missile
├── PlayerMissileLoadout
├── IsUnitChanneling
├── DamageTextUtil
├── LoadoutOrbBalance (?)
├── LoadoutIntFullManaSwapNew (?)
└── Table
```

```
IsUnitChanneling.j
├── RegisterPlayerUnitEvent (requerido)
├── Opcional: UnitIndexer
└── Opcional: Table
```

```
SpellFinishEvent.j
├── RegisterPlayerUnitEvent (requerido)
└── Opcional: Table
```

## Diagrama de Dependencias

```
                    ┌─────────────────┐
                    │     Missile    │
                    │   (Core)       │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
     ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
     │  SpellIndex │  │   Dummy     │  │   Table     │
     │             │  │   Caster    │  │             │
     └──────┬──────┘  └─────────────┘  └─────────────┘
            │
     ┌──────┼──────┐
     │            │
┌────▼────┐  ┌───▼──────┐
│Register  │  │TimerUtils│
│Player    │  │          │
│UnitEvent │  └──────────┘
└──────────┘
```

## Dependencias No Encontradas

Las siguientes dependencias se referencian en el código pero no están en el repositorio:
- `LoadoutOrbBalance`
- `LoadoutIntFullManaSwapNew`

## Carga de Librerías

Orden recomendado de carga:
1. Table
2. TimerUtils
3. RegisterPlayerUnitEvent
4. WorldBounds
5. SpellEffectEvent
6. SpellFinishEvent
7. IsUnitChanneling
8. DummyCaster
9. Missile
10. SpellIndex
11. Sistemas de aplicación
