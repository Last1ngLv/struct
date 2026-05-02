//===========================================================================
//
//  MovementSystem v2 - DIRECT HERO MOVECAST
//  - no dummy follower
//  - registered spell casts open/refresh a fixed 1s move-cast session
//  - move/smart during the session redirects the hero manually
//  - smart recasts can re-issue the last registered spell while moving
//
//===========================================================================
library MovementSystem initializer Init requires TimerUtils, Table, RegisterPlayerUnitEvent, TextTagDebug, TerrainPathability

globals
    private constant real INTERVAL = 0.03125
    private constant real MOVECAST_SESSION_DURATION = 1.00
    private constant real ARRIVAL_THRESHOLD = 50.0
    private constant real ARRIVAL_THRESHOLD_SQ = ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD
    private constant real SMART_POINT_TOLERANCE = 128.0
    private constant real SMART_POINT_TOLERANCE_SQ = SMART_POINT_TOLERANCE * SMART_POINT_TOLERANCE
    private constant integer LOADOUT_LEAP_SPELL_ID = 'U0A2'
    private constant integer LEAP_BUFF_ID = 'BB01'
    private constant integer MAX_MOVECAST_PLAYER_ID = 7
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
    private Table registeredOrderByAbility
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

private function IsMoveCastTrackedUnit takes unit u returns boolean
    local player owner
    local integer pid

    if (u == null) or (GetUnitTypeId(u) == 0) then
        return false
    endif

    set owner = GetOwningPlayer(u)
    set pid = GetPlayerId(owner)

    if (pid < 0) or (pid > MAX_MOVECAST_PLAYER_ID) then
        set owner = null
        return false
    endif

    if GetPlayerSlotState(owner) != PLAYER_SLOT_STATE_PLAYING then
        set owner = null
        return false
    endif

    if GetPlayerController(owner) != MAP_CONTROL_USER then
        set owner = null
        return false
    endif

    if not IsUnitType(u, UNIT_TYPE_HERO) then
        set owner = null
        return false
    endif

    set owner = null
    return true
endfunction

private function DistanceSq takes real ax, real ay, real bx, real by returns real
    return (ax - bx) * (ax - bx) + (ay - by) * (ay - by)
endfunction

