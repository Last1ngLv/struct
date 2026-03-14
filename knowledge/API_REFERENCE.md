# API_REFERENCE.md - Referencia de API

## Missile (libraries/Missile.j)

### Métodos Estáticos de Creación
```jass
static method create takes real x, real y, real z, real angleInRadians, real distanceToTravel, real endZ returns Missile
static method createEx takes unit missileDummy, real impactX, real impactY, real impactZ returns Missile
static method createXYZ takes real x, real y, real z, real impactX, real impactY, real impactZ returns Missile
```

### Métodos de Instancia
```jass
method destroy takes nothing returns nothing       // Destrucción diferida
method terminate takes nothing returns nothing    // Destrucción inmediata
```

### Propiedades
```jass
// Editables
missile.source         // Unidad que lanzó
missile.target         // Objetivo (homing)
missile.speed          // Velocidad
missile.acceleration   // Aceleración
missile.damage         // Daño
missile.turn           // Rate de giro
missile.data           // Entero personalizado
missile.collision      // Radio de colisión
missile.collisionZ    // Colisión Z

// Solo lectura
missile.dummy          // Unit dummy
missile.origin         // MissilePosition origen
missile.impact         // MissilePosition impacto
missile.x, .y, .z     // Posición actual
missile.angle          // Ángulo actual
missile.terrainZ      // Z del terreno

// Operadores
missile.model=         // Set modelo
missile.model          // Get modelo
missile.scale=         // Set escala
missile.scale          // Get escala
```

---

## SpellIndex (libraries/SpellIndex.j)

### Miembros
```jass
SpellIndex.source      // Unidad fuente
SpellIndex.target      // Unidad objetivo
SpellIndex.user        // Jugador
SpellIndex.fx          // Effect
SpellIndex.splat       // Ubersplat
SpellIndex.flash       // Lightning
SpellIndex.clock       // Timer
SpellIndex.damage      // Daño
SpellIndex.collision   // Colisión
SpellIndex.time        // Tiempo
SpellIndex.count       // Contador
SpellIndex.level       // Nivel
SpellIndex.phase       // Fase

// Grupo global
SpellIndex.GLOBAL_GROUP
```

### Métodos
```jass
static method create takes nothing returns SpellIndex
method destroy takes nothing returns nothing
```

---

## Table (libraries/Table.j)

### Table
```jass
static method create takes nothing returns Table
method destroy takes nothing returns nothing
method flush takes nothing returns nothing
method remove takes integer key returns nothing
method operator []= takes integer key, TYPE value returns nothing
method operator [] takes integer key returns TYPE
method has takes integer key returns boolean
```

### TableArray
```jass
static method operator [] takes integer array_size returns TableArray
method destroy takes nothing returns nothing
method flush takes nothing returns nothing
method operator size takes nothing returns integer
method operator [] takes integer key returns Table
```

---

## TimerUtils (libraries/TimerUtils.j)

```jass
function NewTimer takes nothing returns timer
function NewTimerEx takes integer data returns timer
function ReleaseTimer takes timer t returns nothing
function SetTimerData takes timer t, integer data returns nothing
function GetTimerData takes timer t returns integer
```

---

## DummyCaster (libraries/DummyCaster.j)

```jass
method cast takes player p, integer level, integer order, real x, real y returns boolean
method castTarget takes player p, integer level, integer order, widget t returns boolean
method castPoint takes player p, integer level, integer order, real x, real y returns boolean
```

---

## RegisterPlayerUnitEvent (libraries/RegisterPlayerUnitEvent.j)

```jass
function RegisterPlayerUnitEvent takes playerunitevent whichEvent, code whichFunction returns nothing
function RegisterPlayerUnitEventForPlayer takes playerunitevent whichEvent, code whichFunction, player whichPlayer returns nothing
function GetPlayerUnitEventTrigger takes playerunitevent whichEvent returns trigger
```

---

## SpellFinishEvent (libraries/SpellFinishEvent.j)

```jass
function RegisterSpellFinishEvent takes integer abil, code onFinish returns nothing
```

---

## IsUnitChanneling (libraries/IsUnitChanneling.j)

```jass
function IsUnitChanneling takes unit whichUnit returns boolean
```

---

## PlayerMissileLoadout (MyMissiles/Loadout Missile.j)

### Setters
```jass
function SetPlayerMissileLoadout(...)
function SetPlayerMissileAbilityChoice(player p, integer abilityRawcode)
function SetPlayerMissileSpeedBonus(player p, real speedBonus)
function SetPlayerMissileDamageValue(player p, real damageValue)
function SetPlayerMissileInstanceCount(player p, integer instanceCount)
function AddPlayerMissileInstanceCount(player p, integer delta)
function SetPlayerMissileModelPath(player p, string modelPath)
function SetPlayerMissileOverlayModelPath(player p, string modelPath)
```

### Getters
```jass
function GetPlayerMissileAbilityChoice(player p) -> integer
function GetPlayerMissileSpeedBonus(player p) -> real
function GetPlayerMissileDamageValue(player p) -> real
function GetPlayerMissileInstanceCount(player p) -> integer
function GetPlayerMissileModelPath(player p) -> string
function GetPlayerMissileOverlayModelPath(player p) -> string
```
