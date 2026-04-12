//===========================================================================
//
//  MovementSystem v1 - SIMPLE FOLLOW WITH CAST SESSION
//  - smart/move stores or retargets the dummy path
//  - registered spell casts refresh aim and session duration
//  - smart during follow consumes recast charges
//  - no manual facing; the native dummy order keeps orientation behavior
//
//===========================================================================
library MovementSystem initializer Init requires TimerUtils, Table, RegisterPlayerUnitEvent

globals
    private constant real INTERVAL = 0.03125
    private constant real ARRIVAL_THRESHOLD = 50.0
    private constant real ARRIVAL_THRESHOLD_SQ = ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD
    private constant integer DUMMY_UNIT_ID = 'h003'
    private constant integer LOADOUT_LEAP_SPELL_ID = 'U0A2'
    private constant integer LEAP_BUFF_ID = 'BB01'
    private constant real PULSE_DELAY = 0.03
    private constant boolean DEBUG_MODE = false

    private constant real CAST_TEXT_SIZE = 0.020
    private constant integer CAST_TEXT_R = 0
    private constant integer CAST_TEXT_G = 255
    private constant integer CAST_TEXT_B = 0
    private constant real CAST_TEXT_LIFESPAN = 1.00
    private constant real CAST_TEXT_FADEPOINT = 0.80
    private constant real CAST_TEXT_RISE_SPEED = 0.035

    private Table registeredAbilityFlags
    private Table registeredOrderFlags
    private Table registeredOrderByAbility
    private Table castDurationByAbility
    private Table smartRecastEnabledByAbility
    private Table smartRecastCountByAbility
    private integer ORDER_ID_MOVE
    private integer ORDER_ID_SMART
    private integer ORDER_ID_STOP
endglobals

private function IsLeapBuffActive takes unit u returns boolean
    if (u == null) or (GetUnitTypeId(u) == 0) then
        return false
    endif
    return GetUnitAbilityLevel(u, LEAP_BUFF_ID) > 0
endfunction

