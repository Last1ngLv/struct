//===========================================================================
//
//  MovementSystem v3.0 - ORDER-BASED
//  Sistema de movimiento que responde INMEDIATAMENTE a órdenes de hechizos
//  
//  - Captura la orden ANTES del giro/animación
//  - Registra hechizos con su OrderId string
//  - Mucho más responsivo que versiones basadas en EFFECT
//
//  Requires:
//  ---------
//  - TimerUtils
//  - Table
//  - RegisterPlayerUnitEvent
//  - IsUnitChanneling (opcional pero recomendado)
//
//===========================================================================
library MovementSystem initializer Init requires TimerUtils, Table, RegisterPlayerUnitEvent, optional IsUnitChanneling, optional PlayerMissileLoadout

globals
    // Configuración
    private constant real INTERVAL = 0.03125
    private constant real ARRIVAL_THRESHOLD = 50.0
    private constant real ARRIVAL_THRESHOLD_SQ = ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD
    private constant real DATA_IDLE_TIMEOUT = 10.0
    private constant real RECAST_LOCK_TIMEOUT = 0.60
    private constant real CHANNEL_END_GRACE_TIMEOUT = 0.20
    private constant integer DUMMY_UNIT_ID = 'h003'   // CAMBIAR
    private constant integer IGNORE_BUFF_ID = 'BB01'
    
    // Comportamiento
    private constant boolean INSTANT_CASTS_USE_DUMMY = true  
    
    // Debug
    private constant boolean DEBUG_MODE = false
    
    // Tabla de habilidades registradas: OrderId -> AbilityId
    private Table registeredSpells
    // Tabla inversa: AbilityId -> OrderId
    private Table abilityOrderSpells
    
    // Tabla de OrderId -> Boolean (para órdenes target)
    private Table targetOrderSpells
    // Tabla de OrderId -> Boolean (habilita recast explícito)
    private Table recastOrderSpells

    private integer ORDER_ID_MOVE
    private integer ORDER_ID_SMART
    private integer ORDER_ID_STOP
    private integer ORDER_ID_HOLD_POSITION
endglobals

