# Gameplay Systems

## Sistema
Este proyecto contiene sistemas de gameplay enfocados en:
- Sistema de proyectiles (Missile)
- Sistema de spells con tracking (SpellIndex)
- Sistema de loadout por jugador
- Efectos visuales y de daño

## Reglas Importantes

### Sistema Missile
- Crear con `Missile.create()` o `Missile.createXYZ()`
- Configurar propiedades: speed, damage, collision, model
- Asignar source y owner
- Llamar `launch()` para iniciar
- Callbacks: onRemove, onCollide, onFinish, onUpdate

### Sistema SpellIndex
- Crear instancia con `SpellIndex.create()`
- Asignar miembros: source, target, damage, clock, etc.
- Destruir en cleanup con `destroy()`
- Auto-limpia handles en destroy()

### Sistema de Loadout
- Tabla por jugador con clave de slot
- Configuración: ability, speed, damage, model, instances

## Ejemplos del Proyecto

### Spell Básico con Missile (Fireball.j)
```jass
private function OnEffect takes nothing returns nothing
    local unit source = GetTriggerUnit()
    local integer level = GetUnitAbilityLevel(source, FIREBALL_ABILITY)
    local real x = GetUnitX(source)
    local real y = GetUnitY(source)
    local real angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
    
    local Missile missile = Missile.create(x, y, FIREBALL_FLY_HEIGHT, angle, GetFlyDistance(level), FIREBALL_FLY_HEIGHT)
    call CustomizeMissile(missile, level)
    set missile.source = source
    set missile.owner = GetTriggerPlayer()
    set missile.data = level
    call Fireball.launch(missile)
    
    set source = null
endfunction

private struct Fireball extends array
    private static method onRemove takes Missile missile returns boolean
        local unit u
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, GetExplosionRadius(missile.data), null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, missile.owner) then
                call UnitDamageTarget(missile.source, u, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            endif
        endloop
        call DestroyEffect(AddSpecialEffectTarget(ON_EXPLODE_FX, missile.dummy, "origin"))
        return true
    endmethod
    implement MissileStruct
endstruct
```

### Spell Complejo con Tracking (Guided Arrow.j)
```jass
private struct GuidedArrow extends array
    private static method onRemove takes Missile missile returns boolean
        call SpellIndex(missile.data).destroy()
        return true
    endmethod
    
    private static method onFinish takes Missile missile returns boolean
        local SpellIndex dex = missile.data
        return (dex.phase == 0) or (GetUnitTypeId(dex.target) == 0)
    endmethod
    
    private static method onCollide takes Missile missile, unit hit returns boolean
        local SpellIndex dex = missile.data
        if (hit == missile.target) then
            call missile.enableHitAfter(hit, ALLOW_HIT_AFTER)
            call UnitDamageTarget(missile.source, hit, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            set missile.target = null
            set missile.turn = 0
            set dex.count = dex.count - 1
        endif
        return (dex.count < 0)
    endmethod
    
    implement MissileStruct
endstruct
```

### Sistema de Loadout (Loadout Missile.j)
```jass
function SetPlayerMissileLoadout takes player p, integer abilityRawcode, real speedBonus, real damageValue, integer instanceCount, string missileModelPath, string overlayModelPath returns nothing
    local integer slot = SlotOfPlayer(p)
    if instanceCount < 1 then
        set instanceCount = 1
    endif
    set chosenAbility[slot] = abilityRawcode
    set chosenSpeedBonus[slot] = speedBonus
    set chosenDamage[slot] = damageValue
    set chosenInstances[slot] = instanceCount
    set chosenModelPath[slot] = missileModelPath
    set chosenOverlayPath[slot] = overlayModelPath
endfunction

function GetPlayerMissileAbilityChoice takes player p returns integer
    return chosenAbility[SlotOfPlayer(p)]
endfunction
```

### Spell con Daño en Área (Loadout Control.j)
```jass
private function DamageArea takes unit source, player owner, real x, real y, real radius, real amount returns nothing
    local unit u
    if amount <= 0. or GetUnitTypeId(source) == 0 then
        return
    endif
    call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, radius, null)
    loop
        set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
        exitwhen u == null
        call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
        if FilterUnits(u, owner) then
            call UnitDamageTarget(source, u, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        endif
    endloop
    set u = null
endfunction
```

### Efecto de Texto de Daño (Damage Text Util.j)
```jass
function ShowCustomLoadoutText takes unit target, string msg, integer r, integer g, integer b returns nothing
    local texttag t
    if target == null then
        return
    endif
    set t = CreateTextTag()
    call SetTextTagText(t, msg, 0.020)
    call SetTextTagPosUnit(t, target, 90.)
    call SetTextTagColor(t, r, g, b, 255)
    call SetTextTagVelocity(t, 0.0, 0.035)
    call SetTextTagLifespan(t, 1.00)
    call SetTextTagFadepoint(t, 0.50)
    call SetTextTagPermanent(t, false)
    set t = null
endfunction
```

## Errores Comunes

1. **Olvidar launch()**: Missile creado pero no se mueve
2. **No filtrar objetivos**: Daño a aliados o estructuras
3. **Memory leaks**: No destruir SpellIndex en onRemove
4. **Velocidad incorrecta**: Valores en小姐 vs por segundo
5. **Colisión muy pequeña**: Missile no colisiona

## Cómo Modificar Correctamente

1. **Crear spell simple**:
   - Definir constantes de configuración
   - Crear FilterUnits
   - Implementar struct con MissileStruct
   - Implementar callbacks necesarios
   - Registrar en Init

2. **Crear spell complejo**:
   - Usar SpellIndex para tracking
   - Implementar múltiples fases
   - Manejar casos edge (target muere, etc.)

3. **Sistema de loadout**:
   - Añadir constantes DEFAULT_
   - Añadir arrays de configuración
   - Implementar SlotOfPlayer
   - Crear setters y getters
