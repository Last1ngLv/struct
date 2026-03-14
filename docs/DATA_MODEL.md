# DATA_MODEL.md - Modelo de Datos

## Structs Principales

### Missile (libraries/Missile.j)
```jass
struct Missile extends array
    // Fields editables
    unit       source          // Unidad que lanzó el missile
    unit       target          // Objetivo (para homing)
    real       distance        // Distancia viajada
    player     owner           // Propietario pseudo
    real       speed           // Velocidad del missile
    real       acceleration    // Aceleración
    real       damage          // Daño almacenado
    real       turn            // Rate de giro
    integer    data            // Datos personalizados
    boolean    recycle        // Flag de reciclaje
    boolean    wantDestroy    // Flag de destrucción
    real       collision       // Radio de colisión
    real       collisionZ      // Colisión en eje Z
    
    // Fields de solo lectura
    readonly unit         dummy        // Dummy unit
    readonly MissilePosition origin    // Posición origen
    readonly MissilePosition impact    // Posición impacto
    readonly real         terrainZ     // Z del terreno
    readonly real         x, y, z      // Posición actual
    readonly real         angle        // Ángulo actual
    
    // Métodos
    static method create(...)
    static method createEx(...)
    static method createXYZ(...)
    method destroy()
    method terminate()
endstruct
```

### SpellIndex (libraries/SpellIndex.j)
```jass
struct SpellIndex
    // Miembros
    unit      source    // Unidad fuente
    unit      target    // Unidad objetivo
    player    user      // Jugador
    effect    fx        // Efecto
    ubersplat splat     // Ubersplat
    lightning flash     // Lightning
    timer     clock     // Timer
    real      damage    // Daño
    real      collision // Colisión
    real      time      // Tiempo
    integer   count     // Contador
    integer   level    // Nivel del spell
    integer   phase     // Fase
    
    // Métodos
    static method create() -> SpellIndex
    method destroy()
endstruct
```

### PlayerMissileLoadout (MyMissiles/Loadout Missile.j)
```jass
// Datos por jugador
chosenAbility[]        // Habilidad seleccionada
chosenSpeedBonus[]    // Bonus de velocidad
chosenDamage[]        // Daño
chosenInstances[]     // Conteo de instancias
chosenModelPath[]     // Modelo del missile
chosenOverlayPath[]   // Modelo overlay
// Configuración de Leap
chosenLeapCasterFx1/2[]
chosenLeapDummyFx1/2[]
chosenLeapDummyScale[]
chosenLeapCompanionUnitId[]
chosenLeapImpactFx[]
```

## Globals Tables
```jass
// Table global (libraries/Table.j)
private hashtable ht = InitHashtable()
private key sizeK
private key listK
```

## Arrays de Estado
```jass
// Loadout Control.j
storedDamage[]        // Daño almacenado
effectInstances[]     // Instancias de efecto
rayHitsLeft[]         // Hits restantes (rayo)
bonusActive[]         // Bonus activo
overlayFx[]           // FX overlay
poisonFx[]            // FX de veneno
aim[]                 // Ángulo de aim
```