//===========================================================================
// Struct principal
//===========================================================================
struct MovementData
    unit source          
    unit dummy           
    effect casterFollowFx
    unit targetUnit
    real targetX         
    real targetY         
    timer tim            
    timer gcTim
    timer recastTim
    timer recastIssueTim
    timer channelEndTim
    boolean isMoving     
    boolean hasDummy     
    boolean followTarget
    boolean recastInFlight
    boolean channelCanRecast
    integer channelOrderId
    real channelTargetX
    real channelTargetY
    
    private static Table table
    
    //=======================================================================
    // Constructor
    //=======================================================================
    static method create takes unit u returns thistype
        local thistype this = thistype.allocate()
        
        set .source = u
        set .dummy = null
        set .casterFollowFx = null
        set .targetUnit = null
        set .targetX = 0
        set .targetY = 0
        set .tim = null
        set .gcTim = null
        set .recastTim = null
        set .recastIssueTim = null
        set .channelEndTim = null
        set .isMoving = false
        set .hasDummy = false
        set .followTarget = false
        set .recastInFlight = false
        set .channelCanRecast = false
        set .channelOrderId = 0
        set .channelTargetX = 0.
        set .channelTargetY = 0.
        
        set table[GetHandleId(u)] = this
        
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Created for: " + GetUnitName(u))
        endif

        call .armIdleCleanup()
        
        return this
    endmethod
    
    //=======================================================================
    static method get takes unit u returns thistype
        local integer id = GetHandleId(u)
        if table.has(id) then
            return table[id]
        endif
        return 0
    endmethod
    
    //=======================================================================
    static method has takes unit u returns boolean
        return table.has(GetHandleId(u))
    endmethod

    //=======================================================================
    private static method onRecastUnlock takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif
        if .recastTim == t then
            set .recastTim = null
        endif
        set .recastInFlight = false
        call ReleaseTimer(t)
        set t = null
    endmethod

    //=======================================================================
    private static method onRecastIssue takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif
        if .recastIssueTim == t then
            set .recastIssueTim = null
        endif
        call ReleaseTimer(t)
        set t = null

        if .channelOrderId == 0 then
            return
        endif
        if not .channelCanRecast then
            return
        endif
        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            return
        endif
        call IssuePointOrderById(.source, .channelOrderId, .channelTargetX, .channelTargetY)
    endmethod

    //=======================================================================
    private method lockRecast takes nothing returns nothing
        if .recastTim != null then
            call ReleaseTimer(.recastTim)
            set .recastTim = null
        endif
        set .recastInFlight = true
        set .recastTim = NewTimerEx(this)
        call TimerStart(.recastTim, RECAST_LOCK_TIMEOUT, false, function thistype.onRecastUnlock)
    endmethod

    //=======================================================================
    private method unlockRecast takes nothing returns nothing
        if .recastIssueTim != null then
            call ReleaseTimer(.recastIssueTim)
            set .recastIssueTim = null
        endif
        if .recastTim != null then
            call ReleaseTimer(.recastTim)
            set .recastTim = null
        endif
        set .recastInFlight = false
    endmethod

    //=======================================================================
    private static method onChannelEndFinalize takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif
        if .channelEndTim == t then
            set .channelEndTim = null
        endif
        call ReleaseTimer(t)
        set t = null

        if (.source == null) or (GetUnitTypeId(.source) == 0) then
            return
        endif
        call .endChannelTracking()
        call .onSpellEnd()
    endmethod

    //=======================================================================
    method scheduleChannelEndFinalize takes nothing returns nothing
        if .channelEndTim != null then
            call ReleaseTimer(.channelEndTim)
            set .channelEndTim = null
        endif
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Scheduling delayed channel end finalize")
        endif
        set .channelEndTim = NewTimerEx(this)
        call TimerStart(.channelEndTim, CHANNEL_END_GRACE_TIMEOUT, false, function thistype.onChannelEndFinalize)
    endmethod

    //=======================================================================
    method cancelChannelEndFinalize takes nothing returns nothing
        if .channelEndTim != null then
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Cancel delayed channel end finalize")
            endif
            call ReleaseTimer(.channelEndTim)
            set .channelEndTim = null
        endif
    endmethod

    //=======================================================================
    method beginChannelTracking takes integer orderId, real tx, real ty, boolean canRecast returns nothing
        call .cancelChannelEndFinalize()
        set .channelOrderId = orderId
        set .channelTargetX = tx
        set .channelTargetY = ty
        set .channelCanRecast = canRecast
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Tracking channel order id: " + I2S(orderId))
        endif
        call .unlockRecast()
    endmethod

    //=======================================================================
    method endChannelTracking takes nothing returns nothing
        call .cancelChannelEndFinalize()
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Channel tracking cleared")
        endif
        set .channelOrderId = 0
        set .channelTargetX = 0.
        set .channelTargetY = 0.
        set .channelCanRecast = false
        call .unlockRecast()
    endmethod

    //=======================================================================
    method tryRecastTrackedChannel takes nothing returns nothing
        if .recastInFlight then
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Recast skipped: recast lock active")
            endif
            return
        endif
        if not .channelCanRecast then
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Recast skipped: order not marked for recast")
            endif
            return
        endif
        if .channelOrderId == 0 then
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Recast skipped: no tracked channel order")
            endif
            return
        endif
        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Recast skipped: invalid source")
            endif
            return
        endif
        call .cancelChannelEndFinalize()
        // If recast is disabled for this player, keep the redirect movement flow
        // but do not re-issue the channel order.
        static if LIBRARY_PlayerMissileLoadout then
            if not GetPlayerMissileUseSmartRecast(GetOwningPlayer(.source)) then
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Recast skipped: disabled by loadout")
                endif
                return
            endif
        endif
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Recast issuing tracked order id: " + I2S(.channelOrderId))
        endif
        call .lockRecast()
        call IssuePointOrderById(.source, .channelOrderId, .channelTargetX, .channelTargetY)
    endmethod

    //=======================================================================
    private method armIdleCleanup takes nothing returns nothing
        if .gcTim != null then
            call ReleaseTimer(.gcTim)
            set .gcTim = null
        endif
        set .gcTim = NewTimerEx(this)
        call TimerStart(.gcTim, DATA_IDLE_TIMEOUT, false, function thistype.onIdleExpire)
    endmethod

    //=======================================================================
    private static method onIdleExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        local real sx
        local real sy

        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if .gcTim == t then
            set .gcTim = null
        endif
        call ReleaseTimer(t)
        set t = null

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            call .destroy()
            return
        endif
        if GetUnitAbilityLevel(.source, IGNORE_BUFF_ID) > 0 then
            call .destroy()
            return
        endif

        if .hasDummy then
            call .armIdleCleanup()
            return
        endif

        if not .isMoving then
            call .destroy()
            return
        endif

        if .followTarget then
            if (.targetUnit == null) or (GetUnitTypeId(.targetUnit) == 0) or (not UnitAlive(.targetUnit)) then
                call .destroy()
                return
            endif
            call .armIdleCleanup()
            return
        endif

        set sx = GetUnitX(.source)
        set sy = GetUnitY(.source)
        if .getDistanceSquared(sx, sy, .targetX, .targetY) <= ARRIVAL_THRESHOLD_SQ then
            call .destroy()
            return
        endif

        call .armIdleCleanup()
    endmethod
    
    //=======================================================================
    private method getDistanceSquared takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        return dx * dx + dy * dy
    endmethod
    
    //=======================================================================
    // Callback periódico del timer
    //=======================================================================
    private static method periodic takes nothing returns nothing
        local thistype this = GetTimerData(GetExpiredTimer())
        local real dummyX
        local real dummyY
        local real distSq
        
        if this == 0 then
            return
        endif

        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            call .destroy()
            return
        endif
        if GetUnitAbilityLevel(.source, IGNORE_BUFF_ID) > 0 then
            call .destroy()
            return
        endif

        if .followTarget then
            if (.targetUnit == null) or (GetUnitTypeId(.targetUnit) == 0) or (not UnitAlive(.targetUnit)) then
                set .isMoving = false
                set .followTarget = false
                set .targetUnit = null
                call .stopDummyMovement()
                call .destroy()
                return
            endif
            set .targetX = GetUnitX(.targetUnit)
            set .targetY = GetUnitY(.targetUnit)
        endif
        
        if .dummy != null and GetUnitTypeId(.dummy) != 0 then
            set dummyX = GetUnitX(.dummy)
            set dummyY = GetUnitY(.dummy)
            set distSq = .getDistanceSquared(dummyX, dummyY, .targetX, .targetY)
            
            // Teleportar la unidad al dummy
            call SetUnitX(.source, dummyX)
            call SetUnitY(.source, dummyY)
            
            // Verificar llegada
            if (not .followTarget) and (distSq < ARRIVAL_THRESHOLD_SQ) then
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Arrived at destination")
                endif
                
                if (IsTerrainWalkable(dummyX, dummyY)) then
                else
                    call SetUnitX(.source, TerrainPathability_X)
                    call SetUnitY(.source, TerrainPathability_Y)
                endif

                set .isMoving = false
                set .targetUnit = null
                call .stopDummyMovement()
                call .destroy()
            endif
        else
            set .isMoving = false
            set .targetUnit = null
            set .followTarget = false
            call .stopDummyMovement()
            call .destroy()
        endif
    endmethod
    
    //=======================================================================
    // Iniciar movimiento con dummy
    //=======================================================================
    method startDummyMovement takes nothing returns nothing
        local real unitX
        local real unitY
        local real angle
        local unit follow
        local string followFxModel
        
        if .hasDummy then
            return
        endif
        if .casterFollowFx != null then
            call DestroyEffect(.casterFollowFx)
            set .casterFollowFx = null
        endif
        
        set unitX = GetUnitX(.source)
        set unitY = GetUnitY(.source)

        if .followTarget then
            set follow = .targetUnit
            if (follow == null) or (GetUnitTypeId(follow) == 0) or (not UnitAlive(follow)) then
                set .isMoving = false
                set .followTarget = false
                set .targetUnit = null
                set follow = null
                return
            endif
            set .targetX = GetUnitX(follow)
            set .targetY = GetUnitY(follow)
        endif

        // Crear dummy
        set .dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_UNIT_ID, unitX, unitY, 0)
        
        //call IssueImmediateOrderById( .dummy, OrderId("windwalk") )
        //call SetUnitX(.dummy,unitX)
        //call SetUnitY(.dummy,unitY)
        
        call SetUnitInvulnerable(.dummy, true)
        //call SetUnitPathing(.dummy, false)
        call ShowUnit(.dummy, false)
        
        // Orientar hacia destino
        set angle = Atan2(.targetY - unitY, .targetX - unitX) * bj_RADTODEG
        call SetUnitFacing(.dummy, angle)
        
        //call UnitAddAbility(.dummy,'Aloc')
        // Mover dummy al destino o seguir target de smart-click.
        if .followTarget then
            call IssueTargetOrder(.dummy, "smart", .targetUnit)
        else
            call IssuePointOrder(.dummy, "move", .targetX, .targetY)
        endif
        
        set .hasDummy = true
        
        static if LIBRARY_PlayerMissileLoadout then
            set followFxModel = GetPlayerLeapCasterFx1(GetOwningPlayer(.source))
            if (followFxModel != null) and (followFxModel != "") then
                set .casterFollowFx = AddSpecialEffectTarget(followFxModel, .source, "origin")
            endif
        endif
        
        // Timer para copiar posición
        set .tim = NewTimerEx(this)
        call TimerStart(.tim, INTERVAL, true, function thistype.periodic)
        call .armIdleCleanup()
        
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Dummy created - continuing trajectory")
        endif
        set follow = null
        set followFxModel = null
    endmethod
    
    //=======================================================================
    // Detener movimiento con dummy
    //=======================================================================
    method stopDummyMovement takes nothing returns nothing
        if .tim != null then
            call ReleaseTimer(.tim)
            set .tim = null
        endif
        
        if .casterFollowFx != null then
            call DestroyEffect(.casterFollowFx)
            set .casterFollowFx = null
        endif
        
        if .dummy != null then
            call RemoveUnit(.dummy)
            set .dummy = null
        endif
        
        set .hasDummy = false
    endmethod
    
    //=======================================================================
    // Restaurar movimiento normal
    //=======================================================================
    method restoreNormalMovement takes nothing returns nothing
        call .stopDummyMovement()
        
        if .isMoving then
            if .followTarget and (.targetUnit != null) and (GetUnitTypeId(.targetUnit) != 0) and UnitAlive(.targetUnit) then
                call IssueTargetOrder(.source, "smart", .targetUnit)
            else
                call IssuePointOrder(.source, "smart", .targetX, .targetY)
            endif
            
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Movement restored")
            endif
        endif
        call .armIdleCleanup()
    endmethod
    
    //=======================================================================
    // Reiniciar movimiento
    //=======================================================================
    method resetMovement takes real x, real y returns nothing
        set .targetX = x
        set .targetY = y
        set .isMoving = true
        set .followTarget = false
        set .targetUnit = null
        if .hasDummy and (.dummy != null) and (GetUnitTypeId(.dummy) != 0) then
            call IssuePointOrder(.dummy, "move", x, y)
        endif
        call .armIdleCleanup()
    endmethod

    //=======================================================================
    method resetMovementTarget takes unit target returns nothing
        if (target == null) or (GetUnitTypeId(target) == 0) or (not UnitAlive(target)) then
            set .isMoving = false
            set .followTarget = false
            set .targetUnit = null
            call .armIdleCleanup()
            return
        endif
        set .targetUnit = target
        set .targetX = GetUnitX(target)
        set .targetY = GetUnitY(target)
        set .isMoving = true
        set .followTarget = true
        if .hasDummy and (.dummy != null) and (GetUnitTypeId(.dummy) != 0) then
            call IssueTargetOrder(.dummy, "smart", target)
        endif
        call .armIdleCleanup()
    endmethod

    //=======================================================================
    // Guardar destino durante cast sin redirigir al dummy (modo base)
    //=======================================================================
    method queueMovementDuringCast takes real x, real y returns nothing
        if .hasDummy then
            call .stopDummyMovement()
        endif
        set .targetX = x
        set .targetY = y
        set .isMoving = true
        set .followTarget = false
        set .targetUnit = null
        call .armIdleCleanup()
    endmethod

    //=======================================================================
    // Guardar seguimiento target durante cast sin redirigir al dummy
    //=======================================================================
    method queueMovementTargetDuringCast takes unit target returns nothing
        if .hasDummy then
            call .stopDummyMovement()
        endif
        if (target == null) or (GetUnitTypeId(target) == 0) or (not UnitAlive(target)) then
            set .isMoving = false
            set .followTarget = false
            set .targetUnit = null
            call .armIdleCleanup()
            return
        endif
        set .targetUnit = target
        set .targetX = GetUnitX(target)
        set .targetY = GetUnitY(target)
        set .isMoving = true
        set .followTarget = true
        call .armIdleCleanup()
    endmethod
    
    //=======================================================================
    // Procesar orden de hechizo (EARLY - antes del giro)
    //=======================================================================
    method onSpellOrder takes nothing returns nothing
        local boolean shouldUseDummy = false
        
        if not .isMoving or .hasDummy then
            return
        endif
        
        // SIEMPRE crear dummy cuando se ordena el hechizo
        // (incluso antes de saber si es canalizado o no)
        set shouldUseDummy = true
        
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Spell order detected - starting dummy IMMEDIATELY")
        endif
        
        if shouldUseDummy then
            call .startDummyMovement()
            call .armIdleCleanup()
        endif
    endmethod
    
    //=======================================================================
    // Procesar efecto de hechizo (para verificar channeling)
    //=======================================================================
    method onSpellEffect takes nothing returns nothing
        // Si no es channeling y no queremos dummy para instantáneos
        static if LIBRARY_IsUnitChanneling then
            if IsUnitChanneling(.source) then
                // Channel confirmed: ensure dummy follow starts
                // even if it was not started during early order phase.
                if (.channelOrderId != 0) and .isMoving and (not .hasDummy) then
                    call .startDummyMovement()
                    call .armIdleCleanup()
                endif
            elseif not INSTANT_CASTS_USE_DUMMY then
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Instant cast detected - removing dummy")
                endif
                call .restoreNormalMovement()
            else
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Channeling confirmed - keeping dummy")
                endif
            endif
        endif
    endmethod
    
    //=======================================================================
    // Procesar fin de cast
    //=======================================================================
    method onSpellEnd takes nothing returns nothing
        if .hasDummy then
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Spell ended - restoring movement")
            endif
            call .restoreNormalMovement()
        endif
    endmethod
    
    //=======================================================================
    // Destruir
    //=======================================================================
    method destroy takes nothing returns nothing
    
        if .source == null then
            return
        endif
        call .stopDummyMovement()
        if .gcTim != null then
            call ReleaseTimer(.gcTim)
            set .gcTim = null
        endif
        if .recastTim != null then
            call ReleaseTimer(.recastTim)
            set .recastTim = null
        endif
        if .recastIssueTim != null then
            call ReleaseTimer(.recastIssueTim)
            set .recastIssueTim = null
        endif
        if .channelEndTim != null then
            call ReleaseTimer(.channelEndTim)
            set .channelEndTim = null
        endif
        call table.remove(GetHandleId(.source))
        set .targetUnit = null
        set .source = null
        set .isMoving = false
        set .followTarget = false
        set .recastInFlight = false
        set .channelCanRecast = false
        set .channelOrderId = 0
        set .channelTargetX = 0.
        set .channelTargetY = 0.
        call .deallocate()
    endmethod
    
    //=======================================================================
    // Inicialización estática
    //=======================================================================
    private static method onInit takes nothing returns nothing
        set table = Table.create()
    endmethod
