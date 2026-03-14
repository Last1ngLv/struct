# Data Structures

## Sistema
El proyecto usa varias estructuras de datos:
- Arrays nativos de JASS
- Table (hashtable optimizado)
- TimerUtils (timer recycling)
- Structs como índices de arrays

## Reglas Importantes

### Arrays Nativos
- Tamaño máximo: 8190
- Índices negativos no soportados
- Acceso directo sin inicialización

### Table
- Crear con `Table.create()`
- Destroy con `.destroy()`
- Operador `[]` para acceso
- Soporta todos los tipos

### TimerUtils
- NewTimer() para obtener timer
- ReleaseTimer() para devolver al pool
- SetTimerData()/GetTimerData() para attach

## Ejemplos del Proyecto

### Table Simple (PlayerMissileLoadout.j)
```jass
globals
    private Table byHandle
    private integer array chosenAbility
    private real array chosenSpeedBonus
    private real array chosenDamage
    private integer array chosenInstances
    private string array chosenModelPath
    private string array chosenOverlayPath
endglobals

private function SlotOfPlayer takes player p returns integer
    local integer hid
    local integer slot
    if p == null then
        return 1
    endif
    set hid = GetHandleId(p)
    if byHandle.has(hid) then
        return byHandle[hid]
    endif
    set slot = GetPlayerId(p) + 1
    if slot < 1 then
        set slot = 1
    elseif slot > MAX_PLAYER_SLOTS then
        set slot = MAX_PLAYER_SLOTS
    endif
    set byHandle[hid] = slot
    return slot
endfunction
```

### SpellIndex con Múltiples Tipos (SpellIndex.j)
```jass
struct SpellIndex
    unit      source
    unit      target
    player    user
    effect    fx
    ubersplat splat
    lightning flash
    timer     clock
    real      damage
    real      collision
    real      time
    integer   count
    integer   level
    integer   phase
    
    method destroy takes nothing returns nothing
        if fx != null then
            call DestroyEffect(fx)
            set fx = null
        endif
        if splat != null then
            call DestroyUbersplat(splat)
            set splat = null
        endif
        if flash != null then
            call DestroyLightning(flash)
            set flash = null
        endif
        set target    = null
        set clock     = null
        set source    = null
        call deallocate()
    endmethod
endstruct
```

### TimerUtils con Datos (Loadout Control.j)
```jass
private function OnPoisonTick takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local SpellIndex dex = GetTimerData(t)
    if (dex.count <= 0) or (GetUnitTypeId(dex.target) == 0) or (not UnitAlive(dex.target)) or (GetUnitTypeId(dex.source) == 0) then
        if poisonFx[dex] != null then
            call DestroyEffect(poisonFx[dex])
            set poisonFx[dex] = null
        endif
        call ReleaseTimer(t)
        call dex.destroy()
        set t = null
        return
    endif
    call UnitDamageTarget(dex.source, dex.target, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
    set dex.count = dex.count - 1
    if dex.count <= 0 then
        if poisonFx[dex] != null then
            call DestroyEffect(poisonFx[dex])
            set poisonFx[dex] = null
        endif
        call ReleaseTimer(t)
        call dex.destroy()
    endif
    set t = null
endfunction
```

### TableArray (Table.j)
```jass
// Crear array de tablas
static method operator [] takes integer array_size returns TableArray
// Acceso
method operator [] takes integer key returns Table
```

### Tabla con Boolean (IsUnitChanneling.j)
```jass
static if LIBRARY_Table then
    static key k
    static Table channeling = k
    //...
    set channeling.boolean[id] = not channeling.boolean[id]
else
    // fallback con hashtable nativa
endif
```

## Errores Comunes

1. **Array index out of bounds**: Índice > 8190
2. **Table sin destroy**: Memory leak
3. **Timer sin ReleaseTimer**: Timer leak
4. **Índice negativo**: Arrays JASS no soportan negativos
5. **Confundir handle id con user data**: Son diferentes

## Cómo Modificar Correctamente

1. **Usar Table**:
   - Crear con `Table.create()` en init
   - Siempre hacer `.destroy()` cuando ya no necesario
   - Usar `.has(key)` para verificar existencia
   - Usar `.remove(key)` para borrar entrada específica

2. **Usar TimerUtils**:
   - Obtener con `NewTimer()` o `NewTimerEx(data)`
   - Siempre devolver con `ReleaseTimer()`
   - Attach datos con `SetTimerData()`
   - Leer con `GetTimerData()`

3. **Arrays por Jugador**:
   - Calcular slot: `GetPlayerId(p) + 1`
   - Validar rango: 1 a MAX_PLAYER_SLOTS
   - Usar Table si necesita mapeo handle→slot
