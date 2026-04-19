//===========================================================================
//
//  MovementSystem v0 - SIMPLE FOLLOW
//  Fase mínima: guarda el último punto de smart/move y, al castear una habilidad
//  registrada, hace follow al dummy hacia ese punto usando SetUnitX/SetUnitY.
//
//  Reglas actuales:
//  - smart/move durante follow actualiza el punto de movimiento del dummy
//  - no hay corrección manual de facing: la orden nativa se encarga
//
//===========================================================================
library MovementSystem initializer Init requires TimerUtils, Table, RegisterPlayerUnitEvent

globals
    private constant real INTERVAL = 0.03125
    private constant real ARRIVAL_THRESHOLD = 50.0
    private constant real ARRIVAL_THRESHOLD_SQ = ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD
    private constant integer DUMMY_UNIT_ID = 'h003'
    private constant integer DUMMY_FOLLOW_ABILITY_ID = 'ADD0'
    private constant boolean DEBUG_MODE = false

    private Table registeredOrderSpells
    private Table registeredAbilities
    private Table castSessionDurationByAbility

    private integer ORDER_ID_MOVE
    private integer ORDER_ID_SMART
    private integer ORDER_ID_STOP
    private integer ORDER_ID_FLARE
endglobals

struct MovementData
    unit source
    unit dummy
    timer tim
    timer pulseTim
    real lastSmartX
    real lastSmartY
    boolean hasLastSmart
    real moveX
    real moveY
    real aimX
    real aimY
    boolean hasMovePoint
    boolean hasAimPoint
    boolean isFollowing

    private static Table table

    static method create takes unit u returns thistype
        local thistype this = thistype.allocate()

        set .source = u
        set .dummy = null
        set .tim = null
        set .pulseTim = null
        set .lastSmartX = 0.
        set .lastSmartY = 0.
        set .hasLastSmart = false
        set .moveX = 0.
        set .moveY = 0.
        set .aimX = 0.
        set .aimY = 0.
        set .hasMovePoint = false
        set .hasAimPoint = false
        set .isFollowing = false

        set table[GetHandleId(u)] = this
        return this
    endmethod

    static method has takes unit u returns boolean
        return table.has(GetHandleId(u))
    endmethod

    static method get takes unit u returns thistype
        return table[GetHandleId(u)]
    endmethod

    private static method onPeriodic takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        local real dx
        local real dy
        local real distSq

        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if .tim != t then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            call .destroy()
            set t = null
            return
        endif

        if (.dummy == null) or (GetUnitTypeId(.dummy) == 0) then
            call .destroy()
            set t = null
            return
        endif

        set dx = GetUnitX(.dummy)
        set dy = GetUnitY(.dummy)
        set distSq = (.moveX - dx) * (.moveX - dx) + (.moveY - dy) * (.moveY - dy)

        call SetUnitX(.source, dx)
        call SetUnitY(.source, dy)

        if distSq <= ARRIVAL_THRESHOLD_SQ then
            call .stopFollow()
        endif

        set t = null
    endmethod

    private static method onPulse takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)

        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if .pulseTim != t then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        set .pulseTim = null

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            set t = null
            return
        endif

        if (.dummy == null) or (GetUnitTypeId(.dummy) == 0) then
            set t = null
            return
        endif

        if .isFollowing and .hasAimPoint then
            call IssuePointOrderById(.source, ORDER_ID_FLARE, .aimX, .aimY)
        endif

        set t = null
    endmethod

    method rememberPoint takes real x, real y returns nothing
        set .lastSmartX = x
        set .lastSmartY = y
        set .hasLastSmart = true
    endmethod

    method setAimPoint takes real x, real y returns nothing
        set .aimX = x
        set .aimY = y
        set .hasAimPoint = true
    endmethod

    private method ensureDummy takes nothing returns boolean
        local real sx
        local real sy

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            return false
        endif

        if (.dummy != null) and (GetUnitTypeId(.dummy) != 0) then
            return true
        endif

        set sx = GetUnitX(.source)
        set sy = GetUnitY(.source)
        set .dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_UNIT_ID, sx, sy, 0)
        call SetUnitInvulnerable(.dummy, true)
        call SetUnitPathing(.dummy, false)
        call ShowUnit(.dummy, true)
        return (.dummy != null) and (GetUnitTypeId(.dummy) != 0)
    endmethod

    method setMovePoint takes real x, real y, boolean queuePulse returns nothing
        set .moveX = x
        set .moveY = y
        set .hasMovePoint = true
        set .isFollowing = true

        if not .ensureDummy() then
            return
        endif

        call IssueImmediateOrderById(.source, ORDER_ID_STOP)
        call IssuePointOrder(.dummy, "move", .moveX, .moveY)

        if .pulseTim != null then
            call ReleaseTimer(.pulseTim)
            set .pulseTim = null
        endif

        if queuePulse then
            set .pulseTim = NewTimerEx(this)
            call TimerStart(.pulseTim, 0.03, false, function thistype.onPulse)
        endif
    endmethod

    method startFollowToStoredPoint takes nothing returns nothing
        if .isFollowing then
            return
        endif

        if not .hasLastSmart then
            return
        endif

        if not .ensureDummy() then
            return
        endif

        call .setMovePoint(.lastSmartX, .lastSmartY, false)

        if .tim == null then
            set .tim = NewTimerEx(this)
            call TimerStart(.tim, INTERVAL, true, function thistype.onPeriodic)
        endif

        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Follow started")
        endif
    endmethod

    method stopFollow takes nothing returns nothing
        if .tim != null then
            call ReleaseTimer(.tim)
            set .tim = null
        endif

        if .pulseTim != null then
            call ReleaseTimer(.pulseTim)
            set .pulseTim = null
        endif

        if (.dummy != null) and (GetUnitTypeId(.dummy) != 0) then
            call RemoveUnit(.dummy)
        endif

        set .dummy = null
        set .isFollowing = false
        set .hasMovePoint = false
        set .hasAimPoint = false
    endmethod

    method destroy takes nothing returns nothing
        if .tim != null then
            call ReleaseTimer(.tim)
            set .tim = null
        endif

        if .pulseTim != null then
            call ReleaseTimer(.pulseTim)
            set .pulseTim = null
        endif

        if (.dummy != null) and (GetUnitTypeId(.dummy) != 0) then
            call RemoveUnit(.dummy)
        endif

        set .dummy = null

        if .source != null then
            call table.remove(GetHandleId(.source))
        endif

        set .source = null
        set .isFollowing = false
        set .hasLastSmart = false
        set .hasMovePoint = false
        set .hasAimPoint = false
        call .deallocate()
    endmethod

    private static method onInit takes nothing returns nothing
        set table = Table.create()
    endmethod