endstruct

//===========================================================================
// API - Funciones públicas para registrar hechizos
//===========================================================================

//===========================================================================
// Registrar hechizo con OrderId string
//===========================================================================
function RegisterMovementSpell takes integer abilityId, string orderId returns nothing
    local integer orderIdInt = OrderId(orderId)
    
    set registeredSpells[orderIdInt] = abilityId
    set abilityOrderSpells[abilityId] = orderIdInt
    set targetOrderSpells.boolean[orderIdInt] = false  // orden point
    set recastOrderSpells.boolean[orderIdInt] = false  // recast desactivado por defecto
    
    static if DEBUG_MODE then
        call BJDebugMsg("[MovementSystem] Registered ability: " + I2S(abilityId) + " with order: " + orderId)
    endif
endfunction

//===========================================================================
// Registrar hechizo TARGET con OrderId string
//===========================================================================
function RegisterMovementSpellTarget takes integer abilityId, string orderId returns nothing
    local integer orderIdInt = OrderId(orderId)
    
    set registeredSpells[orderIdInt] = abilityId
    set abilityOrderSpells[abilityId] = orderIdInt
    set targetOrderSpells.boolean[orderIdInt] = true  // orden target
    set recastOrderSpells.boolean[orderIdInt] = false // recast desactivado por defecto
    
    static if DEBUG_MODE then
        call BJDebugMsg("[MovementSystem] Registered TARGET ability: " + I2S(abilityId) + " with order: " + orderId)
    endif