struct MovementData
    unit source
    timer moveTim
    timer sessionTim
    timer pulseTim
    texttag castText
    real lastSmartX
    real lastSmartY
    boolean hasLastSmart
    real moveX
    real moveY
    boolean hasMovePoint
    real aimX
    real aimY
    boolean hasAimPoint
    integer lastCastAbilityId
    integer lastCastOrderId
    unit lastCastTargetUnit
    boolean isMoving
    boolean sessionActive
    boolean isDestroying
    real sessionRemaining
    integer recastsLeft

    private static Table table

    static method init takes nothing returns nothing
        set table = Table.create()
    endmethod

    static method create takes unit u returns thistype
        local thistype this = thistype.allocate()

        if this == 0 then
            return 0
        endif

        set .source = u
        set .moveTim = null
        set .sessionTim = null
        set .pulseTim = null
        set .castText = null
        set .lastSmartX = 0.
        set .lastSmartY = 0.
        set .hasLastSmart = false
        set .moveX = 0.
        set .moveY = 0.
        set .hasMovePoint = false
        set .aimX = 0.
        set .aimY = 0.
        set .hasAimPoint = false
        set .lastCastAbilityId = 0
        set .lastCastOrderId = 0
        set .lastCastTargetUnit = null
        set .isMoving = false
        set .sessionActive = false
        set .isDestroying = false
        set .sessionRemaining = 0.
        set .recastsLeft = 0

        set table[GetHandleId(u)] = this
        return this
    endmethod

    static method has takes unit u returns boolean
        return (u != null) and table.has(GetHandleId(u))
    endmethod

    static method get takes unit u returns thistype
        if u == null then
            return 0
        endif
        return table[GetHandleId(u)]
    endmethod

    static method forget takes unit u returns nothing
        if u != null then
            call table.remove(GetHandleId(u))
        endif
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
            set .castText = CreateTrackedTextTag(TEXTTAG_DEBUG_MOVECAST)
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
            call ReleaseTrackedTextTag(TEXTTAG_DEBUG_MOVECAST)
            set .castText = null
        endif
    endmethod

    private method ensureMoveTimer takes nothing returns nothing
        if .moveTim == null then
            set .moveTim = NewTimerEx(this)
            call SetTimerDebugTag(.moveTim, TIMER_DEBUG_TAG_MOVECAST)
            call TimerStart(.moveTim, INTERVAL, true, function thistype.onMoveTick)
        endif
    endmethod

    private method ensureSessionTimer takes nothing returns nothing
        if .sessionTim == null then
            set .sessionTim = NewTimerEx(this)
            call SetTimerDebugTag(.sessionTim, TIMER_DEBUG_TAG_MOVECAST)
            call TimerStart(.sessionTim, INTERVAL, true, function thistype.onSessionTick)
        endif
    endmethod

    method queuePulse takes nothing returns nothing
        if .pulseTim != null then
            call ReleaseTimer(.pulseTim)
            set .pulseTim = null
        endif
        set .pulseTim = NewTimerEx(this)
        call SetTimerDebugTag(.pulseTim, TIMER_DEBUG_TAG_MOVECAST)
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

    method isPointTooClose takes real x, real y returns boolean
        if (.source == null) or (GetUnitTypeId(.source) == 0) then
            return true
        endif
        return DistanceSq(GetUnitX(.source), GetUnitY(.source), x, y) <= SMART_POINT_TOLERANCE_SQ
    endmethod

    method applyMovePoint takes real x, real y, boolean queueAimPulse returns nothing
        if .isPointTooClose(x, y) then
            call .rememberPoint(x, y)
            return
        endif

        set .moveX = x
        set .moveY = y
        set .hasMovePoint = true
        set .isMoving = true

        call IssueImmediateOrderById(.source, ORDER_ID_STOP)
        call .ensureMoveTimer()

        if queueAimPulse then
            call .queuePulse()
        endif

        call .syncCastTextTagPosition()
    endmethod

    method beginOrRefreshSession takes integer abilityId returns nothing
        local integer maxRecasts = 0
        local boolean allowSmart = false
        local boolean freshSession = not .sessionActive
        local string freshStr = "0"
        local string smartStr = "0"

        if freshSession then
            set freshStr = "1"
        endif

        set allowSmart = smartRecastEnabledByAbility.boolean[abilityId]
        set maxRecasts = R2I(smartRecastCountByAbility.real[abilityId])
        if allowSmart then
            set smartStr = "1"
        endif

        static if DEBUG_MODE then
            call BJDebugMsg("[MoveCast] begin ability=" + I2S(abilityId) + " fresh=" + freshStr + " duration=" + R2S(MOVECAST_SESSION_DURATION) + " allowSmart=" + smartStr + " maxRecasts=" + I2S(maxRecasts))
        endif

        set .sessionActive = true
        set .sessionRemaining = MOVECAST_SESSION_DURATION
        if freshSession then
            if allowSmart and (maxRecasts > 0) then
                set .recastsLeft = maxRecasts
            else
                set .recastsLeft = 0
            endif
        endif

        call .ensureSessionTimer()
        call .refreshCastTextTag()
    endmethod

    method consumeSmartRecast takes nothing returns nothing
        if .recastsLeft > 0 then
            set .recastsLeft = .recastsLeft - 1
            set .sessionRemaining = MOVECAST_SESSION_DURATION
            call .refreshCastTextTag()
        endif
    endmethod

    method refreshSessionDuration takes nothing returns nothing
        if .sessionActive then
            set .sessionRemaining = MOVECAST_SESSION_DURATION
            call .refreshCastTextTag()
        endif
    endmethod

    method startMoveToStoredPoint takes nothing returns nothing
        if .isMoving then
            return
        endif

        if not .hasLastSmart then
            return
        endif

        call .applyMovePoint(.lastSmartX, .lastSmartY, false)
    endmethod

    private method stopMovement takes nothing returns nothing
        if .moveTim != null then
            call ReleaseTimer(.moveTim)
            set .moveTim = null
        endif
        set .isMoving = false
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

        call .stopMovement()
        call .releaseCastTextTag()

        set .sessionActive = false
        set .sessionRemaining = 0.
        set .recastsLeft = 0
        set .hasAimPoint = false
        set .lastCastAbilityId = 0
        set .lastCastOrderId = 0
        set .lastCastTargetUnit = null
    endmethod

    private method endSessionAndRestoreMovement takes nothing returns nothing
        local unit u = .source
        local boolean hadMove = .isMoving and .hasMovePoint
        local real targetX = .moveX
        local real targetY = .moveY

        call .endSession()

        if (not hadMove) or (u == null) or (GetUnitTypeId(u) == 0) or (not UnitAlive(u)) then
            set u = null
            return
        endif

        if IsLeapBuffActive(u) then
            set u = null
            return
        endif

        if DistanceSq(GetUnitX(u), GetUnitY(u), targetX, targetY) > SMART_POINT_TOLERANCE_SQ then
            call IssuePointOrder(u, "smart", targetX, targetY)
        endif

        set u = null
    endmethod

    private method endSessionByCollision takes nothing returns nothing
        call .endSession()
        if (.source != null) and (GetUnitTypeId(.source) != 0) and UnitAlive(.source) then
            call IssueImmediateOrderById(.source, ORDER_ID_STOP)
        endif
    endmethod

    method destroy takes nothing returns nothing
        local unit u

        if .isDestroying then
            return
        endif
        set .isDestroying = true
        set u = .source

        call .endSession()
        call thistype.forget(u)

        set .source = null
        set .lastCastTargetUnit = null
        set .hasLastSmart = false
        set .isDestroying = false
        call .deallocate()

        set u = null
    endmethod

    private static method onMoveTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        local real sx
        local real sy
        local real dx
        local real dy
        local real distSq
        local real dist
        local real step
        local real nx
        local real ny

        if this == 0 then
            set t = null
            return
        endif

        if .moveTim != t then
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

        if (not .sessionActive) or (not .hasMovePoint) then
            call .stopMovement()
            set t = null
            return
        endif

        set sx = GetUnitX(.source)
        set sy = GetUnitY(.source)
        set dx = .moveX - sx
        set dy = .moveY - sy
        set distSq = dx * dx + dy * dy

        if distSq <= ARRIVAL_THRESHOLD_SQ then
            call .endSession()
            set t = null
            return
        endif

        set dist = SquareRoot(distSq)
        set step = GetUnitMoveSpeed(.source) * INTERVAL
        if step <= 0. then
            call .endSessionByCollision()
            set t = null
            return
        endif
        if step > dist then
            set step = dist
        endif

        set nx = sx + dx / dist * step
        set ny = sy + dy / dist * step

        if not IsTerrainWalkable(nx, ny) then
            call .endSessionByCollision()
            set t = null
            return
        endif

        call SetUnitX(.source, nx)
        call SetUnitY(.source, ny)
        call .syncCastTextTagPosition()

        set t = null
    endmethod

    private static method onSessionTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)

        if this == 0 then
            set t = null
            return
        endif

        if .sessionTim != t then
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

        set .sessionRemaining = .sessionRemaining - INTERVAL
        if .sessionRemaining <= 0. then
            call .endSessionAndRestoreMovement()
        else
            call .refreshCastTextTag()
        endif

        set t = null
    endmethod

    private static method onPulse takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)

        if this == 0 then
            set t = null
            return
        endif

        if .pulseTim != t then
            set t = null
            return
        endif

        set .pulseTim = null

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if IsLeapBuffActive(.source) then
            call .destroy()
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if .sessionActive and .hasAimPoint and (.lastCastOrderId != 0) then
            if (.lastCastTargetUnit != null) and (GetUnitTypeId(.lastCastTargetUnit) != 0) and UnitAlive(.lastCastTargetUnit) then
                call IssueTargetOrderById(.source, .lastCastOrderId, .lastCastTargetUnit)
            else
                call IssuePointOrderById(.source, .lastCastOrderId, .aimX, .aimY)
            endif
        endif

        call ReleaseTimer(t)
        set t = null
    endmethod