struct MovementData
    unit source
    unit dummy
    timer followTim
    timer sessionTim
    timer pulseTim
    texttag castText
    real lastSmartX
    real lastSmartY
    boolean hasLastSmart
    real moveX
    real moveY
    real aimX
    real aimY
    boolean hasMovePoint
    boolean hasAimPoint
    integer lastCastAbilityId
    integer lastCastOrderId
    unit lastCastTargetUnit
    boolean isFollowing
    boolean sessionActive
    real sessionDuration
    real sessionRemaining
    integer recastsLeft

    private static Table table

    static method create takes unit u returns thistype
        local thistype this = thistype.allocate()

        set .source = u
        set .dummy = null
        set .followTim = null
        set .sessionTim = null
        set .pulseTim = null
        set .castText = null
        set .lastSmartX = 0.
        set .lastSmartY = 0.
        set .hasLastSmart = false
        set .moveX = 0.
        set .moveY = 0.
        set .aimX = 0.
        set .aimY = 0.
        set .hasMovePoint = false
        set .hasAimPoint = false
        set .lastCastAbilityId = 0
        set .lastCastOrderId = 0
        set .lastCastTargetUnit = null
        set .isFollowing = false
        set .sessionActive = false
        set .sessionDuration = 0.
        set .sessionRemaining = 0.
        set .recastsLeft = 0

        set table[GetHandleId(u)] = this
        return this
    endmethod

    static method has takes unit u returns boolean
        return table.has(GetHandleId(u))
    endmethod

    static method get takes unit u returns thistype
        return table[GetHandleId(u)]
    endmethod

    private method syncCastTextTagPosition takes nothing returns nothing
        if (.castText != null) and (.source != null) and (GetUnitTypeId(.source) != 0) then
            call SetTextTagPosUnit(.castText, .source, 90.)
        endif
    endmethod

    private method refreshCastTextTag takes nothing returns nothing
        local string msg

        if not .sessionActive then
            call .releaseCastTextTag()
            return
        endif

        if .castText == null then
            set .castText = CreateTextTag()
            call SetTextTagPermanent(.castText, true)
            call SetTextTagVisibility(.castText, true)
        endif

        set msg = "MoveCast: " + I2S(.recastsLeft)
        call SetTextTagText(.castText, msg, CAST_TEXT_SIZE)
        call SetTextTagColor(.castText, CAST_TEXT_R, CAST_TEXT_G, CAST_TEXT_B, 255)
        call SetTextTagVelocity(.castText, 0.0, 0.0)
        call SetTextTagPermanent(.castText, true)
        call SetTextTagLifespan(.castText, 60.0)
        call SetTextTagFadepoint(.castText, 60.0)
        call .syncCastTextTagPosition()
    endmethod

    private method releaseCastTextTag takes nothing returns nothing
        if .castText != null then
            call SetTextTagPermanent(.castText, false)
            call SetTextTagVelocity(.castText, 0.0, CAST_TEXT_RISE_SPEED)
            call SetTextTagLifespan(.castText, CAST_TEXT_LIFESPAN)
            call SetTextTagFadepoint(.castText, CAST_TEXT_FADEPOINT)
            set .castText = null
        endif
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
        call SetUnitPathing(.dummy, true)
        call ShowUnit(.dummy, false)
        return (.dummy != null) and (GetUnitTypeId(.dummy) != 0)
    endmethod

    private method ensureFollowTimer takes nothing returns nothing
        if .followTim == null then
            set .followTim = NewTimerEx(this)
            call TimerStart(.followTim, INTERVAL, true, function thistype.onFollowTick)
        endif
    endmethod

    private method ensureSessionTimer takes nothing returns nothing
        if .sessionTim != null then
            call ReleaseTimer(.sessionTim)
            set .sessionTim = null
        endif
        if .sessionDuration > 0. then
            set .sessionTim = NewTimerEx(this)
            call TimerStart(.sessionTim, INTERVAL, true, function thistype.onSessionTick)
        endif
    endmethod

    method queuePulse takes nothing returns nothing
        if .pulseTim != null then
            call ReleaseTimer(.pulseTim)
            set .pulseTim = null
        endif
        set .pulseTim = NewTimerEx(this)
        call TimerStart(.pulseTim, PULSE_DELAY, false, function thistype.onPulse)
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

    method applyMovePoint takes real x, real y, boolean queueAimPulse returns nothing
        set .moveX = x
        set .moveY = y
        set .hasMovePoint = true
        set .isFollowing = true

        if not .ensureDummy() then
            return
        endif

        call IssueImmediateOrderById(.source, ORDER_ID_STOP)
        call IssuePointOrder(.dummy, "move", .moveX, .moveY)
        call .ensureFollowTimer()

        if queueAimPulse then
            call .queuePulse()
        endif

        call .syncCastTextTagPosition()
    endmethod

    method beginOrRefreshSession takes integer abilityId returns nothing
        local real duration = 0.
        local integer maxRecasts = 0
        local boolean allowSmart = false
        local boolean freshSession = not .sessionActive
        local string activeStr = "0"
        local string freshStr = "0"
        local string smartStr = "0"

        if .sessionActive then
            set activeStr = "1"
        endif
        if freshSession then
            set freshStr = "1"
        endif

        set duration = castDurationByAbility.real[abilityId]
        set allowSmart = smartRecastEnabledByAbility.boolean[abilityId]
        set maxRecasts = R2I(smartRecastCountByAbility.real[abilityId])
        if allowSmart then
            set smartStr = "1"
        endif

        static if DEBUG_MODE then
            call BJDebugMsg("[MoveCast] begin ability=" + I2S(abilityId) + " active=" + activeStr + " fresh=" + freshStr + " duration=" + R2S(duration) + " allowSmart=" + smartStr + " maxRecasts=" + I2S(maxRecasts))
        endif

        set .sessionActive = true
        set .sessionDuration = duration
        set .sessionRemaining = duration
        if freshSession then
            if allowSmart and (maxRecasts > 0) then
                set .recastsLeft = maxRecasts
            else
                set .recastsLeft = 0
            endif
        endif

        static if DEBUG_MODE then
            call BJDebugMsg("[MoveCast] loaded ability=" + I2S(abilityId) + " recastsLeft=" + I2S(.recastsLeft))
        endif

        call .ensureSessionTimer()
        call .refreshCastTextTag()
    endmethod

    method consumeSmartRecast takes nothing returns nothing
        if .recastsLeft > 0 then
            set .recastsLeft = .recastsLeft - 1
            call .refreshCastTextTag()
        endif
    endmethod

    method refreshSessionDuration takes nothing returns nothing
        if .sessionActive then
            set .sessionRemaining = .sessionDuration
            call .refreshCastTextTag()
        endif
    endmethod

    method startFollowToStoredPoint takes nothing returns nothing
        if .isFollowing then
            return
        endif

        if not .hasLastSmart then
            return
        endif

        call .applyMovePoint(.lastSmartX, .lastSmartY, false)
    endmethod

    private method stopFollow takes nothing returns nothing
        if .followTim != null then
            call ReleaseTimer(.followTim)
            set .followTim = null
        endif

        if (.dummy != null) and (GetUnitTypeId(.dummy) != 0) then
            call RemoveUnit(.dummy)
        endif

        set .dummy = null
        set .lastCastTargetUnit = null
        set .isFollowing = false
        set .hasMovePoint = false
    endmethod

    method endSession takes nothing returns nothing
        if .sessionTim != null then
            call ReleaseTimer(.sessionTim)
            set .sessionTim = null
        endif

        if .pulseTim != null then
            call ReleaseTimer(.pulseTim)
            set .pulseTim = null
        endif

        call .stopFollow()
        call .releaseCastTextTag()

        set .sessionActive = false
        set .sessionDuration = 0.
        set .sessionRemaining = 0.
        set .recastsLeft = 0
        set .hasAimPoint = false
        set .lastCastAbilityId = 0
        set .lastCastOrderId = 0
        set .lastCastTargetUnit = null
    endmethod

    method destroy takes nothing returns nothing
        call .endSession()
        if .source != null then
            call table.remove(GetHandleId(.source))
        endif
        set .source = null
        set .hasLastSmart = false
        call .deallocate()
    endmethod

    private static method onFollowTick takes nothing returns nothing
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

        if .followTim != t then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            call .destroy()
            set t = null
            return
        endif

        if IsLeapBuffActive(.source) then
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
        call .syncCastTextTagPosition()

        if distSq <= ARRIVAL_THRESHOLD_SQ then
            call .endSession()
        endif

        set t = null
    endmethod

    private static method onSessionTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)

        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if .sessionTim != t then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            call .destroy()
            set t = null
            return
        endif

        if IsLeapBuffActive(.source) then
            call .destroy()
            set t = null
            return
        endif

        if .sessionRemaining <= 0. then
            call .endSession()
            set t = null
            return
        endif

        set .sessionRemaining = .sessionRemaining - INTERVAL
        if .sessionRemaining <= 0. then
            call .endSession()
        else
            call .refreshCastTextTag()
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

        if IsLeapBuffActive(.source) then
            call .destroy()
            set t = null
            return
        endif

        if (.dummy == null) or (GetUnitTypeId(.dummy) == 0) then
            set t = null
            return
        endif

        if .sessionActive and .hasAimPoint then
            if (.lastCastOrderId != 0) then
                if (.lastCastTargetUnit != null) and (GetUnitTypeId(.lastCastTargetUnit) != 0) and UnitAlive(.lastCastTargetUnit) then
                    call IssueTargetOrderById(.source, .lastCastOrderId, .lastCastTargetUnit)
                else
                    call IssuePointOrderById(.source, .lastCastOrderId, .aimX, .aimY)
                endif
            endif
        endif

        set t = null
    endmethod

    private static method onInit takes nothing returns nothing
        set table = Table.create()
    endmethod
