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
library MovementSystem initializer Init requires TimerUtils, Table, RegisterPlayerUnitEvent, optional IsUnitChanneling

globals
    // Configuración
    private constant real INTERVAL = 0.03125              
    private constant real ARRIVAL_THRESHOLD = 50.0    
    private constant integer DUMMY_UNIT_ID = 'h003'   // CAMBIAR
    
    // Comportamiento
    private constant boolean INSTANT_CASTS_USE_DUMMY = true  
    
    // Debug
    private constant boolean DEBUG_MODE = false
    
    // Tabla de habilidades registradas: OrderId -> AbilityId
    private Table registeredSpells
    
    // Tabla de OrderId -> Boolean (para órdenes target)
    private Table targetOrderSpells
endglobals

//===========================================================================
// Struct principal
//===========================================================================
struct MovementData
    unit source          
    unit dummy           
    real targetX         
    real targetY         
    timer tim            
    boolean isMoving     
    boolean hasDummy     
    
    private static Table table
    
    //=======================================================================
    // Constructor
    //=======================================================================
    static method create takes unit u returns thistype
        local thistype this = thistype.allocate()
        
        set .source = u
        set .dummy = null
        set .targetX = 0
        set .targetY = 0
        set .tim = null
        set .isMoving = false
        set .hasDummy = false
        
        set table[GetHandleId(u)] = this
        
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Created for: " + GetUnitName(u))
        endif
        
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
    private method getDistance takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        return SquareRoot(dx * dx + dy * dy)
    endmethod
    
    //=======================================================================
    // Callback periódico del timer
    //=======================================================================
    private static method periodic takes nothing returns nothing
        local thistype this = GetTimerData(GetExpiredTimer())
        local real dummyX
        local real dummyY
        local real dist
        
        if .dummy != null and GetUnitTypeId(.dummy) != 0 then
            set dummyX = GetUnitX(.dummy)
            set dummyY = GetUnitY(.dummy)
            set dist = .getDistance(dummyX, dummyY, .targetX, .targetY)
            
            // Teleportar la unidad al dummy
            call SetUnitX(.source, dummyX)
            call SetUnitY(.source, dummyY)
            
            // Verificar llegada
            if dist < ARRIVAL_THRESHOLD then
                static if DEBUG_MODE then
                    call BJDebugMsg("[MovementSystem] Arrived at destination")
                endif
                
                if (IsTerrainWalkable(dummyX, dummyY)) then
                else
                    call SetUnitX(.source, TerrainPathability_X)
                    call SetUnitY(.source, TerrainPathability_Y)
                endif

                call .stopDummyMovement()
            endif
        else
            call .stopDummyMovement()
        endif
    endmethod
    
    //=======================================================================
    // Iniciar movimiento con dummy
    //=======================================================================
    method startDummyMovement takes nothing returns nothing
        local real unitX
        local real unitY
        local real angle
        
        if .hasDummy then
            return
        endif
        
        set unitX = GetUnitX(.source)
        set unitY = GetUnitY(.source)

        // Crear dummy
        set .dummy = CreateUnit(GetOwningPlayer(.source), DUMMY_UNIT_ID, unitX, unitY, 0)
        
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
        // Mover dummy al destino
        call IssuePointOrder(.dummy, "move", .targetX, .targetY)
        
        set .hasDummy = true
        
        // Timer para copiar posición
        set .tim = NewTimerEx(this)
        call TimerStart(.tim, INTERVAL, true, function thistype.periodic)
        
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Dummy created - continuing trajectory")
        endif
    endmethod
    
    //=======================================================================
    // Detener movimiento con dummy
    //=======================================================================
    method stopDummyMovement takes nothing returns nothing
        if .tim != null then
            call ReleaseTimer(.tim)
            set .tim = null
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
            call IssuePointOrder(.source, "move", .targetX, .targetY)
            
            static if DEBUG_MODE then
                call BJDebugMsg("[MovementSystem] Movement restored")
            endif
        endif
    endmethod
    
    //=======================================================================
    // Reiniciar movimiento
    //=======================================================================
    method resetMovement takes real x, real y returns nothing
        call .stopDummyMovement()
        set .targetX = x
        set .targetY = y
        set .isMoving = true
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
        endif
    endmethod
    
    //=======================================================================
    // Procesar efecto de hechizo (para verificar channeling)
    //=======================================================================
    method onSpellEffect takes nothing returns nothing
        // Si no es channeling y no queremos dummy para instantáneos
        static if LIBRARY_IsUnitChanneling then
            if not IsUnitChanneling(.source) and not INSTANT_CASTS_USE_DUMMY then
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
        call .stopDummyMovement()
        set table[GetHandleId(.source)] = 0
        set .source = null
        set .isMoving = false
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
    set targetOrderSpells.boolean[orderIdInt] = false  // orden point
    
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
    set targetOrderSpells.boolean[orderIdInt] = true  // orden target
    
    static if DEBUG_MODE then
        call BJDebugMsg("[MovementSystem] Registered TARGET ability: " + I2S(abilityId) + " with order: " + orderId)
    endif
endfunction

//===========================================================================
// Eventos del sistema
//===========================================================================

//===========================================================================
// Evento: Orden de movimiento
//===========================================================================
private function OnMoveOrder takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    local real x
    local real y
    
    if orderId == 851986 or orderId == 851971 then // "move"
        set x = GetOrderPointX()
        set y = GetOrderPointY()
        
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.resetMovement(x, y)
        else
            set data = MovementData.create(u)
            set data.targetX = x
            set data.targetY = y
            set data.isMoving = true
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
    
    // Verificar si es un hechizo registrado
    if registeredSpells.has(orderId) and not targetOrderSpells.boolean[orderId] then
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Registered spell ORDER (point) detected: " + I2S(orderId))
        endif
        
        if MovementData.has(u) then
            set data = MovementData.get(u)
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
    local integer orderId = GetIssuedOrderId()
    local MovementData data
    
    // Verificar si es un hechizo registrado
    if registeredSpells.has(orderId) and targetOrderSpells.boolean[orderId] then
        static if DEBUG_MODE then
            call BJDebugMsg("[MovementSystem] Registered spell ORDER (target) detected: " + I2S(orderId))
        endif
        
        if MovementData.has(u) then
            set data = MovementData.get(u)
            call data.onSpellOrder()
        endif
    endif
    
    set u = null
    return false
endfunction

//===========================================================================
// Evento: Efecto de hechizo (para verificar channeling)
//===========================================================================
private function OnSpellEffect takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local MovementData data
    
    if MovementData.has(u) then
        set data = MovementData.get(u)
        if data.hasDummy then
            call data.onSpellEffect()
        endif
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
    
    if MovementData.has(u) then
        set data = MovementData.get(u)
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
    
    if orderId == 851972 or orderId == 851973 then // stop, holdposition
        if MovementData.has(u) then
            set data = MovementData.get(u)
            set data.isMoving = false
            call data.stopDummyMovement()
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