endfunction

//===========================================================================
// Eventos del sistema
//===========================================================================

private function IsIgnoredUnit takes unit u returns boolean
    return GetUnitAbilityLevel(u, IGNORE_BUFF_ID) > 0
endfunction

private function IsRecastOrder takes integer orderId returns boolean
    return recastOrderSpells.boolean[orderId]
endfunction

//===========================================================================
// Registrar hechizo con recast habilitado (POINT ORDER)
//===========================================================================
function RegisterMovementSpellRecast takes integer abilityId, string orderId returns nothing
    local integer orderIdInt = OrderId(orderId)
    call RegisterMovementSpell(abilityId, orderId)
    set recastOrderSpells.boolean[orderIdInt] = true
endfunction

//===========================================================================
// Registrar hechizo TARGET con recast habilitado (TARGET ORDER)
//===========================================================================
function RegisterMovementSpellTargetRecast takes integer abilityId, string orderId returns nothing
    local integer orderIdInt = OrderId(orderId)
    call RegisterMovementSpellTarget(abilityId, orderId)
    set recastOrderSpells.boolean[orderIdInt] = true
endfunction

//===========================================================================
// Evento: Orden de movimiento
//===========================================================================
private function OnMoveOrder takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    local real x
    local real y
    local boolean hasChannel
    local boolean canRedirect
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        return false// Ignora este evento
    endif
    
    if orderId == ORDER_ID_MOVE or orderId == ORDER_ID_SMART then
        set x = GetOrderPointX()
        set y = GetOrderPointY()

        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif
        set hasChannel = (data.channelOrderId != 0)
        set canRedirect = hasChannel and data.channelCanRecast
        static if LIBRARY_PlayerMissileLoadout then
            if canRedirect then
                set canRedirect = GetPlayerMissileUseSmartRecast(GetOwningPlayer(u))
            endif
        endif

        // Si el order smart estÃ¡ registrado para spells, igual permitimos
        // redirecciÃ³n cuando hay un channel track activo.
        if (orderId == ORDER_ID_MOVE) or (not registeredSpells.has(orderId)) or hasChannel then
            // During channel, redirect movement only when recast is enabled for this player.
            if (not hasChannel) or canRedirect then
                call data.resetMovement(x, y)
                if hasChannel and (not data.hasDummy) then
                    call data.startDummyMovement()
                endif
                if hasChannel then
                    call data.tryRecastTrackedChannel()
                endif
            elseif hasChannel then
                call data.queueMovementDuringCast(x, y)
            endif
        endif
        
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Move order to (" + R2S(x) + ", " + R2S(y) + ")")
        endif
    endif
    
    set u = null
    return false