endstruct

private function GetOrCreateMovementData takes unit u returns MovementData
    local MovementData data

    if not IsMoveCastTrackedUnit(u) then
        return 0
    endif

    if MovementData.has(u) then
        return MovementData.get(u)
    endif

    set data = MovementData.create(u)
    return data
endfunction

private function DestroyMovementDataForUnit takes unit u returns nothing
    local MovementData data

    if u == null then
        return
    endif

    if MovementData.has(u) then
        set data = MovementData.get(u)
        if data != 0 then
            call data.destroy()
        endif
    endif
endfunction

//===========================================================================
function RegisterMovementSpell takes integer abilityId, string orderId returns nothing
    local integer oid = OrderId(orderId)
    set registeredAbilityFlags.boolean[abilityId] = true
    set registeredOrderByAbility.real[abilityId] = I2R(oid)
endfunction

//===========================================================================
function RegisterMovementSpellTarget takes integer abilityId, string orderId returns nothing
    call RegisterMovementSpell(abilityId, orderId)
endfunction

//===========================================================================
function ConfigureMovementSpellCastSession takes integer abilityId, real castDuration, boolean allowSmartRecast, integer maxSmartRecasts returns nothing
    if maxSmartRecasts < 0 then
        set maxSmartRecasts = 0
    endif

    set smartRecastEnabledByAbility.boolean[abilityId] = allowSmartRecast
    set smartRecastCountByAbility.real[abilityId] = I2R(maxSmartRecasts)

    static if DEBUG_MODE then
        call BJDebugMsg("[MoveCast] configure ability=" + I2S(abilityId) + " requestedDuration=" + R2S(castDuration) + " fixedDuration=" + R2S(MOVECAST_SESSION_DURATION) + " maxRecasts=" + I2S(maxSmartRecasts))
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
function CancelMovementSpellSessionForUnit takes unit u returns nothing
    if u == null or GetUnitTypeId(u) == 0 then
        return
    endif
    call DestroyMovementDataForUnit(u)