endstruct

//===========================================================================
function RegisterMovementSpell takes integer abilityId, string orderId returns nothing
    local integer oid = OrderId(orderId)
    set registeredOrderSpells[oid] = abilityId
    set registeredAbilities[abilityId] = oid
endfunction

//===========================================================================
function RegisterMovementSpellTarget takes integer abilityId, string orderId returns nothing
    call RegisterMovementSpell(abilityId, orderId)
endfunction

//===========================================================================
function ConfigureMovementSpellCastSession takes integer abilityId, real castDuration, boolean allowSmartRecast, integer maxSmartRecasts returns nothing
    set castSessionDurationByAbility.real[abilityId] = castDuration
    set allowSmartRecast = allowSmartRecast
    set maxSmartRecasts = maxSmartRecasts
endfunction

//===========================================================================
function RegisterMovementSpellRecast takes integer abilityId, string orderId returns nothing
    call RegisterMovementSpell(abilityId, orderId)
endfunction

//===========================================================================
function RegisterMovementSpellTargetRecast takes integer abilityId, string orderId returns nothing
    call RegisterMovementSpellTarget(abilityId, orderId)
endfunction

//===========================================================================
private function OnPointOrder takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data

    if orderId == ORDER_ID_MOVE or orderId == ORDER_ID_SMART then
        if MovementData.has(u) then
            set data = MovementData.get(u)
        else
            set data = MovementData.create(u)
        endif
        if not data.isFollowing then
            call data.rememberPoint(GetOrderPointX(), GetOrderPointY())
        else
            call data.setMovePoint(GetOrderPointX(), GetOrderPointY(), true)
        endif
    endif

    set u = null
    return false
endfunction

//===========================================================================
private function OnTargetOrder takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local unit targetU = GetOrderTargetUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data

    if (orderId == ORDER_ID_SMART) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
        else
            set data = MovementData.create(u)
        endif
        if not data.isFollowing then
            call data.rememberPoint(GetUnitX(targetU), GetUnitY(targetU))
        else
            call data.setMovePoint(GetUnitX(targetU), GetUnitY(targetU), true)
        endif
    endif

    set targetU = null
    set u = null
    return false
endfunction

//===========================================================================
private function OnSpellEffect takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local unit targetU = GetSpellTargetUnit()
    local integer abilityId = GetSpellAbilityId()
    local real tx = GetSpellTargetX()
    local real ty = GetSpellTargetY()
    local MovementData data

    if abilityId == DUMMY_FOLLOW_ABILITY_ID then
        set targetU = null
        set u = null
        return false
    endif

    if registeredAbilities.has(abilityId) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
        else
            set data = MovementData.create(u)
        endif
        if (targetU != null) and (GetUnitTypeId(targetU) != 0) then
            set tx = GetUnitX(targetU)
            set ty = GetUnitY(targetU)
        endif
        call data.setAimPoint(tx, ty)
        if not data.isFollowing then
            call data.startFollowToStoredPoint()
        endif
    endif

    set targetU = null
    set u = null
    return false
endfunction

//===========================================================================
private function OnUnitDeath takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local MovementData data

    if MovementData.has(u) then
        set data = MovementData.get(u)
        call data.destroy()
    endif

    set u = null
    return false
endfunction

//===========================================================================
private function Init takes nothing returns nothing
    set registeredOrderSpells = Table.create()
    set registeredAbilities = Table.create()
    set castSessionDurationByAbility = Table.create()

    set ORDER_ID_MOVE = OrderId("move")
    set ORDER_ID_SMART = OrderId("smart")
    set ORDER_ID_STOP = OrderId("stop")
    set ORDER_ID_FLARE = OrderId("flare")

    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function OnSpellEffect)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnUnitDeath)

    static if DEBUG_MODE then
        call BJDebugMsg("[MovementSystem] Simple follow initialized")
    endif
endfunction

endlibrary