endfunction

//===========================================================================
// Evento: Orden de hechizo (POINT ORDER)
//===========================================================================
private function OnSpellOrderPoint takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    local real x
    local real y
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        return false// Ignora este evento
    endif
    
    // Verificar si es un hechizo registrado
    if registeredSpells.has(orderId) and not targetOrderSpells.boolean[orderId] then
        set x = GetOrderPointX()
        set y = GetOrderPointY()
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Registered spell ORDER (point) detected: " + I2S(orderId))
        endif

        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif
        static if LIBRARY_IsUnitChanneling then
            if IsUnitChanneling(u) and ((orderId != ORDER_ID_SMART) or (data.channelOrderId == 0)) then
                call data.beginChannelTracking(orderId, x, y, IsRecastOrder(orderId))
            endif
        else
            if (orderId != ORDER_ID_SMART) or (data.channelOrderId == 0) then
                call data.beginChannelTracking(orderId, x, y, IsRecastOrder(orderId))
            endif
        endif
        if not ((orderId == ORDER_ID_SMART) and (data.channelOrderId == 0)) then
            call data.onSpellOrder()
        endif
    endif
    
    set u = null
    return false
endfunction

//===========================================================================
// Evento: Orden de hechizo (TARGET ORDER)
//===========================================================================
private function OnSpellOrderTarget takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local unit targetU = GetOrderTargetUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    local boolean hasChannel
    local boolean canRedirect
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        set targetU = null
        return false// Ignora este evento
    endif

    // Smart-target de movimiento normal (seguir target con el dummy).
    if (orderId == ORDER_ID_SMART) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif
        set hasChannel = (data.channelOrderId != 0)
        set canRedirect = hasChannel and data.channelCanRecast
        static if LIBRARY_PlayerMissileLoadout then
            if canRedirect then
                set canRedirect = GetPlayerMissileUseSmartRecast(GetOwningPlayer(u))
            endif
        endif

        if (not registeredSpells.has(orderId)) or hasChannel then
            // During channel, redirect movement only when recast is enabled for this player.
            if (not hasChannel) or canRedirect then
                call data.resetMovementTarget(targetU)
                if hasChannel and (not data.hasDummy) then
                    call data.startDummyMovement()
                endif
                if hasChannel then
                    call data.tryRecastTrackedChannel()
                endif
            elseif hasChannel then
                call data.queueMovementTargetDuringCast(targetU)
            endif
        endif
    endif
    
    // Verificar si es un hechizo registrado
    if registeredSpells.has(orderId) and targetOrderSpells.boolean[orderId] then
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Registered spell ORDER (target) detected: " + I2S(orderId))
        endif

        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif
        static if LIBRARY_IsUnitChanneling then
            if IsUnitChanneling(u) and ((orderId != ORDER_ID_SMART) or (data.channelOrderId == 0)) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
                call data.beginChannelTracking(orderId, GetUnitX(targetU), GetUnitY(targetU), IsRecastOrder(orderId))
            endif
        else
            if ((orderId != ORDER_ID_SMART) or (data.channelOrderId == 0)) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
                call data.beginChannelTracking(orderId, GetUnitX(targetU), GetUnitY(targetU), IsRecastOrder(orderId))
            endif
        endif
        if not ((orderId == ORDER_ID_SMART) and (data.channelOrderId == 0)) then
            call data.onSpellOrder()
        endif
    endif
    
    set u = null
    set targetU = null
    return false
