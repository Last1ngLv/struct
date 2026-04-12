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
//  - PlayerMissileLoadout (opcional, para respetar el toggle del jugador)
//
//===========================================================================
library MovementSystem initializer Init requires TimerUtils, Table, RegisterPlayerUnitEvent, optional PlayerMissileLoadout

globals
    // Configuración
    private constant real INTERVAL = 0.03125
    private constant real ARRIVAL_THRESHOLD = 50.0
    private constant real ARRIVAL_THRESHOLD_SQ = ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD
    private constant real DATA_IDLE_TIMEOUT = 10.0
    private constant real DEFAULT_SESSION_END_GRACE = 0.20
    private constant integer DUMMY_UNIT_ID = 'h003'   // CAMBIAR
    private constant integer IGNORE_BUFF_ID = 'BB01'
    
    // Debug
    private constant boolean DEBUG_MODE = false

    // MoveCast texttag
    private constant real MOVECAST_TEXT_SIZE = 0.020
    private constant real MOVECAST_TEXT_Z = 110.0
    private constant real MOVECAST_TEXT_LIFE = 1.00
    private constant real MOVECAST_TEXT_FADE = 0.50
    private constant real MOVECAST_TEXT_VY = 0.035
    private constant integer MOVECAST_TEXT_R = 60
    private constant integer MOVECAST_TEXT_G = 255
    private constant integer MOVECAST_TEXT_B = 60
    
    // Tabla de habilidades registradas: OrderId -> AbilityId
    private Table registeredSpells
    // Tabla inversa: AbilityId -> OrderId
    private Table abilityOrderSpells
    
    // Tabla de OrderId -> Boolean (para órdenes target)
    private Table targetOrderSpells
    // Tabla de OrderId -> Boolean (habilita recast explícito)
    private Table recastOrderSpells
    // Config personalizada de sesi?n por habilidad
    private Table castDurationByAbility
    private Table smartRecastEnabledByAbility
    private Table smartRecastCountByAbility

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
    timer castSessionTim
    boolean isMoving     
    boolean hasDummy     
    boolean followTarget
    boolean channelCanRecast
    integer channelOrderId
    real channelTargetX
    real channelTargetY
    unit castTargetUnit
    boolean castTargetIsUnit
    integer castAbilityId
    real castDuration
    real castTimeRemaining
    integer smartRecastsRemaining
    integer smartRecastsMax
    texttag castTextTag
    boolean suppressNextStopOrder
    
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
        set .castSessionTim = null
        set .isMoving = false
        set .hasDummy = false
        set .followTarget = false
        set .channelCanRecast = false
        set .channelOrderId = 0
        set .channelTargetX = 0.
        set .channelTargetY = 0.
        set .castTargetUnit = null
        set .castTargetIsUnit = false
        set .castAbilityId = 0
        set .castDuration = 0.
        set .castTimeRemaining = 0.
        set .smartRecastsRemaining = 0
        set .smartRecastsMax = 0
        set .castTextTag = null
        set .suppressNextStopOrder = false
        
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
    private method hasCastSession takes nothing returns boolean
        return .channelOrderId != 0
    endmethod

    //=======================================================================
    method hasTimedCastSession takes nothing returns boolean
        return (.channelOrderId != 0) and (.castDuration > 0.) and (.castTimeRemaining > 0.)
    endmethod

    //=======================================================================
    method canUseSmartRecast takes nothing returns boolean
        if not .hasCastSession() then
            return false
        endif
        if not .channelCanRecast then
            return false
        endif
        if .smartRecastsRemaining <= 0 then
            return false
        endif
        static if LIBRARY_PlayerMissileLoadout then
            if not GetPlayerMissileUseSmartRecast(GetOwningPlayer(.source)) then
                return false
            endif
        endif
        return true
    endmethod

    //=======================================================================
    private method updateTrackedCastTarget takes nothing returns nothing
        if .castTargetIsUnit then
            if (.castTargetUnit != null) and (GetUnitTypeId(.castTargetUnit) != 0) and UnitAlive(.castTargetUnit) then
                set .channelTargetX = GetUnitX(.castTargetUnit)
                set .channelTargetY = GetUnitY(.castTargetUnit)
            else
                set .castTargetUnit = null
                set .castTargetIsUnit = false
            endif
        endif
    endmethod

    //=======================================================================
    private method syncCastTextTagPosition takes nothing returns nothing
        if (.castTextTag != null) and (.source != null) and (GetUnitTypeId(.source) != 0) then
            call SetTextTagPos(.castTextTag, GetUnitX(.source), GetUnitY(.source), MOVECAST_TEXT_Z)
        endif
    endmethod

    //=======================================================================
    private method refreshCastTextTag takes nothing returns nothing
        local string msg
        if .smartRecastsMax <= 0 then
            if .castTextTag != null then
                call DestroyTextTag(.castTextTag)
                set .castTextTag = null
            endif
            return
        endif
        if (.source == null) or (GetUnitTypeId(.source) == 0) then
            return
        endif
        if .castTextTag == null then
            set .castTextTag = CreateTextTag()
            call SetTextTagPermanent(.castTextTag, true)
            call SetTextTagVisibility(.castTextTag, true)
        endif
        set msg = "MoveCast: " + I2S(.smartRecastsRemaining)
        call SetTextTagText(.castTextTag, msg, MOVECAST_TEXT_SIZE)
        call SetTextTagColor(.castTextTag, MOVECAST_TEXT_R, MOVECAST_TEXT_G, MOVECAST_TEXT_B, 255)
        call .syncCastTextTagPosition()
        call SetTextTagVelocity(.castTextTag, 0.0, 0.0)
        call SetTextTagPermanent(.castTextTag, true)
        call SetTextTagLifespan(.castTextTag, 60.0)
        call SetTextTagFadepoint(.castTextTag, 60.0)
    endmethod

    //=======================================================================
    private method releaseCastTextTag takes nothing returns nothing
        if .castTextTag != null then
            call SetTextTagPermanent(.castTextTag, false)
            call SetTextTagVelocity(.castTextTag, 0.0, MOVECAST_TEXT_VY)
            call SetTextTagLifespan(.castTextTag, MOVECAST_TEXT_LIFE)
            call SetTextTagFadepoint(.castTextTag, MOVECAST_TEXT_FADE)
            set .castTextTag = null
        endif
    endmethod

    //=======================================================================
    private method destroyCastTextTag takes nothing returns nothing
        if .castTextTag != null then
            call DestroyTextTag(.castTextTag)
            set .castTextTag = null
        endif
    endmethod

    //=======================================================================
    private method updateCastFacing takes nothing returns nothing
        local real sx
        local real sy
        call .updateTrackedCastTarget()
        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            return
        endif
        if .channelOrderId == 0 then
            return
        endif
        set sx = GetUnitX(.source)
        set sy = GetUnitY(.source)
        if .getDistanceSquared(sx, sy, .channelTargetX, .channelTargetY) > 1.0 then
            call SetUnitFacing(.source, Atan2(.channelTargetY - sy, .channelTargetX - sx) * bj_RADTODEG)
        endif
    endmethod

    //=======================================================================
    private static method onCastSessionTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local thistype this = GetTimerData(t)
        if this == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif
        if .castSessionTim != t then
            call ReleaseTimer(t)
            set t = null
            return
        endif
        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            set .castSessionTim = null
            call ReleaseTimer(t)
            set t = null
            call .destroy()
            return
        endif
        call .updateTrackedCastTarget()
        if .hasDummy then
            call .updateCastFacing()
        endif
        call .refreshCastTextTag()
        if .castDuration <= 0. then
            set t = null
            return
        endif
        set .castTimeRemaining = .castTimeRemaining - INTERVAL
        if .castTimeRemaining <= 0. then
            set .castSessionTim = null
            call ReleaseTimer(t)
            set t = null
            call .endCastSession(true)
            return
        endif
        set t = null
    endmethod

    //=======================================================================
    method beginCastSession takes integer abilityId, integer orderId, real tx, real ty, unit targetU returns nothing
        local real duration = 0.
        local integer maxRecasts = 0
        local boolean resetCharges = (.channelOrderId == 0) or (.castAbilityId != abilityId) or (.channelOrderId != orderId)

        if castDurationByAbility.has(abilityId) then
            set duration = castDurationByAbility.real[abilityId]
        endif
        if smartRecastCountByAbility.has(abilityId) then
            set maxRecasts = smartRecastCountByAbility[abilityId]
        endif

        set .castAbilityId = abilityId
        set .channelOrderId = orderId
        set .castDuration = duration
        set .castTimeRemaining = duration
        set .castTargetUnit = targetU
        set .castTargetIsUnit = (targetU != null) and targetOrderSpells.boolean[orderId]
        if .castTargetIsUnit then
            set .channelTargetX = GetUnitX(targetU)
            set .channelTargetY = GetUnitY(targetU)
        else
            set .channelTargetX = tx
            set .channelTargetY = ty
        endif

        if smartRecastEnabledByAbility.boolean[abilityId] and (maxRecasts > 0) then
            set .channelCanRecast = true
            if resetCharges then
                set .smartRecastsMax = maxRecasts
                set .smartRecastsRemaining = maxRecasts
            endif
        else
            set .channelCanRecast = false
            set .smartRecastsMax = 0
            set .smartRecastsRemaining = 0
        endif

        if duration > 0. then
            if .castSessionTim == null then
                set .castSessionTim = NewTimerEx(this)
                call TimerStart(.castSessionTim, INTERVAL, true, function thistype.onCastSessionTick)
            endif
        elseif .castSessionTim != null then
            call ReleaseTimer(.castSessionTim)
            set .castSessionTim = null
        endif

        call .refreshCastTextTag()
    endmethod

    //=======================================================================
    method endCastSession takes boolean restoreMovement returns nothing
        local boolean hadDummy = .hasDummy
        if .castSessionTim != null then
            call ReleaseTimer(.castSessionTim)
            set .castSessionTim = null
        endif
        call .releaseCastTextTag()
        set .castAbilityId = 0
        set .castDuration = 0.
        set .castTimeRemaining = 0.
        set .castTargetUnit = null
        set .castTargetIsUnit = false
        set .smartRecastsRemaining = 0
        set .smartRecastsMax = 0
        set .channelOrderId = 0
        set .channelTargetX = 0.
        set .channelTargetY = 0.
        set .channelCanRecast = false
        if restoreMovement and hadDummy then
            call .restoreNormalMovement()
        endif
    endmethod

    //=======================================================================
    method consumeSmartRecast takes nothing returns nothing
        if .smartRecastsRemaining <= 0 then
            return
        endif
        set .smartRecastsRemaining = .smartRecastsRemaining - 1
        call .refreshCastTextTag()
        if .smartRecastsRemaining <= 0 then
            call .endCastSession(true)
        endif
    endmethod

    //=======================================================================
    method beginChannelTracking takes integer orderId, real tx, real ty, boolean canRecast returns nothing
        local integer abilityId = 0
        if registeredSpells.has(orderId) then
            set abilityId = registeredSpells[orderId]
        endif
        if abilityId == 0 then
            return
        endif
        call .beginCastSession(abilityId, orderId, tx, ty, null)
        if not canRecast then
            set .channelCanRecast = false
            set .smartRecastsRemaining = 0
            set .smartRecastsMax = 0
            call .releaseCastTextTag()
        endif
    endmethod

    //=======================================================================
    method endChannelTracking takes nothing returns nothing
        call .endCastSession(false)
    endmethod

    //=======================================================================
    method tryRecastTrackedChannel takes nothing returns nothing
        // Legacy no-op: smart recast ya no re-lanza la habilidad registrada.
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
    private method isFlyingDummy takes nothing returns boolean
        return (.dummy != null) and (GetUnitTypeId(.dummy) != 0) and IsUnitType(.dummy, UNIT_TYPE_FLYING)
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
            call .syncCastTextTagPosition()

            if not IsTerrainWalkable(dummyX, dummyY) then
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Dummy reached non-walkable terrain - stopping")
                endif
                set .isMoving = false
                set .targetUnit = null
                set .followTarget = false
                call .stopDummyMovement()
                call .destroy()
                return
            endif
            
            // Verificar llegada
            if (not .followTarget) and (distSq < ARRIVAL_THRESHOLD_SQ) then
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Arrived at destination")
                endif

                if not IsTerrainWalkable(dummyX, dummyY) then
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
        if .isFlyingDummy() then
            call SetUnitPathing(.dummy, false)
        endif
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
    method absorbSmartRecast takes nothing returns nothing
        if (.source == null) or (GetUnitTypeId(.source) == 0) or (not UnitAlive(.source)) then
            return
        endif
        set .suppressNextStopOrder = true
        call IssueImmediateOrderById(.source, ORDER_ID_STOP)
        call .updateCastFacing()
        call .syncCastTextTagPosition()
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
        if (.channelOrderId != 0) and .isMoving and (not .hasDummy) then
            call .startDummyMovement()
            call .armIdleCleanup()
        endif
    endmethod
    
    //=======================================================================
    // Procesar fin de cast
    //=======================================================================
    method onSpellEnd takes nothing returns nothing
        if .channelOrderId != 0 then
            call .endCastSession(true)
        elseif .hasDummy then
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
        if .castSessionTim != null then
            call ReleaseTimer(.castSessionTim)
            set .castSessionTim = null
        endif
        call .releaseCastTextTag()
        call .stopDummyMovement()
        if .gcTim != null then
            call ReleaseTimer(.gcTim)
            set .gcTim = null
        endif
        call table.remove(GetHandleId(.source))
        set .targetUnit = null
        set .source = null
        set .isMoving = false
        set .followTarget = false
        set .channelCanRecast = false
        set .channelOrderId = 0
        set .channelTargetX = 0.
        set .channelTargetY = 0.
        set .castTargetUnit = null
        set .castTargetIsUnit = false
        set .castAbilityId = 0
        set .castDuration = 0.
        set .castTimeRemaining = 0.
        set .smartRecastsRemaining = 0
        set .smartRecastsMax = 0
        set .suppressNextStopOrder = false
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

