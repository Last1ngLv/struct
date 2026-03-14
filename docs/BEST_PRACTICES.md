# BEST_PRACTICES.md - Mejores Prácticas

## Desarrollo de Spells

### Creación de Missile
```jass
// Correcto
local Missile missile = Missile.create(x, y, z, angle, distance, endZ)
set missile.speed = 500.
set missile.damage = 100.
set missile.source = GetTriggerUnit()
set missile.owner = GetTriggerPlayer()
call MiSpell.launch(missile)

// Incorrecto - omitir launch
local Missile missile = Missile.create(...)
// missile no se mueve
```

### Validación de Objetivos
```jass
// Correcto
private function FilterUnits takes unit target, player owner returns boolean
    return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
endfunction

// En callback
if FilterUnits(hit, missile.owner) then
    // aplicar efecto
endif
```

### Manejo de Datos
```jass
// Guardar SpellIndex en missile.data
set dex = SpellIndex.create()
set dex.source = source
set dex.target = target
set missile.data = dex

// Recuperar en callback
local SpellIndex dex = missile.data
```

### Reciclaje de Recursos
```jass
// En destroy
method destroy takes nothing returns nothing
    if fx != null then
        call DestroyEffect(fx)
        set fx = null
    endif
    if clock != null then
        call ReleaseTimer(clock)
        set clock = null
    endif
    set source = null
    set target = null
endmethod
```

## Configuración de Missiles

### Velocidad
```jass
// En小姐 creating
set missile.speed = 20. // por frame, NO por segundo
// 20 * 32 = 640 unidades/segundo (con TIMER_TIMEOUT = 1/32)
```

### Colisión
```jass
set missile.collision = 32. // radio de colisión
set missile.collisionZ = 50. // colisión en eje Z
```

### Modelos
```jass
set missile.model = "path/to/model.mdl"
set missile.scale = 1.0
```

## Errores Comunes

1. **Olvidar launch()** - Missile no se mueve
2. **No filtrar objetivos** - Daño a aliados
3. **Memory leaks** - No destruir recursos
4. **Velocidad incorrecta** - En小姐 vs por segundo
5. **Callbacks mal implementados** - No retornar boolean