endfunction

//===========================================================================
// Evento: Efecto de hechizo (para verificar channeling)
//===========================================================================
private function OnSpellEffect takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local MovementData data
    local integer abilId = GetSpellAbilityId()
    local integer orderId
    local real tx
    local real ty
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        return false// Ignora este evento
    endif

    if abilId == 'AM01' or abilId == 'AM02' or abilId == 'AM03' or abilId == 'AM04' or abilId == 'AM05' or abilId == 'AM06' then
        set u = null
        return false // Ignora este evento
    endif
    
    if abilityOrderSpells.has(abilId) and (not MovementData.has(u)) then
        set data = MovementData.create(u)
    endif

    if MovementData.has(u) then
        set data = MovementData.get(u)
        if abilityOrderSpells.has(abilId) then
            set orderId = abilityOrderSpells[abilId]
            static if LIBRARY_IsUnitChanneling then
                if IsUnitChanneling(u) then
                    set tx = GetSpellTargetX()
                    set ty = GetSpellTargetY()
                    call data.beginChannelTracking(orderId, tx, ty, IsRecastOrder(orderId))
                else
                    call data.endChannelTracking()
                endif
            else
                call data.endChannelTracking()
            endif
        endif
        call data.onSpellEffect()
    endif
    
    set u = null
    return false
