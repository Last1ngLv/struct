library LoadoutIntFullManaSwapNew initializer Init requires Table, SpellIndex, TimerUtils, SpellFinishEvent, PlayerMissileLoadout
//*******************************************************************************
// Guarda inteligencia y mana actual, sube INT a 500 y mana a full.
// Al disparar un orb: restaura INT y mana original y nivel de habilidad temporal (CD_LEVEL)
// Al finalizar cooldown: solo restaura nivel original de habilidad
// Compatible con Warcraft III 1.27
//*******************************************************************************

globals
    private constant integer CD_LEVEL = 5
    private constant integer MAX_TRIGGER_LEVEL = 4
    private constant real COOLDOWN_MIN = 0.50

    private constant integer ABILITY_RAY    = 'AM05'
    private constant integer ABILITY_FIRE   = 'AM04'
    private constant integer ABILITY_POISON = 'AM02'
    private constant integer ABILITY_WIND   = 'AM06'
    private constant integer ABILITY_DARK   = 'AM03'
    private constant integer ABILITY_BLOOD  = 'AM01'

    private constant real ABILITY_CD_LEVEL1 = 1.00
    private constant real ABILITY_CD_STEP   = -0.20

    private Table byUnit
    private integer array trackedAbility
    private integer array savedLevel
    private integer array savedInt
    private real array savedMana
endglobals

// Calcula cooldown según nivel
private function CooldownFromLevel takes integer level returns real
    local real t
    if level < 1 then
        set level = 1
    endif
    set t = ABILITY_CD_LEVEL1 + ABILITY_CD_STEP * (level - 1)
    if t < COOLDOWN_MIN then
        set t = COOLDOWN_MIN
    endif
    return t
endfunction

// Solo restaura nivel de habilidad al terminar cooldown
private function OnCooldownFinish takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local SpellIndex dex = GetTimerData(t)
    local unit u = dex.source

    if dex.clock == t then
        set dex.clock = null
    endif

    call ReleaseTimer(t)

    if GetUnitTypeId(u) != 0 then
        if GetUnitAbilityLevel(u, trackedAbility[dex]) <= 0 then
            call UnitAddAbility(u, trackedAbility[dex])
        endif
        call SetUnitAbilityLevel(u, trackedAbility[dex], GetPlayerOrbLevel(GetOwningPlayer(dex.source)))
    endif

    call byUnit.remove(GetHandleId(u))
    set trackedAbility[dex] = 0
    set savedLevel[dex] = 0
    set savedInt[dex] = 0
    set savedMana[dex] = 0.
    call dex.destroy()
endfunction

// Al disparar un orb: aplica restauración de INT y mana, y nivel temporal
private function OnOrbEvent takes integer orbAbility returns nothing
    local unit u = GetTriggerUnit()
    local integer hid = GetHandleId(u)
    local SpellIndex dex
    local integer level

    if not byUnit.has(hid) then
        set u = null
        return
    endif

    set dex = byUnit[hid]

    if trackedAbility[dex] != orbAbility then
        set u = null
        return
    endif

    // Restaurar INT y mana original
    call SetHeroInt(u, savedInt[dex], true)
    call SetUnitState(u, UNIT_STATE_MANA, savedMana[dex])

    // Guardar nivel actual y aplicar nivel temporal
    set level = GetUnitAbilityLevel(u, orbAbility)
    if level < 1 then
        set level = savedLevel[dex]
    endif
    if level < 1 then
        set level = 1
    endif
    set savedLevel[dex] = level

    call SetUnitAbilityLevel(u, orbAbility, CD_LEVEL)
    
    // Timer para restaurar nivel original
    if dex.clock != null then
        call ReleaseTimer(dex.clock)
    endif
    set dex.clock = NewTimerEx(dex)
    call SetTimerDebugTag(dex.clock, TIMER_DEBUG_TAG_OTHER)
    call TimerStart(dex.clock, CooldownFromLevel(savedLevel[dex]), false, function OnCooldownFinish)
    
    

    set u = null
endfunction

// Handlers para cada orbe
private function FunctionEventRay takes nothing returns nothing
    call OnOrbEvent(ABILITY_RAY)
endfunction

private function FunctionEventFire takes nothing returns nothing
    call OnOrbEvent(ABILITY_FIRE)
endfunction

private function FunctionEventPoison takes nothing returns nothing
    call OnOrbEvent(ABILITY_POISON)
endfunction

private function FunctionEventWind takes nothing returns nothing
    call OnOrbEvent(ABILITY_WIND)
endfunction

private function FunctionEventDark takes nothing returns nothing
    call OnOrbEvent(ABILITY_DARK)
endfunction

private function FunctionEventBlood takes nothing returns nothing
    call OnOrbEvent(ABILITY_BLOOD)
endfunction

// Inicializa tracking y aplica INT 500 + mana full
private function BeginGive takes unit u, integer orbAbility returns nothing
    local integer hid
    local integer level
    local SpellIndex dex

    if u == null or GetUnitTypeId(u) == 0 then
        return
    endif

    set level = GetPlayerOrbLevel(GetOwningPlayer(u))
    if level < 1 or level > MAX_TRIGGER_LEVEL then
        return
    endif

    set hid = GetHandleId(u)
    if byUnit.has(hid) then
        return
    endif

    set dex = SpellIndex.create()
    set dex.source = u
    set dex.clock = null
    set trackedAbility[dex] = orbAbility
    set savedLevel[dex] = level
    set savedInt[dex] = GetHeroInt(u, true)
    set savedMana[dex] = GetUnitState(u, UNIT_STATE_MANA)
    
    // Subir INT temporal
    call SetHeroInt(u, 500, true)
    // Mana al máximo compatible con 1.27
    call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MAX_MANA))

    set byUnit[hid] = dex
endfunction

function TriggerLoadoutIntFullManaSwapForAbility takes unit u, integer abilityRaw returns nothing
    if abilityRaw == ABILITY_RAY then
        call BeginGive(u, ABILITY_RAY)
    elseif abilityRaw == ABILITY_FIRE then
        call BeginGive(u, ABILITY_FIRE)
    elseif abilityRaw == ABILITY_POISON then
        call BeginGive(u, ABILITY_POISON)
    elseif abilityRaw == ABILITY_WIND then
        call BeginGive(u, ABILITY_WIND)
    elseif abilityRaw == ABILITY_DARK then
        call BeginGive(u, ABILITY_DARK)
    elseif abilityRaw == ABILITY_BLOOD then
        call BeginGive(u, ABILITY_BLOOD)
    endif
endfunction

function LoadoutIntFullMana takes unit u, integer abilityRaw returns nothing
    call TriggerLoadoutIntFullManaSwapForAbility(u, abilityRaw)
endfunction

private function Init takes nothing returns nothing
    set byUnit = Table.create()
    call RegisterSpellFinishEvent(ABILITY_RAY, function FunctionEventRay)
    call RegisterSpellFinishEvent(ABILITY_FIRE, function FunctionEventFire)
    call RegisterSpellFinishEvent(ABILITY_POISON, function FunctionEventPoison)
    call RegisterSpellFinishEvent(ABILITY_WIND, function FunctionEventWind)
    call RegisterSpellFinishEvent(ABILITY_DARK, function FunctionEventDark)
    call RegisterSpellFinishEvent(ABILITY_BLOOD, function FunctionEventBlood)
endfunction
endlibrary
