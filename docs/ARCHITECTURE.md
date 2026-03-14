# ARCHITECTURE.md - Arquitectura del Sistema

## Visión General
Sistema de proyectiles personalizables para Warcraft III basado en vJASS. Arquitectura modular con librería core y múltiples sistemas de soporte.

## Componentes Principales

### Capa Core
```
Missile.j (v2.5.1)
├── Sistema de proyectiles
├── Colisión (units, destructibles, items)
├── Reciclaje de dummies
└── Configuración global
```

### Capa de Datos
```
Table.j (v3.1.0.1)
├── Hashtable optimizado
├── Soporte para múltiples tipos
└── TableArray para arrays de tablas

TimerUtils.j (v2.0)
├── Reutilización de timers
├── Múltiples sabores (red/blue/orange)
└── Attach de datos a timers
```

### Capa de Spells
```
SpellIndex.j (v1.1)
├── Indexación global de spells
├── Tracking de fuente/objetivo
├── Timer por spell
└── Almacenamiento de damage/collision

RegisterPlayerUnitEvent.j (v5.1.0.1)
├── Registro de eventos por jugador
├── Optimización de triggers
└── Soporte para eventos específicos de jugador
```

### Capa de Aplicación
```
MyMissiles/
├── PlayerMissileLoadout - Configuración por jugador
├── Loadout Missile - Sistema base
├── Loadout Control - Spell tipo shotgun
├── Loadout Leap - Spell de salto
└── Damage Text Util - Utilidades de texto

MissileExamples/
├── Blademaster (Leap, Whirlwind)
├── BloodMage (Fireball, Ice Siege, etc.)
├── Mountain King (Fist of Thunder)
├── Necromancer (Bone Spirit, Reapers Scythe)
└── Rogue (Guided Arrow, Target Sling, etc.)
```

## Flujo de Datos
1. Spell se lanza → RegisterSpellEffectEvent detecta
2. Missile se crea → Configuración desde PlayerMissileLoadout
3. Missile se mueve → onUpdate callback (si existe)
4. Colisión ocurre → onCollide callback
5. Missile termina → onRemove/onFinish callback
6. Recycling → Dummy se reutiliza

## Dependencias
- Missile no requiere nada por defecto
- SpellIndex requiere: Table, Missile, TimerUtils, DummyCaster, WorldBounds, SpellEffectEvent, RegisterPlayerUnitEvent
- Loadout Control requiere: SpellIndex, Missile, PlayerMissileLoadout, IsUnitChanneling, DamageTextUtil, Table