endfunction

//===========================================================================
// Evento: Fin de hechizo
//===========================================================================
private function OnSpellEndCast takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local MovementData data
    local integer abilId = GetSpellAbilityId()
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        return false// Ignora este evento
    endif

    if abilId == 'AM01' or abilId == 'AM02' or abilId == 'AM03' or abilId == 'AM04' or abilId == 'AM05' or abilId == 'AM06' then
        set u = null
        return false// Ignora este evento
    endif
    
    if MovementData.has(u) then
        set data = MovementData.get(u)
        if abilityOrderSpells.has(abilId) then
            if abilityOrderSpells[abilId] == data.channelOrderId then
                if data.channelCanRecast then
                    if data.recastInFlight then
                        static if DEBUG_MODE then
                            call BJDebugMsg("[MovementSystem] ENDCAST ignored (internal recast)")
                        endif
                        set u = null
                        return false
                    endif
                    // ENDCAST can fire before smart retarget order is processed.
                    // Delay final cleanup a bit; smart-cast path will cancel this.
                    static if DEBUG_MODE then
                        call BJDebugMsg("[MovementSystem] ENDCAST delayed finalize for tracked channel")
                    endif
                    call data.scheduleChannelEndFinalize()
                    set u = null
                    return false
                endif
            endif
            call data.endChannelTracking()
        endif
        call data.onSpellEnd()
    endif
    
    set u = null
    return false
