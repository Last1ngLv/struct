# Triggers System

## Sistema
El sistema de triggers de Warcraft III responde a eventos del juego:
- Player unit events (cast, death, selection)
- Unit events (enters region, dies)
- Timer events
- Custom events (SpellEffectEvent, SpellFinishEvent)

## Reglas Importantes

### Eventos de Spell
```
EVENT_PLAYER_UNIT_SPELL_CHANNEL     - Inicio de canalización
EVENT_PLAYER_UNIT_SPELL_CAST        - Spell iniciado
EVENT_PLAYER_UNIT_SPELL_EFFECT     - Efecto del spell (más común)
EVENT_PLAYER_UNIT_SPELL_FINISH      - Spell terminado
EVENT_PLAYER_UNIT_SPELL_ENDCAST    - Cast finalizado
```

### Registro de Eventos
```jass
call TriggerRegisterPlayerUnitEvent(trigger, player, event, filter)
call RegisterSpellEffectEvent(abilityId, function handler)
```

### Filter Functions
```jass
private function ConsiderUnitsFiltered takes nothing returns boolean
    return FilterUnits(GetFilterUnit(), tempOwner)
endfunction
```

## Ejemplos del Proyecto

### Registro con RegisterPlayerUnitEvent (IsUnitChanneling.j)
```jass
private static method onInit takes nothing returns nothing
   call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_CHANNEL, function thistype.onEvent)
   call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_ENDCAST, function thistype.onEvent)
endmethod
```

### Registro con RegisterSpellEffectEvent (Fireball.j)
```jass
private function Init takes nothing returns nothing
    call RegisterSpellEffectEvent(FIREBALL_ABILITY, function OnEffect)
endfunction
```

### Registro con RegisterSpellFinishEvent (SpellFinishEvent.j)
```jass
function RegisterSpellFinishEvent takes integer abil, code onFinish returns nothing
    static if LIBRARY_Table then
        if not S.tb.handle.has(abil) then
            set S.tb.trigger[abil] = CreateTrigger()
        endif
        call TriggerAddCondition(S.tb.trigger[abil], Filter(onFinish))
    else
        if not HaveSavedHandle(S.ht, 0, abil) then
            call SaveTriggerHandle(S.ht, 0, abil, CreateTrigger())
        endif
        call TriggerAddCondition(LoadTriggerHandle(S.ht, 0, abil), Filter(onFinish))
    endif
endfunction
```

### Evento por Jugador Específico (RegisterPlayerUnitEvent.j)
```jass
function RegisterPlayerUnitEventForPlayer takes playerunitevent p, code c, player pl returns nothing
    local integer i = 16 * GetHandleId(p) + GetPlayerId(pl)
    if t[i] == null then
        set t[i] = CreateTrigger()
        call TriggerRegisterPlayerUnitEvent(t[i], pl, p, null)
    endif
    call TriggerAddCondition(t[i], Filter(c))
endfunction
```

### Handler de Spell Effect (Loadout Control.j)
```jass
private function OnEffect takes nothing returns nothing
    local unit source = GetTriggerUnit()
    local integer level = GetUnitAbilityLevel(source, LOADOUT_CONTROL_SPELL)
    local real x = GetUnitX(source)
    local real y = GetUnitY(source)
    local real angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
    // ... lógica del spell
    set source = null
endfunction
```

## Errores Comunes

1. **No inicializar**: Olvidar llamar Init() en initializer
2. **Trigger leaks**: No destruir triggers creados
3. **Sleep en triggers**: `TriggerSleepAction` no funciona bien con eventos de jugador
4. **Filtrar wrong**: Filter que no retorna boolean
5. **Múltiples registros**: Registrar mismo evento múltiples veces

## Cómo Modificar Correctamente

1. **Crear nuevo spell**:
   - Definir constante de ability rawcode
   - Crear función handler
   - Registrar en Init con RegisterSpellEffectEvent

2. **Añadir nuevo evento**:
   - Usar RegisterPlayerUnitEvent para eventos globales
   - Usar RegisterPlayerUnitEventForPlayer para eventos por jugador
   - Implementar filter si es necesario

3. **Evitar leaks**:
   - No crear triggers en loops
   - Reutilizar triggers existentes
   - Usar sistemas como RegisterPlayerUnitEvent