endfunction

//===========================================================================
private function OnPointOrder takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    local real x
    local real y

    if not IsMoveCastTrackedUnit(u) then
        set u = null
        return false
    endif

    if (orderId == ORDER_ID_MOVE) or (orderId == ORDER_ID_SMART) then
        if IsLeapBuffActive(u) then
            call DestroyMovementDataForUnit(u)
            set u = null
            return false
        endif

        set x = GetOrderPointX()
        set y = GetOrderPointY()
        set data = GetOrCreateMovementData(u)
        if data == 0 then
            set u = null
            return false
        endif

        if not data.sessionActive then
            call data.rememberPoint(x, y)
        elseif data.isPointTooClose(x, y) then
            call data.rememberPoint(x, y)
        elseif not data.isMoving then
            call data.applyMovePoint(x, y, false)
        elseif data.recastsLeft > 0 then
            call data.consumeSmartRecast()
            call data.applyMovePoint(x, y, true)
        else
            call IssueImmediateOrderById(u, ORDER_ID_STOP)
            call data.endSession()
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

    if not IsMoveCastTrackedUnit(u) then
        set targetU = null
        set u = null
        return false
    endif

    if (orderId == ORDER_ID_SMART) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
        if IsLeapBuffActive(u) then
            call DestroyMovementDataForUnit(u)
            set targetU = null
            set u = null
            return false
        endif

        set x = GetUnitX(targetU)
        set y = GetUnitY(targetU)
        set data = GetOrCreateMovementData(u)
        if data == 0 then
            set targetU = null
            set u = null
            return false
        endif

        if not data.sessionActive then
            call data.rememberPoint(x, y)
        elseif data.isPointTooClose(x, y) then
            call data.rememberPoint(x, y)
        elseif not data.isMoving then
            call data.applyMovePoint(x, y, false)
        elseif data.recastsLeft > 0 then
            call data.consumeSmartRecast()
            call data.applyMovePoint(x, y, true)
        else
            call IssueImmediateOrderById(u, ORDER_ID_STOP)
            call data.endSession()
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

    if not IsMoveCastTrackedUnit(u) then
        set targetU = null
        set u = null
        return false
    endif

    if abilityId == LOADOUT_LEAP_SPELL_ID then
        call DestroyMovementDataForUnit(u)
        set targetU = null
        set u = null
        return false
    endif

    if IsLeapBuffActive(u) then
        call DestroyMovementDataForUnit(u)
        set targetU = null
        set u = null
        return false
    endif

    if registeredAbilityFlags.boolean[abilityId] then
        set data = GetOrCreateMovementData(u)
        if data == 0 then
            set targetU = null
            set u = null
            return false
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
        call SetUnitFacing(u, Atan2(ty - GetUnitY(u), tx - GetUnitX(u)) * bj_RADTODEG)
        call data.beginOrRefreshSession(abilityId)

        if (not data.isMoving) and data.hasLastSmart then
            call data.startMoveToStoredPoint()
        endif
    endif

    set targetU = null
    set u = null
    return false
endfunction

//===========================================================================
private function OnUnitDeath takes nothing returns boolean
    local unit u = GetTriggerUnit()
    call DestroyMovementDataForUnit(u)
    set u = null
    return false
endfunction

//===========================================================================
private function Init takes nothing returns nothing
    set registeredAbilityFlags = Table.create()
    set registeredOrderByAbility = Table.create()
    set smartRecastEnabledByAbility = Table.create()
    set smartRecastCountByAbility = Table.create()
    set ORDER_ID_MOVE = OrderId("move")
    set ORDER_ID_SMART = OrderId("smart")
    set ORDER_ID_STOP = OrderId("stop")

    call MovementData.init()

    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function OnSpellEffect)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnUnitDeath)
endfunction

endlibrary