endfunction

//===========================================================================
// Evento: Orden de detener
//===========================================================================
private function OnStopOrder takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        return false// Ignora este evento
    endif
    
    if orderId == ORDER_ID_STOP or orderId == ORDER_ID_HOLD_POSITION then // stop, holdposition
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
    endif
    
    set u = null
    return false
endfunction

//===========================================================================
// Evento: Muerte
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
// Inicialización
//===========================================================================
private function Init takes nothing returns nothing
    // Inicializar tablas
    set registeredSpells = Table.create()
    set targetOrderSpells = Table.create()
    set abilityOrderSpells = Table.create()
    set recastOrderSpells = Table.create()
    set ORDER_ID_MOVE = OrderId("move")
    set ORDER_ID_SMART = OrderId("smart")
    set ORDER_ID_STOP = OrderId("stop")
    set ORDER_ID_HOLD_POSITION = OrderId("holdposition")
    
    // Registrar eventos
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnMoveOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnSpellOrderPoint)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnSpellOrderTarget)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function OnSpellEffect)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_ENDCAST, function OnSpellEndCast)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnStopOrder)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnUnitDeath)
    
    static if DEBUG_MODE then
        call BJDebugMsg("[MovementSystem] v3.0 Initialized")
        call BJDebugMsg("[MovementSystem] Use RegisterMovementSpell(abilId, 'orderId') to register")
    endif
endfunction

endlibrary