function ConfigureMovementSpellCastSession takes integer abilityId, real castDuration, boolean allowSmartRecast, integer maxSmartRecasts returns nothing
    if abilityId == 0 then
        return
    endif
    if castDuration < 0. then
        set castDuration = 0.
    endif
    if maxSmartRecasts < 0 then
        set maxSmartRecasts = 0
    endif
    set castDurationByAbility.real[abilityId] = castDuration
    set smartRecastEnabledByAbility.boolean[abilityId] = allowSmartRecast
    if allowSmartRecast then
        set smartRecastCountByAbility[abilityId] = maxSmartRecasts
    else
        set smartRecastCountByAbility[abilityId] = 0
    endif
endfunction

//===========================================================================
// Registrar hechizo con recast habilitado (POINT ORDER)
//===========================================================================
function RegisterMovementSpellRecast takes integer abilityId, string orderId returns nothing
    local integer orderIdInt = OrderId(orderId)
    call RegisterMovementSpell(abilityId, orderId)
    set recastOrderSpells.boolean[orderIdInt] = true
    call ConfigureMovementSpellCastSession(abilityId, 0., true, 1)
endfunction

//===========================================================================
// Registrar hechizo TARGET con recast habilitado (TARGET ORDER)
//===========================================================================
function RegisterMovementSpellTargetRecast takes integer abilityId, string orderId returns nothing
    local integer orderIdInt = OrderId(orderId)
    call RegisterMovementSpellTarget(abilityId, orderId)
    set recastOrderSpells.boolean[orderIdInt] = true
    call ConfigureMovementSpellCastSession(abilityId, 0., true, 1)
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
    local boolean hasSession
    
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
        set hasSession = (data.channelOrderId != 0)

        if (orderId == ORDER_ID_MOVE) or (not registeredSpells.has(orderId)) or hasSession then
            if hasSession then
                if data.canUseSmartRecast() then
                    call data.absorbSmartRecast()
                    call data.consumeSmartRecast()
                else
                    call data.queueMovementDuringCast(x, y)
                endif
            else
                call data.resetMovement(x, y)
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
    local integer abilityId
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
    
    if registeredSpells.has(orderId) and not targetOrderSpells.boolean[orderId] then
        set x = GetOrderPointX()
        set y = GetOrderPointY()
        set abilityId = registeredSpells[orderId]
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Registered spell ORDER (point) detected: " + I2S(orderId))
        endif

        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif

        call data.beginCastSession(abilityId, orderId, x, y, null)
        call data.onSpellOrder()
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
    local integer abilityId
    local MovementData data
    local boolean hasSession
    
    if IsIgnoredUnit(u) then
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.destroy()
        endif
        set u = null
        set targetU = null
        return false// Ignora este evento
    endif

    if (orderId == ORDER_ID_SMART) and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif
        set hasSession = (data.channelOrderId != 0)

        if (not registeredSpells.has(orderId)) or hasSession then
            if hasSession then
                if data.canUseSmartRecast() then
                    call data.absorbSmartRecast()
                    call data.consumeSmartRecast()
                else
                    call data.queueMovementTargetDuringCast(targetU)
                endif
            else
                call data.resetMovementTarget(targetU)
            endif
        endif
    endif
    
    if registeredSpells.has(orderId) and targetOrderSpells.boolean[orderId] and (targetU != null) and (GetUnitTypeId(targetU) != 0) then
        set abilityId = registeredSpells[orderId]
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Registered spell ORDER (target) detected: " + I2S(orderId))
        endif

        if not MovementData.has(u) then
            set data = MovementData.create(u)
        else
            set data = MovementData.get(u)
        endif

        call data.beginCastSession(abilityId, orderId, GetUnitX(targetU), GetUnitY(targetU), targetU)
        call data.onSpellOrder()
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
    local unit targetU = null
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
            set tx = GetSpellTargetX()
            set ty = GetSpellTargetY()
            set targetU = GetSpellTargetUnit()
            if (targetU != null) and (GetUnitTypeId(targetU) != 0) then
                set tx = GetUnitX(targetU)
                set ty = GetUnitY(targetU)
            else
                set targetU = null
            endif
            call data.beginCastSession(abilId, orderId, tx, ty, targetU)
        endif
        call data.onSpellEffect()
    endif
    
    set targetU = null
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
        if abilityOrderSpells.has(abilId) and (data.channelOrderId != 0) and (data.castAbilityId == abilId) then
            if data.hasTimedCastSession() then
                set u = null
                return false
            endif
            call data.endCastSession(true)
            set u = null
            return false
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
            if data.suppressNextStopOrder then
                set data.suppressNextStopOrder = false
                set u = null
                return false
            endif
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
    set castDurationByAbility = Table.create()
    set smartRecastEnabledByAbility = Table.create()
    set smartRecastCountByAbility = Table.create()
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