endstruct

//===========================================================================
function RegisterMovementSpell takes integer abilityId, string orderId returns nothing
    local integer oid = OrderId(orderId)
    set registeredAbilityFlags.boolean[abilityId] = true
    set registeredOrderFlags.boolean[oid] = true
    set registeredOrderByAbility.real[abilityId] = I2R(oid)
endfunction

//===========================================================================
function RegisterMovementSpellTarget takes integer abilityId, string orderId returns nothing
    call RegisterMovementSpell(abilityId, orderId)
endfunction

//===========================================================================
function ConfigureMovementSpellCastSession takes integer abilityId, real castDuration, boolean allowSmartRecast, integer maxSmartRecasts returns nothing
    local string smartStr = "0"
    if castDuration < 0. then
        set castDuration = 0.
    endif
    if maxSmartRecasts < 0 then
        set maxSmartRecasts = 0
    endif
    if allowSmartRecast then
        set smartStr = "1"
    endif
    set castDurationByAbility.real[abilityId] = castDuration
    set smartRecastEnabledByAbility.boolean[abilityId] = allowSmartRecast
    set smartRecastCountByAbility.real[abilityId] = I2R(maxSmartRecasts)
    static if DEBUG_MODE then
        call BJDebugMsg("[MoveCast] configure ability=" + I2S(abilityId) + " duration=" + R2S(castDuration) + " allowSmart=" + smartStr + " maxRecasts=" + I2S(maxSmartRecasts))
    endif
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
    local real x
    local real y

    if (orderId == ORDER_ID_MOVE) or (orderId == ORDER_ID_SMART) then
        if IsLeapBuffActive(u) then
            if MovementData.has(u) then
                set data = MovementData.get(u)
                call data.destroy()
            endif
            set u = null
            return false
        endif
        set x = GetOrderPointX()
        set y = GetOrderPointY()
        if MovementData.has(u) then
            set data = MovementData.get(u)
        else
            set data = MovementData.create(u)
        endif

        if not data.sessionActive then
            call data.rememberPoint(x, y)
        else
            if not data.isFollowing then
                call data.applyMovePoint(x, y, false)
            else
                if data.recastsLeft > 0 then
                    call data.consumeSmartRecast()
                    call data.applyMovePoint(x, y, true)
                else
                    call IssueImmediateOrderById(u, ORDER_ID_STOP)
                    call data.endSession()
                endif
            endif
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
    local real x
    local real y

    if (orderId == ORDER_ID_SMART) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
        if IsLeapBuffActive(u) then
            if MovementData.has(u) then
                set data = MovementData.get(u)
                call data.destroy()
            endif
            set targetU = null
            set u = null
            return false
        endif
        set x = GetUnitX(targetU)
        set y = GetUnitY(targetU)
        if MovementData.has(u) then
            set data = MovementData.get(u)
        else
            set data = MovementData.create(u)
        endif

        if not data.sessionActive then
            call data.rememberPoint(x, y)
        else
            if not data.isFollowing then
                call data.applyMovePoint(x, y, false)
            else
                if data.recastsLeft > 0 then
                    call data.consumeSmartRecast()
                    call data.applyMovePoint(x, y, true)
                else
                    call IssueImmediateOrderById(u, ORDER_ID_STOP)
                    call data.endSession()
                endif
            endif
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

    if abilityId == LOADOUT_LEAP_SPELL_ID then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set targetU = null
        set u = null
        return false
    endif

    if IsLeapBuffActive(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set targetU = null
        set u = null
        return false
    endif

    if registeredAbilityFlags.boolean[abilityId] then
        if MovementData.has(u) then
            set data = MovementData.get(u)
        else
            set data = MovementData.create(u)
        endif

        if (targetU != null) and (GetUnitTypeId(targetU) != 0) then
            set tx = GetUnitX(targetU)
            set ty = GetUnitY(targetU)
        endif

        set data.lastCastAbilityId = abilityId
        set data.lastCastOrderId = R2I(registeredOrderByAbility.real[abilityId])
        set data.lastCastTargetUnit = null
        if (targetU != null) and (GetUnitTypeId(targetU) != 0) then
            set data.lastCastTargetUnit = targetU
        endif
        call data.setAimPoint(tx, ty)
        call data.beginOrRefreshSession(abilityId)

        if (not data.isFollowing) and data.hasLastSmart then
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
    set registeredAbilityFlags = Table.create()
    set registeredOrderFlags = Table.create()
    set registeredOrderByAbility = Table.create()
    set castDurationByAbility = Table.create()
    set smartRecastEnabledByAbility = Table.create()
    set smartRecastCountByAbility = Table.create()
    set ORDER_ID_MOVE = OrderId("move")
    set ORDER_ID_SMART = OrderId("smart")
    set ORDER_ID_STOP = OrderId("stop")

    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function OnSpellEffect)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnUnitDeath)

    static if DEBUG_MODE then
        call BJDebugMsg("[MovementSystem] initialized")
    endif
endfunction

endlibrary
