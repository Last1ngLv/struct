
library WaveTest initializer Init /*

    */requires Table,/*
    */TimerUtils, TheEnd, SwlsMath 
    /*
    ==========================================================================
    WaveTest (SwlsWave) - Documentación práctica
    ==========================================================================

    IDEA GENERAL
    ------------
    Wave es una instancia independiente de spawn PvE.
    Cada Wave tiene su propio timer, slots, conteos, estado y eventos.

    FLUJO BÁSICO
    ------------
    1) set w = Wave.create(...)
    2) call w.addPoint(...) / call w.addNearUnit(...)
    3) call w.addSlot... (la variante que te convenga)
    4) call w.start()

    --------------------------------------------------------------------------
    WAVE.CREATE
    --------------------------------------------------------------------------
    Firma:
    Wave.create(
        perPlayerLimit,          // integer
        spawnNearChancePercent,  // integer 0..100
        intervalSec,             // real (ej: 0.25)
        board,                   // multiboard (null permitido)
        titleFuncName,           // string ExecuteFunc para board ("" permitido)
        waveIndex,               // integer (wave actual)
        waveTotal,               // integer (total waves)
        finishFuncName           // string callback al finalizar ("" permitido)
    )

    Parámetros:
    - perPlayerLimit:
      Límite de unidades activas por owner de slot (dentro de esa Wave).
    - spawnNearChancePercent:
      Chance de usar near units para spawnear; si falla usa points.
    - intervalSec:
      Tick interno de spawn.
    - board / titleFuncName:
      Integración opcional con multiboard.
    - waveIndex / waveTotal:
      Datos para UI/progreso.
    - finishFuncName:
      Nombre de función global a ejecutar cuando termina.

    --------------------------------------------------------------------------
    FAMILIA ADDSLOT (qué usar y cuándo)
    --------------------------------------------------------------------------
    A) Slot fijo por owner puntual (SIN escalado automático por players activos)
       addSlot(uId, amount, lim, prio, fxId, killGate, isBoss, playerOwner)
       addSlotEx(... + aiProfileId, laneId, behaviorFlags, threatWeight)

       Uso típico:
       - Boss único real (1 unidad total) en un owner específico.
       - Spawns especiales scriptados.

    B) Slots para owners default Player(8..12)
       addSlotByPlayers(...)
       addSlotByPlayersPct(...)
       addSlotExByPlayers(...)

       Estos métodos SIEMPRE crean un slot por cada owner default.
       El boolean scaleWithActivePlayers SOLO define si escala la cantidad.

    C) Slot por owner puntual con opción de escalado
       addSlotByPlayer(...)
       addSlotByPlayerPct(...)
       addSlotExByPlayer(...)

    --------------------------------------------------------------------------
    PARÁMETROS DE ADDSLOT (significado)
    --------------------------------------------------------------------------
    uId:
      Rawcode de unidad.
    amount / baseAmount:
      Cantidad base a crear desde ese slot.
    scaleWithActivePlayers (métodos ByPlayers/ByPlayer):
      true  -> escala amount según users activos y additionalPerPlayerPct.
      false -> usa baseAmount exacto.
    lim:
      Máximo de unidades activas simultáneas para ESE slot.
    prio:
      Prioridad de spawn (más alto = sale antes).
    fxId:
      Índice de FX de entrada/salida (0 = sin FX).
    killGate:
      -1 sin bloqueo; >=0 requiere totalKilled <= killGate
      (es decir: faltantes directos para terminar wave).
    isBoss:
      Marca para contadores/eventos de boss.
    playerOwner / player p:
      Owner del slot (cuando aplica por owner puntual).
    aiProfileId:
      Perfil de IA (AIProfiles).
    laneId:
      Carril/meta para lógica externa.
    behaviorFlags:
      Banderas de comportamiento IA.
    threatWeight:
      Peso de amenaza para selección de target.

    --------------------------------------------------------------------------
    EJEMPLOS CORTOS
    --------------------------------------------------------------------------
    // Miniboss escalable (owners default 8..12)
    call w.addSlotExByPlayers('nmb', 1, true, 1, 8, 2, -1, true, AI_PROFILE_MELEE, 0, 0, 1.20)

    // Boss único real (solo Player(10), sin escalado)
    call w.addSlotExByPlayer('nbs', 1, false, 1, 10, 3, -1, true, Player(10), AI_PROFILE_CASTER, 0, 0, 2.00)

    // Unit normal fija por owner puntual
    call w.addSlotExByPlayer('hfoo', 6, false, 3, 2, 1, -1, false, Player(10), AI_PROFILE_MELEE, 0, 0, 1.00)

    --------------------------------------------------------------------------
    EVENTOS Y CONTEXTO
    --------------------------------------------------------------------------
    Registro:
    RegisterWaveStartEvent / Pause / Resume / Finish / Spawn / Death / External

    Lectura de contexto:
    GetWaveEventWave(), GetWaveEventUnit(), GetWaveEventKiller(),
    GetWaveEventSlot(), GetWaveEventIsBoss(), GetWaveEventIsExternal()

    --------------------------------------------------------------------------
    NOTA CLAVE PARA BOSS VS MINIBOSS
    --------------------------------------------------------------------------
    - Boss único real:
      usar addSlotExByPlayer(..., false, ..., Player(x), ...)
    - Miniboss escalable:
      usar addSlotExByPlayers(..., true, ...)
    */

    globals
        constant boolean WAVE_DEBUG_ENABLED = false
        constant string WAVE_DEBUG_PREFIX = "[WaveDebug]"

        Table WaveByUnit
        Table WaveByTimer
        Table SlotByUnit
        Table WaveByBoard
        Table ExternalIsBoss
        Table WaveActiveUnitByKey
        Table WaveActivePosByUnit
        Table WaveAffiliateWaveByUnit
        Table WaveAffiliateModeByUnit
        Table WaveExternalOwnerPidByUnit
        Table WaveExternalSpawnFxByUnit

        constant integer WAVE_MAX_SLOTS = 100
        constant integer WAVE_MAX_POINTS = 100
        constant integer WAVE_MAX_NEAR_UNITS = 100
        constant integer WAVE_TRACKED_PLAYER_SLOTS = 20
        constant integer WAVE_ACTIVE_STRIDE = 4096
        constant integer WAVE_DEFAULT_OWNER_MIN = 8
        constant integer WAVE_DEFAULT_OWNER_MAX = 12

        constant integer FX_MAX = 19
        string array FX_UnitIn
        string array FX_UnitOut

        trigger WaveEvtStart
        trigger WaveEvtPause
        trigger WaveEvtResume
        trigger WaveEvtFinish
        trigger WaveEvtSpawn
        trigger WaveEvtDeath
        trigger WaveEvtExternal

        integer WaveEventWaveId = 0
        unit WaveEventUnit = null
        unit WaveEventKiller = null
        integer WaveEventSlotId = 0
        boolean WaveEventIsBoss = false
        boolean WaveEventIsExternal = false

        integer WaveTokenSeed = 0
        multiboard CurrentBoardContext
    endglobals

    private function WavePushEventContext takes integer w, unit u, unit killer, integer s, boolean isBoss, boolean isExternal returns nothing
        set WaveEventWaveId = w
        set WaveEventUnit = u
        set WaveEventKiller = killer
        set WaveEventSlotId = s
        set WaveEventIsBoss = isBoss
        set WaveEventIsExternal = isExternal
    endfunction

    private function WaveClearEventContext takes nothing returns nothing
        set WaveEventWaveId = 0
        set WaveEventUnit = null
        set WaveEventKiller = null
        set WaveEventSlotId = 0
        set WaveEventIsBoss = false
        set WaveEventIsExternal = false
    endfunction

    function WaveDebugBoolToInt takes boolean b returns integer
        if b then
            return 1
        endif
        return 0
    endfunction

    function WaveDebugUnitSummary takes unit u returns string
        local integer hid
        local integer ownerPid
        if u == null then
            return "null"
        endif
        set hid = GetHandleId(u)
        set ownerPid = GetPlayerId(GetOwningPlayer(u))
        return GetUnitName(u) + " ut=" + I2S(GetUnitTypeId(u)) + " hid=" + I2S(hid) + " ownerPid=" + I2S(ownerPid)
    endfunction

    function WaveDebugLog takes string msg returns nothing
        if WAVE_DEBUG_ENABLED then
            call BJDebugMsg(WAVE_DEBUG_PREFIX + " " + msg)
        endif
    endfunction

    function WaveDeathDebugContextSummary takes nothing returns string
        return "w=" + I2S(WaveEventWaveId) + " unit=" + WaveDebugUnitSummary(WaveEventUnit) + " killer=" + WaveDebugUnitSummary(WaveEventKiller) + " slot=" + I2S(WaveEventSlotId) + " external=" + I2S(WaveDebugBoolToInt(WaveEventIsExternal)) + " boss=" + I2S(WaveDebugBoolToInt(WaveEventIsBoss))
    endfunction

    private function WaveExecEvent takes trigger t returns nothing
        local integer waveId
        local integer slotId
        local unit eventUnit
        local unit eventKiller
        local boolean eventBoss
        local boolean eventExternal
        if t != null then
            if WAVE_DEBUG_ENABLED and t == WaveEvtDeath then
                set waveId = WaveEventWaveId
                set slotId = WaveEventSlotId
                set eventUnit = WaveEventUnit
                set eventKiller = WaveEventKiller
                set eventBoss = WaveEventIsBoss
                set eventExternal = WaveEventIsExternal
                call WaveDebugLog("WaveExecEvent enter WaveEvtDeath w=" + I2S(waveId) + " unit=" + WaveDebugUnitSummary(eventUnit) + " killer=" + WaveDebugUnitSummary(eventKiller) + " slot=" + I2S(slotId) + " external=" + I2S(WaveDebugBoolToInt(eventExternal)) + " boss=" + I2S(WaveDebugBoolToInt(eventBoss)))
            endif
            call TriggerExecute(t)
            if WAVE_DEBUG_ENABLED and t == WaveEvtDeath then
                call WaveDebugLog("WaveExecEvent exit WaveEvtDeath w=" + I2S(waveId) + " unit=" + WaveDebugUnitSummary(eventUnit) + " killer=" + WaveDebugUnitSummary(eventKiller) + " slot=" + I2S(slotId) + " external=" + I2S(WaveDebugBoolToInt(eventExternal)) + " boss=" + I2S(WaveDebugBoolToInt(eventBoss)))
            endif
            set eventUnit = null
            set eventKiller = null
        endif
    endfunction

    private function WaveFireStart takes integer w returns nothing
        call WavePushEventContext(w, null, null, 0, false, false)
        call WaveExecEvent(WaveEvtStart)
        call WaveClearEventContext()
    endfunction

    private function WaveFirePause takes integer w returns nothing
        call WavePushEventContext(w, null, null, 0, false, false)
        call WaveExecEvent(WaveEvtPause)
        call WaveClearEventContext()
    endfunction

    private function WaveFireResume takes integer w returns nothing
        call WavePushEventContext(w, null, null, 0, false, false)
        call WaveExecEvent(WaveEvtResume)
        call WaveClearEventContext()
    endfunction

    private function WaveFireFinish takes integer w returns nothing
        call WavePushEventContext(w, null, null, 0, false, false)
        call WaveExecEvent(WaveEvtFinish)
        call WaveClearEventContext()
    endfunction

    private function WaveFireSpawn takes integer w, unit u, integer s, boolean isBoss, boolean isExternal returns nothing
        call WavePushEventContext(w, u, null, s, isBoss, isExternal)
        call WaveExecEvent(WaveEvtSpawn)
        call WaveClearEventContext()
    endfunction

    private function WaveFireDeath takes integer w, unit u, unit killer, integer s, boolean isBoss, boolean isExternal returns nothing
        call WavePushEventContext(w, u, killer, s, isBoss, isExternal)
        call WaveExecEvent(WaveEvtDeath)
        call WaveClearEventContext()
    endfunction

    private function WaveFireExternal takes integer w, unit u, integer s, boolean isBoss, boolean isExternal returns nothing
        call WavePushEventContext(w, u, null, s, isBoss, isExternal)
        call WaveExecEvent(WaveEvtExternal)
        call WaveClearEventContext()
    endfunction

    private function WaveCountPlayingUsers takes nothing returns integer
        local integer i = 0
        local integer count = 0
        local player p
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set p = Player(i)
            if (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) and (GetPlayerController(p) == MAP_CONTROL_USER) then
                set count = count + 1
            endif
            set i = i + 1
        endloop
        set p = null
        if count < 1 then
            set count = 1
        endif
        return count
    endfunction

    private function WaveHandleAffiliateDeath takes integer hid returns nothing
        local Wave aw
        local integer terminateMode = 0
        if WaveAffiliateWaveByUnit.has(hid) then
            set aw = Wave(WaveAffiliateWaveByUnit[hid])
            if WaveAffiliateModeByUnit.has(hid) then
                set terminateMode = WaveAffiliateModeByUnit[hid]
            endif
            call WaveAffiliateWaveByUnit.remove(hid)
            call WaveAffiliateModeByUnit.remove(hid)
            if (aw != 0) and (not aw.isDestroyed) then
                if aw.affiliateUnitHid == hid then
                    set aw.affiliateUnitHid = 0
                    set aw.affiliateTerminateMode = 0
                endif
                call aw.terminate(terminateMode == 1)
            endif
        endif
    endfunction

    //==================================================
    // Callback del timer
    //==================================================
    function Wave_onTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer hid = GetHandleId(t)
        local Wave w

        if WaveByTimer.has(hid) then
            set w = Wave(WaveByTimer[hid])
            call w.onTick() 
        endif
        set t = null
    endfunction

    //==================================================
    // Spawn
    //==================================================
    function PendingSpawn_execute takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local PendingSpawn ps = GetTimerData(t)
            local unit u

            if (ps == 0) then
                call ReleaseTimer(t)
                set t = null
                return
            endif
            if (ps.wave == 0) or ps.wave.isDestroyed or (ps.wave.waveToken != ps.waveToken) then
                if (ps.wave != 0) and (not ps.wave.isDestroyed) and (ps.wave.waveToken != ps.waveToken) then
                    call ps.wave.cancelReservedSpawn(ps.slot, ps.pid, (not ps.wave.cancelPendingPermanently))
                    call ps.wave.tryDestroyAfterTermination()
                endif
                call ReleaseTimer(t)
                call ps.destroy()
                set t = null
                return
            endif

            set u = CreateUnit(ps.slot.owner, ps.slot.unitId, ps.x, ps.y, 270.0)
            if (u == null) or (GetUnitTypeId(u) == 0) then
                call ps.wave.cancelReservedSpawn(ps.slot, ps.pid, true)
                call ReleaseTimer(t)
                call ps.destroy()
                set t = null
                set u = null
                return
            endif
            if (ps.slot.fxId > 0) and (ps.slot.fxId <= FX_MAX) then
                call DestroyEffect(AddSpecialEffectTarget(FX_UnitOut[ps.slot.fxId], u, "origin"))
            endif

            call ps.wave.registerWaveUnit(u, ps.slot, ps.slot.isBoss, false)

            call ReleaseTimer(t)
            call ps.destroy()

            set t = null
            set u = null
    endfunction

    struct WaveSlot
        integer unitId
        integer remaining
        integer active
        integer limit
        integer priority
        integer fxId
        integer total
        boolean isBoss
        integer killGate
        player owner
        integer slotGroupId
        // Metadata IA (opcional)
        integer aiProfileId
        integer laneId
        integer behaviorFlags
        real threatWeight
    endstruct

    struct PendingSpawn
        Wave wave
        WaveSlot slot
        integer pid
        integer waveToken
        real x
        real y
        timer t
    endstruct

    struct Wave
        
        integer slotCount
        WaveSlot array slots[100]

        integer perPlayerLimit
        integer array activeByPlayer[20] 

        integer activeOnMap
        integer activeTrackedCount

        //Timer
        real interval 
        real additionalPerPlayerPct
        timer loopTimer

        integer pointCount
        real array pointX[100]
        real array pointY[100]

        // --- NUEVO: spawn cerca de unidad ---
        integer nearUnitChance   // 0â€“100
        integer nearUnitCount
        unit array nearUnits[100]

        // --- cache del punto elegido ---
        real spawnX
        real spawnY

        multiboard board
        string titleFunc

        string finishFuncName = ""

        // --- Referenciales ---
        integer waveIndex
        integer waveTotal

        // --- Totales ---
        integer totalToSpawn

        integer totalUnits
        integer totalBosses

        // --- DinÃ¡micos ---
        integer remainingToSpawn
        
        integer remainingUnits
        integer remainingBosses

        integer activeBosses
        integer activeUnits

        // Compatibilidad heredada: estos 3 campos representan "objetivos restantes".
        integer totalKilled
        integer totalKilledUnits
        integer totalKilledBoss

        // Contadores acumulados reales (IA/UI)
        integer killsDone
        integer killsDoneUnits
        integer killsDoneBoss

        boolean isRunning
        boolean isPaused
        boolean isFinishing
        boolean isDestroyed
        boolean terminateRequested
        boolean cancelPendingPermanently
        boolean suppressEndCallback
        boolean finishEventFired
        integer affiliateUnitHid
        integer affiliateTerminateMode
        integer tickCounter
        integer waveToken
        
        static method operator [] takes unit u returns thistype
            local integer hid
            if u == null then
                return 0
            endif
            set hid = GetHandleId(u)
            if WaveByUnit.has(hid) then
                return WaveByUnit[hid]
            endif
            return 0
        endmethod 

        static method create takes integer PlayerLim, integer nearChance, real sec, multiboard mb, string titleFunc, integer wIndex, integer wTotal, string onFinishFuncName returns Wave 
            local Wave this = Wave.allocate()
            local integer i = 0

            set WaveTokenSeed = WaveTokenSeed + 1
            set this.waveToken = WaveTokenSeed
            set this.isDestroyed = false
            set this.titleFunc = titleFunc
            set this.waveIndex = wIndex
            set this.waveTotal = wTotal
            set this.finishFuncName = onFinishFuncName

            if mb != null then
                set this.board = mb
                set WaveByBoard[GetHandleId(mb)] = this
            else
                set this.board = null
            endif

            set this.pointCount = 0
            if nearChance < 0 then
                set nearChance = 0
            elseif nearChance > 100 then
                set nearChance = 100
            endif
            set this.nearUnitChance = nearChance
            set this.nearUnitCount  = 0
            set this.slotCount = 0
            set this.activeOnMap = 0
            set this.activeTrackedCount = 0
            set this.perPlayerLimit = PlayerLim
            if this.perPlayerLimit < 1 then
                set this.perPlayerLimit = 1
            endif
            if sec <= 0.0 then
                set sec = 0.25
            endif
            set this.interval  = sec
            set this.additionalPerPlayerPct = 100.0

            set this.totalToSpawn      = 0
            set this.totalUnits        = 0
            set this.totalBosses       = 0

            set this.remainingToSpawn  = 0
            set this.remainingUnits    = 0
            set this.remainingBosses   = 0

            set this.activeBosses      = 0
            set this.activeUnits       = 0

            set this.totalKilled       = 0
            set this.totalKilledUnits  = 0
            set this.totalKilledBoss   = 0

            set this.killsDone      = 0
            set this.killsDoneUnits = 0
            set this.killsDoneBoss  = 0

            set this.isRunning = false
            set this.isPaused = false
            set this.isFinishing = false
            set this.terminateRequested = false
            set this.cancelPendingPermanently = false
            set this.suppressEndCallback = false
            set this.finishEventFired = false
            set this.affiliateUnitHid = 0
            set this.affiliateTerminateMode = 0
            set this.tickCounter = 0

            loop
                exitwhen i >= WAVE_TRACKED_PLAYER_SLOTS
                set this.activeByPlayer[i] = 0
                set i = i + 1
            endloop

            return this
        endmethod

        private method findSlotByGroupForOwner takes integer slotGroupId, integer uId, boolean isBoss, player p returns WaveSlot
            local integer i = 0
            local WaveSlot s

            if slotGroupId <= 0 or p == null then
                return 0
            endif

            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                if s != 0 and s.slotGroupId == slotGroupId and s.owner == p and s.unitId == uId and s.isBoss == isBoss then
                    return s
                endif
                set i = i + 1
            endloop

            return 0
        endmethod

        private method extendSlotInternal takes WaveSlot s, integer amount returns nothing
            if s == 0 or amount <= 0 then
                return
            endif

            set s.remaining = s.remaining + amount
            set s.total = s.total + amount

            set this.totalToSpawn     = this.totalToSpawn + amount
            set this.remainingToSpawn = this.remainingToSpawn + amount
            set this.totalKilled      = this.totalKilled + amount

            if s.isBoss then
                set this.totalBosses     = this.totalBosses + amount
                set this.remainingBosses = this.remainingBosses + amount
                set this.totalKilledBoss = this.totalKilledBoss + amount
            else
                set this.totalUnits      = this.totalUnits + amount
                set this.remainingUnits  = this.remainingUnits + amount
                set this.totalKilledUnits = this.totalKilledUnits + amount
            endif

            call this.clampCoreCounters()
        endmethod

        // Agregar un tipo de unidad (base interna)
        private method addSlotInternal takes integer slotGroupId, integer uId, integer amount, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing  
            local WaveSlot s

            if this.isDestroyed or this.isFinishing or this.terminateRequested then
                return
            endif

            if slotGroupId > 0 then
                set s = this.findSlotByGroupForOwner(slotGroupId, uId, isBoss, p)
                if s != 0 then
                    call this.extendSlotInternal(s, amount)
                    return
                endif
            endif

            set s = WaveSlot.create()

            if this.slotCount >= WAVE_MAX_SLOTS then
                call s.destroy()
                return
            endif
            if (uId == 0) or (amount <= 0) or (p == null) then
                call s.destroy()
                return
            endif
            if lim < 1 then
                set lim = 1
            endif
            if fxId < 0 then
                set fxId = 0
            elseif fxId > FX_MAX then
                set fxId = FX_MAX
            endif

            set s.unitId    = uId
            set s.remaining = amount
            set s.active    = 0
            set s.limit     = lim
            set s.owner     = p
            set s.priority = prio
            set s.fxId = fxId
            set s.killGate  = killGate

            set s.total     = amount
            set s.slotGroupId = slotGroupId
            
            set s.isBoss    = isBoss
            set s.aiProfileId = aiProfileId
            set s.laneId = laneId
            set s.behaviorFlags = behaviorFlags
            if threatWeight <= 0.0 then
                set threatWeight = 1.0
            endif
            set s.threatWeight = threatWeight

            set this.slots[this.slotCount] = s
            set this.slotCount = this.slotCount + 1

            // Global
            set this.totalToSpawn     = this.totalToSpawn + amount
            set this.remainingToSpawn = this.remainingToSpawn + amount

            set this.totalKilled     = this.totalKilled + amount

            if isBoss then
                // Boss
                set this.totalBosses     = this.totalBosses + amount
                set this.remainingBosses = this.remainingBosses + amount
                set this.totalKilledBoss     = this.totalKilledBoss + amount
            else
                // Unidades normales
                set this.totalUnits     = this.totalUnits + amount
                set this.remainingUnits = this.remainingUnits + amount
                set this.totalKilledUnits     = this.totalKilledUnits + amount
            endif
        endmethod

        // Agregar un tipo de unidad (compatibilidad actual)
        method addSlot takes integer uId, integer amount, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p returns nothing
            call this.addSlotInternal(0, uId, amount, lim, prio, fxId, killGate, isBoss, p, 0, 0, 0, 1.0)
        endmethod

        // VersiÃƒÂ³n extendida para IA: perfil/carril/banderas/peso
        method addSlotEx takes integer uId, integer amount, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
            call this.addSlotInternal(0, uId, amount, lim, prio, fxId, killGate, isBoss, p, aiProfileId, laneId, behaviorFlags, threatWeight)
        endmethod

        method setAdditionalPerPlayerPercent takes real pct returns nothing
            if pct < 0.0 then
                set pct = 0.0
            endif
            set this.additionalPerPlayerPct = pct
        endmethod

        method getAdditionalPerPlayerPercent takes nothing returns real
            return this.additionalPerPlayerPct
        endmethod

        method setFinishFunctionName takes string funcName returns nothing
            set this.finishFuncName = funcName
        endmethod

        method getFinishFunctionName takes nothing returns string
            return this.finishFuncName
        endmethod

        private method computeScaledAmount takes integer baseAmount, integer playersCount, real pct returns integer
            local real addPerPlayer
            local integer extraPlayers
            local integer amount
            if baseAmount <= 0 then
                return 0
            endif
            if playersCount < 1 then
                set playersCount = 1
            endif
            if pct < 0.0 then
                set pct = 0.0
            endif
            set extraPlayers = playersCount - 1
            if extraPlayers <= 0 then
                return baseAmount
            endif
            set addPerPlayer = I2R(baseAmount) * (pct * 0.01)
            set amount = baseAmount + R2I(I2R(extraPlayers) * addPerPlayer + 0.5)
            if amount < baseAmount then
                set amount = baseAmount
            endif
            return amount
        endmethod

        private method addSlotScaledForDefaultPlayers takes integer slotGroupId, integer uId, integer baseAmount, real pct, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
            local integer ownerId = WAVE_DEFAULT_OWNER_MIN
            local integer amount = baseAmount
            if scaleWithActivePlayers then
                set amount = this.computeScaledAmount(baseAmount, WaveCountPlayingUsers(), pct)
            endif
            loop
                exitwhen ownerId > WAVE_DEFAULT_OWNER_MAX
                call this.addSlotInternal(slotGroupId, uId, amount, lim, prio, fxId, killGate, isBoss, Player(ownerId), aiProfileId, laneId, behaviorFlags, threatWeight)
                set ownerId = ownerId + 1
            endloop
        endmethod

        method pickDefaultOwnerPid takes nothing returns integer
            local integer pid = WAVE_DEFAULT_OWNER_MIN
            local integer bestPid = -1
            local integer bestCount = 0
            loop
                exitwhen pid > WAVE_DEFAULT_OWNER_MAX
                if pid < WAVE_TRACKED_PLAYER_SLOTS then
                    if this.activeByPlayer[pid] < this.perPlayerLimit then
                        if bestPid < 0 or this.activeByPlayer[pid] < bestCount then
                            set bestPid = pid
                            set bestCount = this.activeByPlayer[pid]
                        endif
                    endif
                endif
                set pid = pid + 1
            endloop
            return bestPid
        endmethod

        // Modo nativo del sistema: crea slots para Player(8..12) en una sola llamada.
        method addSlotByPlayers takes integer uId, integer baseAmount, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss returns nothing
            call this.addSlotScaledForDefaultPlayers(0, uId, baseAmount, this.additionalPerPlayerPct, scaleWithActivePlayers, lim, prio, fxId, killGate, isBoss, 0, 0, 0, 1.0)
        endmethod

        method addSlotByPlayersPct takes integer uId, integer baseAmount, real pct, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss returns nothing
            call this.addSlotScaledForDefaultPlayers(0, uId, baseAmount, pct, scaleWithActivePlayers, lim, prio, fxId, killGate, isBoss, 0, 0, 0, 1.0)
        endmethod

        method addSlotExByPlayers takes integer uId, integer baseAmount, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
            call this.addSlotScaledForDefaultPlayers(0, uId, baseAmount, this.additionalPerPlayerPct, scaleWithActivePlayers, lim, prio, fxId, killGate, isBoss, aiProfileId, laneId, behaviorFlags, threatWeight)
        endmethod

        method upsertSlotExByPlayers takes integer slotGroupId, integer uId, integer baseAmount, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
            if slotGroupId <= 0 then
                call this.addSlotExByPlayers(uId, baseAmount, scaleWithActivePlayers, lim, prio, fxId, killGate, isBoss, aiProfileId, laneId, behaviorFlags, threatWeight)
                return
            endif
            call this.addSlotScaledForDefaultPlayers(slotGroupId, uId, baseAmount, this.additionalPerPlayerPct, scaleWithActivePlayers, lim, prio, fxId, killGate, isBoss, aiProfileId, laneId, behaviorFlags, threatWeight)
        endmethod

        // Variante explÃƒÆ’Ã‚Â­cita por jugador para casos especiales.
        method addSlotByPlayer takes integer uId, integer baseAmount, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p returns nothing
            local integer amount = baseAmount
            if scaleWithActivePlayers then
                set amount = this.computeScaledAmount(baseAmount, WaveCountPlayingUsers(), this.additionalPerPlayerPct)
            endif
            call this.addSlotInternal(0, uId, amount, lim, prio, fxId, killGate, isBoss, p, 0, 0, 0, 1.0)
        endmethod

        method addSlotByPlayerPct takes integer uId, integer baseAmount, real pct, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p returns nothing
            local integer amount = baseAmount
            if scaleWithActivePlayers then
                set amount = this.computeScaledAmount(baseAmount, WaveCountPlayingUsers(), pct)
            endif
            call this.addSlotInternal(0, uId, amount, lim, prio, fxId, killGate, isBoss, p, 0, 0, 0, 1.0)
        endmethod

        method addSlotExByPlayer takes integer uId, integer baseAmount, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
            local integer amount = baseAmount
            if scaleWithActivePlayers then
                set amount = this.computeScaledAmount(baseAmount, WaveCountPlayingUsers(), this.additionalPerPlayerPct)
            endif
            call this.addSlotInternal(0, uId, amount, lim, prio, fxId, killGate, isBoss, p, aiProfileId, laneId, behaviorFlags, threatWeight)
        endmethod

        method upsertSlotExByPlayer takes integer slotGroupId, integer uId, integer baseAmount, boolean scaleWithActivePlayers, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p, integer aiProfileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
            local integer amount = baseAmount
            if slotGroupId <= 0 then
                call this.addSlotExByPlayer(uId, baseAmount, scaleWithActivePlayers, lim, prio, fxId, killGate, isBoss, p, aiProfileId, laneId, behaviorFlags, threatWeight)
                return
            endif
            if scaleWithActivePlayers then
                set amount = this.computeScaledAmount(baseAmount, WaveCountPlayingUsers(), this.additionalPerPlayerPct)
            endif
            call this.addSlotInternal(slotGroupId, uId, amount, lim, prio, fxId, killGate, isBoss, p, aiProfileId, laneId, behaviorFlags, threatWeight)
        endmethod

        method registerWaveUnit takes unit u, WaveSlot s, boolean isBoss, boolean isExternal returns nothing
            local integer hid
            if (u == null) or (GetUnitTypeId(u) == 0) then
                return
            endif
            set hid = GetHandleId(u)
            set WaveByUnit[hid] = this
            if s != 0 then
                set SlotByUnit[hid] = s
                call ExternalIsBoss.remove(hid)
            else
                call SlotByUnit.remove(hid)
                if isExternal then
                    if isBoss then
                        set ExternalIsBoss[hid] = 1
                    else
                        set ExternalIsBoss[hid] = 0
                    endif
                else
                    call ExternalIsBoss.remove(hid)
                endif
            endif
            call this.trackActiveUnit(u)
            call WaveFireSpawn(this, u, s, isBoss, isExternal)
            if isExternal then
                call WaveFireExternal(this, u, s, isBoss, true)
            endif
        endmethod

        method registerExternalUnit takes unit source, unit summoned, boolean isBoss returns nothing
            local integer srcId = GetHandleId(source)
            local integer summonedId = GetHandleId(summoned)
            local Wave w
            local integer ownerPid
            local integer srcFxId

            if (source == null) or (summoned == null) then
                call WaveDebugLog("registerExternalUnit reject reason=null_source_or_summoned source=" + WaveDebugUnitSummary(source) + " summoned=" + WaveDebugUnitSummary(summoned) + " boss=" + I2S(WaveDebugBoolToInt(isBoss)))
                return
            endif
            if GetUnitTypeId(summoned) == 0 then
                call WaveDebugLog("registerExternalUnit reject reason=summoned_type_zero source=" + WaveDebugUnitSummary(source) + " summoned=" + WaveDebugUnitSummary(summoned) + " boss=" + I2S(WaveDebugBoolToInt(isBoss)))
                return
            endif

            // El invocador NO pertenece a ninguna wave ? ignorar
            if not WaveByUnit.has(srcId) then
                call WaveDebugLog("registerExternalUnit reject reason=source_not_tracked source=" + WaveDebugUnitSummary(source) + " summoned=" + WaveDebugUnitSummary(summoned) + " boss=" + I2S(WaveDebugBoolToInt(isBoss)))
                return
            endif

            set w = Wave(WaveByUnit[srcId])
            if (w == 0) or w.isDestroyed then
                call WaveDebugLog("registerExternalUnit reject reason=wave_invalid source=" + WaveDebugUnitSummary(source) + " summoned=" + WaveDebugUnitSummary(summoned) + " wave=" + I2S(w) + " boss=" + I2S(WaveDebugBoolToInt(isBoss)))
                return
            endif

            // Seguridad extra: no doble registro
            if WaveByUnit.has(GetHandleId(summoned)) then
                call WaveDebugLog("registerExternalUnit reject reason=summoned_already_tracked source=" + WaveDebugUnitSummary(source) + " summoned=" + WaveDebugUnitSummary(summoned) + " wave=" + I2S(w) + " boss=" + I2S(WaveDebugBoolToInt(isBoss)))
                return
            endif

            set ownerPid = GetPlayerId(GetOwningPlayer(summoned))
            if (ownerPid >= 0) and (ownerPid < WAVE_TRACKED_PLAYER_SLOTS) then
                set w.activeByPlayer[ownerPid] = w.activeByPlayer[ownerPid] + 1
            endif

            set srcFxId = 0
            if SlotByUnit.has(srcId) then
                set srcFxId = WaveSlot(SlotByUnit[srcId]).fxId
            elseif WaveExternalSpawnFxByUnit.has(srcId) then
                set srcFxId = WaveExternalSpawnFxByUnit[srcId]
            endif
            if srcFxId > 0 then
                set WaveExternalSpawnFxByUnit[GetHandleId(summoned)] = srcFxId
            endif

            set w.activeOnMap = w.activeOnMap + 1
            set w.totalToSpawn = w.totalToSpawn + 1
            set w.totalKilled = w.totalKilled + 1

            if isBoss then
                //set w.remainingBosses = w.remainingBosses + 1
                set w.totalBosses = w.totalBosses + 1
                set w.totalKilledBoss = w.totalKilledBoss + 1
                set w.activeBosses    = w.activeBosses + 1
            else
                //set w.remainingUnits = w.remainingUnits + 1
                set w.totalUnits = w.totalUnits + 1
                set w.totalKilledUnits = w.totalKilledUnits + 1
                set w.activeUnits    = w.activeUnits + 1
            endif

            if ownerPid >= 0 then
                set WaveExternalOwnerPidByUnit[summonedId] = ownerPid
            endif

            call w.registerWaveUnit(summoned, 0, isBoss, true)
            call WaveDebugLog("registerExternalUnit wave=" + I2S(w) + " source=" + WaveDebugUnitSummary(source) + " summoned=" + WaveDebugUnitSummary(summoned) + " ownerPid=" + I2S(ownerPid) + " external=1 boss=" + I2S(WaveDebugBoolToInt(isBoss)))

        endmethod


        method addPoint takes real x, real y returns nothing
            if this.pointCount >= WAVE_MAX_POINTS then
                return
            endif
            set this.pointX[this.pointCount] = x
            set this.pointY[this.pointCount] = y
            set this.pointCount = this.pointCount + 1
        endmethod

        method addNearUnit takes unit u returns nothing
            if this.nearUnitCount >= WAVE_MAX_NEAR_UNITS then
                return
            endif
            if (u == null) or (GetUnitTypeId(u) == 0) then
                return
            endif
            set this.nearUnits[this.nearUnitCount] = u
            set this.nearUnitCount = this.nearUnitCount + 1
        endmethod

        method clearAffiliateUnit takes nothing returns nothing
            if this.affiliateUnitHid <= 0 then
                return
            endif
            if WaveAffiliateWaveByUnit.has(this.affiliateUnitHid) and (WaveAffiliateWaveByUnit[this.affiliateUnitHid] == this) then
                call WaveAffiliateWaveByUnit.remove(this.affiliateUnitHid)
                call WaveAffiliateModeByUnit.remove(this.affiliateUnitHid)
            endif
            set this.affiliateUnitHid = 0
            set this.affiliateTerminateMode = 0
        endmethod

        // Vincula esta wave a una unidad externa.
        // Cuando esa unidad muera, la wave se termina:
        //   forceKillOnDeath = false -> terminate(false)
        //   forceKillOnDeath = true  -> terminate(true)
        method setAffiliateUnit takes unit anchor, boolean forceKillOnDeath returns nothing
            local integer hid
            local Wave oldWave

            call this.clearAffiliateUnit()
            if (anchor == null) or (GetUnitTypeId(anchor) == 0) then
                return
            endif

            set hid = GetHandleId(anchor)
            if WaveAffiliateWaveByUnit.has(hid) then
                set oldWave = Wave(WaveAffiliateWaveByUnit[hid])
                if (oldWave != 0) and (oldWave != this) then
                    set oldWave.affiliateUnitHid = 0
                    set oldWave.affiliateTerminateMode = 0
                endif
            endif

            set WaveAffiliateWaveByUnit[hid] = this
            if forceKillOnDeath then
                set WaveAffiliateModeByUnit[hid] = 1
                set this.affiliateTerminateMode = 1
            else
                set WaveAffiliateModeByUnit[hid] = 0
                set this.affiliateTerminateMode = 0
            endif
            set this.affiliateUnitHid = hid
        endmethod

        private method activeKey takes integer index returns integer
            return this*WAVE_ACTIVE_STRIDE + index
        endmethod

        private method trackActiveUnit takes unit u returns nothing
            local integer hid
            local integer index
            if u == null then
                return
            endif
            if this.activeTrackedCount >= (WAVE_ACTIVE_STRIDE - 1) then
                return
            endif
            set hid = GetHandleId(u)
            if WaveActivePosByUnit.has(hid) then
                return
            endif
            set index = this.activeTrackedCount + 1
            set this.activeTrackedCount = index
            set WaveActiveUnitByKey.unit[this.activeKey(index)] = u
            set WaveActivePosByUnit[hid] = index
        endmethod

        method untrackUnitByHandle takes integer hid returns nothing
            local integer index
            local integer last
            local integer key
            local integer movedKey
            local unit moved
            if not WaveActivePosByUnit.has(hid) then
                return
            endif
            set index = WaveActivePosByUnit[hid]
            set last = this.activeTrackedCount
            if (index <= 0) or (index > last) then
                call WaveActivePosByUnit.remove(hid)
                return
            endif

            set key = this.activeKey(index)
            set movedKey = this.activeKey(last)
            if index != last then
                set moved = WaveActiveUnitByKey.unit[movedKey]
                set WaveActiveUnitByKey.unit[key] = moved
                if moved != null then
                    set WaveActivePosByUnit[GetHandleId(moved)] = index
                endif
            endif

            call WaveActiveUnitByKey.remove(movedKey)
            call WaveActivePosByUnit.remove(hid)
            set this.activeTrackedCount = last - 1
            set moved = null
        endmethod

        method getActiveIndexedCount takes nothing returns integer
            return this.activeTrackedCount
        endmethod

        method getActiveIndexedUnit takes integer index returns unit
            if (index < 1) or (index > this.activeTrackedCount) then
                return null
            endif
            return WaveActiveUnitByKey.unit[this.activeKey(index)]
        endmethod

        private method clampCoreCounters takes nothing returns nothing
            if this.activeOnMap < 0 then
                set this.activeOnMap = 0
            endif
            if this.activeUnits < 0 then
                set this.activeUnits = 0
            endif
            if this.activeBosses < 0 then
                set this.activeBosses = 0
            endif
            if this.remainingToSpawn < 0 then
                set this.remainingToSpawn = 0
            endif
            if this.remainingUnits < 0 then
                set this.remainingUnits = 0
            endif
            if this.remainingBosses < 0 then
                set this.remainingBosses = 0
            endif
            if this.totalToSpawn < 0 then
                set this.totalToSpawn = 0
            endif
            if this.totalUnits < 0 then
                set this.totalUnits = 0
            endif
            if this.totalBosses < 0 then
                set this.totalBosses = 0
            endif
            if this.totalKilled < 0 then
                set this.totalKilled = 0
            endif
            if this.totalKilledUnits < 0 then
                set this.totalKilledUnits = 0
            endif
            if this.totalKilledBoss < 0 then
                set this.totalKilledBoss = 0
            endif
        endmethod

        private method cancelSlotRemaining takes WaveSlot s returns nothing
            local integer canceled
            if s == 0 then
                return
            endif
            set canceled = s.remaining
            if canceled <= 0 then
                return
            endif
            set s.remaining = 0
            set this.remainingToSpawn = this.remainingToSpawn - canceled
            set this.totalToSpawn = this.totalToSpawn - canceled
            set this.totalKilled = this.totalKilled - canceled
            if s.isBoss then
                set this.remainingBosses = this.remainingBosses - canceled
                set this.totalBosses = this.totalBosses - canceled
                set this.totalKilledBoss = this.totalKilledBoss - canceled
            else
                set this.remainingUnits = this.remainingUnits - canceled
                set this.totalUnits = this.totalUnits - canceled
                set this.totalKilledUnits = this.totalKilledUnits - canceled
            endif
        endmethod

        private method cancelAllPendingSlots takes nothing returns nothing
            local integer i = 0
            loop
                exitwhen i >= this.slotCount
                call this.cancelSlotRemaining(this.slots[i])
                set i = i + 1
            endloop
            call this.clampCoreCounters()
        endmethod

        method cancelReservedSpawn takes WaveSlot s, integer pid, boolean restoreRemaining returns nothing
            if s == 0 then
                return
            endif

            set s.active = s.active - 1
            if s.active < 0 then
                set s.active = 0
            endif

            if (pid >= 0) and (pid < WAVE_TRACKED_PLAYER_SLOTS) then
                set this.activeByPlayer[pid] = this.activeByPlayer[pid] - 1
                if this.activeByPlayer[pid] < 0 then
                    set this.activeByPlayer[pid] = 0
                endif
            endif

            set this.activeOnMap = this.activeOnMap - 1
            if s.isBoss then
                set this.activeBosses = this.activeBosses - 1
            else
                set this.activeUnits = this.activeUnits - 1
            endif

            if restoreRemaining then
                set s.remaining = s.remaining + 1
                set this.remainingToSpawn = this.remainingToSpawn + 1
                if s.isBoss then
                    set this.remainingBosses = this.remainingBosses + 1
                else
                    set this.remainingUnits = this.remainingUnits + 1
                endif
            else
                set this.totalToSpawn = this.totalToSpawn - 1
                set this.totalKilled = this.totalKilled - 1
                if s.isBoss then
                    set this.totalBosses = this.totalBosses - 1
                    set this.totalKilledBoss = this.totalKilledBoss - 1
                else
                    set this.totalUnits = this.totalUnits - 1
                    set this.totalKilledUnits = this.totalKilledUnits - 1
                endif
            endif
            call this.clampCoreCounters()
        endmethod

        method tryDestroyAfterTermination takes nothing returns nothing
            if this.isDestroyed then
                return
            endif
            if this.terminateRequested and this.activeOnMap <= 0 then
                call this.fireFinishEventOnce()
                call this.destroyWave()
            endif
        endmethod

        private method killAllTrackedUnits takes nothing returns nothing
            local integer i = this.getActiveIndexedCount()
            local unit u
            loop
                exitwhen i < 1 or this.isDestroyed
                set u = this.getActiveIndexedUnit(i)
                if (u != null) and (GetUnitTypeId(u) != 0) and UnitAlive(u) then
                    call KillUnit(u)
                endif
                set i = i - 1
            endloop
            set u = null
        endmethod

        // modeKillAlive = false:
        //   cancela por completo lo pendiente y espera a que mueran las unidades vivas.
        // modeKillAlive = true:
        //   cancela pendiente y mata todas las unidades vivas de la instancia.
        method terminate takes boolean modeKillAlive returns nothing
            if this.isDestroyed then
                return
            endif
            set this.terminateRequested = true
            set this.cancelPendingPermanently = true
            // Al terminar por API tambiÃ©n queremos ejecutar callback final (RestTime/endF).
            set this.suppressEndCallback = false
            set this.isRunning = false
            set this.isPaused = true
            set this.isFinishing = true

            if this.loopTimer != null then
                call PauseTimer(this.loopTimer)
            endif

            call this.cancelAllPendingSlots()
            set this.waveToken = this.waveToken + 1

            if modeKillAlive then
                call this.killAllTrackedUnits()
            endif

            // Al terminar por API, forzamos refresco inmediato de multiboard.
            call this.refreshBoard()

            call this.tryDestroyAfterTermination()
        endmethod

        private method compactNearUnits takes nothing returns nothing
            local integer i = 0
            local integer write = 0
            local unit u
            loop
                exitwhen i >= this.nearUnitCount
                set u = this.nearUnits[i]
                if (u != null) and (GetUnitTypeId(u) != 0) then
                    set this.nearUnits[write] = u
                    set write = write + 1
                endif
                set i = i + 1
            endloop
            set this.nearUnitCount = write
            set u = null
        endmethod

        method getRandomPointIndex takes nothing returns integer
            if this.pointCount == 0 then
                call WaveDebugLog("getRandomPointIndex reject reason=no_points")
                return -1
            endif
            return GetRandomInt(0, this.pointCount - 1)
        endmethod

        method tryGetNearUnitPoint takes real radius returns boolean
            local integer tries = 10
            local integer index
            local unit u
            local real angle
            local real dist
            local real x
            local real y           

            if this.nearUnitCount == 0 then
                return false
            endif

            loop
                exitwhen tries <= 0

                set index = GetRandomInt(0, this.nearUnitCount - 1)
                set u = this.nearUnits[index]

                if u != null and GetUnitTypeId(u) != 0 and UnitAlive(u) then
                    set angle = GetRandomReal(0.0, 6.28318)
                    set dist  = GetRandomReal(64.0, radius)

                    set x = GetUnitX(u) + dist * Cos(angle)
                    set y = GetUnitY(u) + dist * Sin(angle)

                    // false = caminable
                    if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
                        set this.spawnX = x
                        set this.spawnY = y
                        return true
                    endif
                endif

                set tries = tries - 1
            endloop

            return false
        endmethod

        method selectSpawnPoint takes real radius returns boolean
            local integer roll
            local integer pIndex

            set roll = GetRandomInt(1, 100)

            // Intentar spawn cerca de unidad
            if roll <= this.nearUnitChance then
                if this.tryGetNearUnitPoint(radius) then
                    return true
                endif
            endif

            // Fallback a puntos base
            set pIndex = this.getRandomPointIndex()
            if pIndex >= 0 then
                set this.spawnX = this.pointX[pIndex]
                set this.spawnY = this.pointY[pIndex]
                return true
            endif

            return false
        endmethod

        // Iniciar la wave
        method start takes nothing returns nothing
            if this.isDestroyed or (this.loopTimer != null) then
                return
            endif
            set this.loopTimer = NewTimer()
            call SetTimerDebugTag(this.loopTimer, TIMER_DEBUG_TAG_WAVE_CORE)
            set WaveByTimer[GetHandleId(this.loopTimer)] = this
            call TimerStart(this.loopTimer, this.interval, true, function Wave_onTick)
            set this.isRunning = true
            set this.isPaused = false
            set this.isFinishing = false
            set this.tickCounter = 0
            call WaveFireStart(this)
        endmethod

        method pause takes nothing returns nothing
            if this.isDestroyed or (not this.isRunning) or this.isPaused then
                return
            endif
            if this.loopTimer != null then
                call PauseTimer(this.loopTimer)
            endif
            set this.isPaused = true
            call WaveFirePause(this)
        endmethod

        method resume takes nothing returns nothing
            if this.isDestroyed or (not this.isRunning) or (not this.isPaused) then
                return
            endif
            if this.loopTimer != null then
                call TimerStart(this.loopTimer, this.interval, true, function Wave_onTick)
            endif
            set this.isPaused = false
            call WaveFireResume(this)
        endmethod

        //==================================================
        private method isTrackedPid takes integer pid returns boolean
            return (pid >= 0) and (pid < WAVE_TRACKED_PLAYER_SLOTS)
        endmethod

        private method killGatePassed takes WaveSlot s returns boolean
            if s.killGate == -1 then
                return true
            endif
            return this.totalKilled <= s.killGate
        endmethod

        //==================================================
        // Elegir slot ()
        //==================================================
        method pickSlot takes nothing returns WaveSlot
            local integer i = 0
            local integer validCount = 0
            local integer pick
            local WaveSlot s
            local integer pid
            local integer maxPrio = -1

            // 1. Encontrar prioridad mÃ¡s alta vÃ¡lida
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if this.isTrackedPid(pid) and s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    if this.killGatePassed(s) then
                        if s.priority > maxPrio then
                            set maxPrio = s.priority
                        endif
                    endif
                endif

                set i = i + 1
            endloop

            if maxPrio < 0 then
                return 0
            endif


            // 2. Contar slots con esa prioridad
            set i = 0
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if this.isTrackedPid(pid) and s.priority == maxPrio and s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    if this.killGatePassed(s) then
                        set validCount = validCount + 1
                    endif
                endif

                set i = i + 1
            endloop

            // 3. Elegir random entre ellos
            if validCount <= 0 then
                return 0
            endif
            set pick = GetRandomInt(1, validCount)

            set i = 0
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if this.isTrackedPid(pid) and s.priority == maxPrio and s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    if this.killGatePassed(s) then
                        set pick = pick - 1
                        if pick == 0 then
                            return s
                        endif
                    endif
                endif

                set i = i + 1
            endloop

            return 0 // seguridad
        endmethod

        //==================================================
        method trySpawn takes nothing returns nothing
            local WaveSlot s
            local integer pid
            local PendingSpawn ps
            
            set s = this.pickSlot()

            if s == 0 then
                return 
            endif

            if not this.selectSpawnPoint(256.0) then
                return
            endif

            set pid = GetPlayerId(s.owner)
            if not this.isTrackedPid(pid) then
                return
            endif

            set this.activeByPlayer[pid] = this.activeByPlayer[pid] + 1
            set s.remaining              = s.remaining - 1
            set s.active                 = s.active + 1
            set this.activeOnMap         = this.activeOnMap + 1

            set this.remainingToSpawn = this.remainingToSpawn - 1

            if s.isBoss then
                set this.remainingBosses = this.remainingBosses - 1
                set this.activeBosses    = this.activeBosses + 1
            else
                set this.remainingUnits = this.remainingUnits - 1
                set this.activeUnits    = this.activeUnits + 1
            endif

            // 2. Crear pending spawn
            set ps = PendingSpawn.create()
            set ps.wave = this
            set ps.slot = s
            set ps.pid  = pid
            set ps.waveToken = this.waveToken
            set ps.x    = this.spawnX
            set ps.y    = this.spawnY

            if s.fxId > 0 and s.fxId <= FX_MAX then
                call DestroyEffect(AddSpecialEffect(FX_UnitIn[s.fxId], ps.x, ps.y))
            endif

            // 4. Timer de spawn real
            set ps.t = NewTimer()
            call SetTimerDebugTag(ps.t, TIMER_DEBUG_TAG_WAVE_CORE)
            call SetTimerData(ps.t, ps)
            call TimerStart(ps.t, 1.50, false, function PendingSpawn_execute)

        endmethod

        //==================================================
        method allSlotsEmpty takes nothing returns boolean
            local integer i = 0
            loop
                exitwhen i >= this.slotCount
                if this.slots[i].remaining > 0 then
                    return false
                endif
                set i = i + 1
            endloop
            return true
        endmethod

        // API semÃƒÂ¡ntica para IA/UI (sin romper legacy)
        method getToKillRemaining takes nothing returns integer
            return this.totalKilled
        endmethod

        method getToKillUnitsRemaining takes nothing returns integer
            return this.totalKilledUnits
        endmethod

        method getToKillBossRemaining takes nothing returns integer
            return this.totalKilledBoss
        endmethod

        method getKillsDone takes nothing returns integer
            return this.killsDone
        endmethod

        method getKillsDoneUnits takes nothing returns integer
            return this.killsDoneUnits
        endmethod

        method getKillsDoneBoss takes nothing returns integer
            return this.killsDoneBoss
        endmethod

        method isOperational takes nothing returns boolean
            return this.isRunning and (not this.isPaused) and (not this.isDestroyed)
        endmethod

        method refreshBoard takes nothing returns nothing
            if this.board != null and this.titleFunc != "" then
                set CurrentBoardContext = this.board
                call ExecuteFunc(this.titleFunc)
                set CurrentBoardContext = null
            endif
        endmethod

        //==================================================
        method onTick takes nothing returns nothing
            if this.isDestroyed or this.isPaused then
                return
            endif
            set this.tickCounter = this.tickCounter + 1
            if ModuloInteger(this.tickCounter, 16) == 0 then
                call this.compactNearUnits()
            endif
            call this.trySpawn()

            call this.refreshBoard()

            if this.allSlotsEmpty() and this.activeOnMap <= 0 then
                call this.finish()
            endif
        endmethod

        //==================================================
        private method fireFinishEventOnce takes nothing returns nothing
            if this.finishEventFired then
                return
            endif
            set this.finishEventFired = true
            call WaveFireFinish(this)
        endmethod

        //==================================================
        method finish takes nothing returns nothing
            if this.isDestroyed or this.isFinishing then
                return
            endif
            set this.isFinishing = true
            call this.fireFinishEventOnce()
            call this.destroyWave()
        endmethod

        method destroyWave takes nothing returns nothing
            local integer i = 0
            local integer hid
            local integer key
            local unit u

            if this.isDestroyed then
                return
            endif
            set this.isDestroyed = true
            set this.isRunning = false
            set this.isPaused = false

            // Timer
            if this.loopTimer != null then
                call PauseTimer(this.loopTimer)
                call ReleaseTimer(this.loopTimer)
                call WaveByTimer.remove(GetHandleId(this.loopTimer))
                set this.loopTimer = null
            endif

            // Active units index cleanup
            set i = 1
            loop
                exitwhen i > this.activeTrackedCount
                set key = this.activeKey(i)
                set u = WaveActiveUnitByKey.unit[key]
                if u != null then
                    set hid = GetHandleId(u)
                    call WaveByUnit.remove(hid)
                    call SlotByUnit.remove(hid)
                    call ExternalIsBoss.remove(hid)
                    call WaveExternalOwnerPidByUnit.remove(hid)
                    call WaveExternalSpawnFxByUnit.remove(hid)
                    call WaveActivePosByUnit.remove(hid)
                endif
                call WaveActiveUnitByKey.remove(key)
                set i = i + 1
            endloop
            set this.activeTrackedCount = 0
            set u = null

            // Multiboard
            if this.board != null then
                call WaveByBoard.remove(GetHandleId(this.board))
                set this.board = null
                set this.titleFunc = ""
            endif

            // endFunct
            if (not this.suppressEndCallback) and this.finishFuncName != "" then 
                // RestTime: recibe el nombre de la funciÃƒÂ³n a ejecutar luego.
                call endF(this.finishFuncName)
            endif

            // Slots
            set i = 0
            loop
                exitwhen i >= this.slotCount
                call this.slots[i].destroy()
                set this.slots[i] = 0
                set i = i + 1
            endloop

            set this.nearUnitCount = 0
            set this.pointCount = 0
            call this.clearAffiliateUnit()

            call this.destroy()
        endmethod
    endstruct

    function GetWaveEventWave takes nothing returns Wave
        return Wave(WaveEventWaveId)
    endfunction

    function GetWaveEventUnit takes nothing returns unit
        return WaveEventUnit
    endfunction

    function GetWaveEventKiller takes nothing returns unit
        return WaveEventKiller
    endfunction

    function GetWaveEventSlot takes nothing returns WaveSlot
        return WaveSlot(WaveEventSlotId)
    endfunction

    function IsWaveEventBoss takes nothing returns boolean
        return WaveEventIsBoss
    endfunction

    function IsWaveEventExternal takes nothing returns boolean
        return WaveEventIsExternal
    endfunction

    function GetWaveSlotByUnit takes unit u returns WaveSlot
        local integer hid
        if u == null then
            return 0
        endif
        set hid = GetHandleId(u)
        if SlotByUnit.has(hid) then
            return SlotByUnit[hid]
        endif
        return 0
    endfunction

    function IsWaveManagedUnit takes unit u returns boolean
        if u == null then
            return false
        endif
        return WaveByUnit.has(GetHandleId(u))
    endfunction

    function RegisterWaveStartEvent takes code c returns nothing
        if WaveEvtStart == null then
            set WaveEvtStart = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtStart, c)
    endfunction

    function RegisterWavePauseEvent takes code c returns nothing
        if WaveEvtPause == null then
            set WaveEvtPause = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtPause, c)
    endfunction

    function RegisterWaveResumeEvent takes code c returns nothing
        if WaveEvtResume == null then
            set WaveEvtResume = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtResume, c)
    endfunction

    function RegisterWaveFinishEvent takes code c returns nothing
        if WaveEvtFinish == null then
            set WaveEvtFinish = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtFinish, c)
    endfunction

    function RegisterWaveSpawnEvent takes code c returns nothing
        if WaveEvtSpawn == null then
            set WaveEvtSpawn = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtSpawn, c)
    endfunction

    function RegisterWaveDeathEvent takes code c returns nothing
        if WaveEvtDeath == null then
            set WaveEvtDeath = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtDeath, c)
    endfunction

    function RegisterWaveExternalEvent takes code c returns nothing
        if WaveEvtExternal == null then
            set WaveEvtExternal = CreateTrigger()
        endif
        call TriggerAddAction(WaveEvtExternal, c)
    endfunction

    function PauseWave takes Wave w returns nothing
        if w != 0 then
            call w.pause()
        endif
    endfunction

    function ResumeWave takes Wave w returns nothing
        if w != 0 then
            call w.resume()
        endif
    endfunction

    function BindWaveToUnitDeath takes Wave w, unit anchor, boolean forceKillOnDeath returns nothing
        if w != 0 then
            call w.setAffiliateUnit(anchor, forceKillOnDeath)
        endif
    endfunction

    function UnbindWaveFromUnitDeath takes Wave w returns nothing
        if w != 0 then
            call w.clearAffiliateUnit()
        endif
    endfunction

    function TerminateWaveInstanceGraceful takes integer waveId returns nothing
        local Wave w = Wave(waveId)
        if w != 0 then
            call w.terminate(false)
            call w.refreshBoard()
        endif
    endfunction

    function TerminateWaveInstanceForceKill takes integer waveId returns nothing
        local Wave w = Wave(waveId)
        if w != 0 then
            call w.terminate(true)
            call w.refreshBoard()
        endif
    endfunction

    function BindWaveInstanceToUnitDeath takes integer waveId, unit anchor, boolean forceKillOnDeath returns nothing
        local Wave w = Wave(waveId)
        if w != 0 then
            call w.setAffiliateUnit(anchor, forceKillOnDeath)
        endif
    endfunction

    function UnbindWaveInstanceFromUnitDeath takes integer waveId returns nothing
        local Wave w = Wave(waveId)
        if w != 0 then
            call w.clearAffiliateUnit()
        endif
    endfunction

    function InitFX takes nothing returns nothing
        // 1. Teletransporte masivo humano
        set FX_UnitIn[1]  = "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl"
        set FX_UnitOut[1] = "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl"
        // 2. ResurrecciÃ³n humana
        set FX_UnitIn[2]  = "Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl"
        set FX_UnitOut[2] = "Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl"
        // 3. Animar muerto no-muerto
        set FX_UnitIn[3]  = "Abilities\\Spells\\Undead\\CarrionSwarm\\CarrionSwarmDamage.mdl"
        set FX_UnitOut[3] = "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl"
        // 4. Artefacto especial (AIil)
        set FX_UnitIn[4]  = "Abilities\\Spells\\Items\\AIil\\AIilTarget.mdl"
        set FX_UnitOut[4] = "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl"
        // 5. DisipaciÃ³n no-muerto
        set FX_UnitIn[5]  = "Objects\\Spawnmodels\\Undead\\UndeadDissipate\\UndeadDissipate.mdl"
        set FX_UnitOut[5] = "Abilities\\Spells\\Human\\MarkOfChaos\\MarkOfChaosDone.mdl"
        // 6. PurificaciÃ³n de objeto
        set FX_UnitIn[6]  = "Abilities\\Spells\\Items\\StaffOfPurification\\PurificationCaster.mdl"
        set FX_UnitOut[6] = "Abilities\\Spells\\Items\\StaffOfPurification\\PurificationTarget.mdl"
        // 7. Invocar esqueleto guerrero
        set FX_UnitIn[7]  = "Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl"
        set FX_UnitOut[7] = "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl"
        // 8.  / batalla
        set FX_UnitIn[8]  = "Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl"
        set FX_UnitOut[8] = "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl"
        // 9. Ola aplastante / daÃ±o
        set FX_UnitIn[9]  = "Abilities\\Spells\\Other\\CrushingWave\\CrushingWaveDamage.mdl"
        set FX_UnitOut[9] = "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl"
        // 10. DisipaciÃ³n / cancelaciÃ³n no-muerto
        set FX_UnitIn[10]  = "Objects\\Spawnmodels\\Undead\\UndeadDissipate\\UndeadDissipate.mdl"
        set FX_UnitOut[10] = "Objects\\Spawnmodels\\Undead\\UCancelDeath\\UCancelDeath.mdl"
        // 11. Polvo de empalamiento / humano
        set FX_UnitIn[11]  = "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl"
        set FX_UnitOut[11] = "Objects\\Spawnmodels\\Human\\HCancelDeath\\HCancelDeath.mdl"
        // 12. Pacto de muerte
        set FX_UnitIn[12]  = "Abilities\\Spells\\Undead\\DeathPact\\DeathPactTarget.mdl"
        set FX_UnitOut[12] = "Objects\\Spawnmodels\\NightElf\\NECancelDeath\\NECancelDeath.mdl"
        // 13. ToonBoom / arte especial
        set FX_UnitIn[13]  = "Objects\\Spawnmodels\\Other\\ToonBoom\\ToonBoom.mdl"
        set FX_UnitOut[13] = "Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl"
        // 15. Rayo divino / HolyBolt
        set FX_UnitIn[14]  = "Abilities\\Spells\\Other\\Awaken\\Awaken.mdl"
        set FX_UnitOut[14] = "Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl"
        // 16. Arte AIhe / HolyBolt
        set FX_UnitIn[15]  = "Abilities\\Spells\\Items\\AIhe\\AIheTarget.mdl"
        set FX_UnitOut[15] = "Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl"
        // 17. Feedback / WarStomp
        set FX_UnitIn[16]  = "Abilities\\Spells\\Human\\Feedback\\SpellBreakerAttack.mdl"
        set FX_UnitOut[16] = "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl"
        // 18. Control mÃ¡gico
        set FX_UnitIn[17]  = "Abilities\\Spells\\Human\\ControlMagic\\ControlMagicTarget.mdl"
        set FX_UnitOut[17] = "Abilities\\Spells\\Undead\\DarkRitual\\DarkRitualTarget.mdl"
        // 19. Impacto de proyectil / Bolt
        set FX_UnitIn[18]  = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        set FX_UnitOut[18] = "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl"
        // 20. Dispel / TomeOfRetraining
        set FX_UnitIn[19]  = "Abilities\\Spells\\Human\\DispelMagic\\DispelMagicTarget.mdl"
        set FX_UnitOut[19] = "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl"
    endfunction

    //==================================================
    // Trigger de muerte
    //==================================================
    private function OnUnitDeath takes nothing returns nothing
        local unit u = GetDyingUnit()
        local unit killer = GetKillingUnit()
        local integer hid = GetHandleId(u)
        local Wave w
        local WaveSlot s
        local integer pid
        local integer ownerPid = -1
        local integer slotUnitId = -1
        local boolean isBoss = false
        local boolean isExternal = false
        local string deathKind = "normal"

        if WaveByUnit.has(hid) then
            set w = Wave(WaveByUnit[hid])
            if w == 0 then
                call WaveDebugLog("OnUnitDeath reject reason=wave_missing unit=" + WaveDebugUnitSummary(u) + " killer=" + WaveDebugUnitSummary(killer) + " hid=" + I2S(hid))
                call WaveByUnit.remove(hid)
                call SlotByUnit.remove(hid)
                call ExternalIsBoss.remove(hid)
                call WaveExternalOwnerPidByUnit.remove(hid)
                call WaveExternalSpawnFxByUnit.remove(hid)
                call WaveHandleAffiliateDeath(hid)
                set u = null
                return
            endif
            if w.isDestroyed then
                call WaveDebugLog("OnUnitDeath reject reason=wave_destroyed unit=" + WaveDebugUnitSummary(u) + " killer=" + WaveDebugUnitSummary(killer) + " wave=" + I2S(w) + " hid=" + I2S(hid))
                call w.untrackUnitByHandle(hid)
                call WaveByUnit.remove(hid)
                call SlotByUnit.remove(hid)
                call ExternalIsBoss.remove(hid)
                call WaveExternalOwnerPidByUnit.remove(hid)
                call WaveExternalSpawnFxByUnit.remove(hid)
                call WaveHandleAffiliateDeath(hid)
                set u = null
                return
            endif

            set w.activeOnMap = w.activeOnMap - 1
            set w.totalKilled = w.totalKilled - 1
            set w.killsDone = w.killsDone + 1

            if SlotByUnit.has(hid) then
                set s = WaveSlot(SlotByUnit[hid])
                set slotUnitId = s.unitId
                if s.owner != null then
                    set ownerPid = GetPlayerId(s.owner)
                endif
                set pid = ownerPid
                if (pid >= 0) and (pid < WAVE_TRACKED_PLAYER_SLOTS) then
                    set w.activeByPlayer[pid] = w.activeByPlayer[pid] - 1
                endif
                set s.active = s.active - 1
                if s.isBoss then
                    set isBoss = true
                    set w.activeBosses = w.activeBosses - 1
                    set w.totalKilledBoss = w.totalKilledBoss - 1
                    set w.killsDoneBoss = w.killsDoneBoss + 1
                else
                    set w.activeUnits = w.activeUnits - 1
                    set w.totalKilledUnits = w.totalKilledUnits - 1
                    set w.killsDoneUnits = w.killsDoneUnits + 1
                endif
            elseif ExternalIsBoss.has(hid) then
                set isExternal = true
                if WaveExternalOwnerPidByUnit.has(hid) then
                    set pid = WaveExternalOwnerPidByUnit[hid]
                    set ownerPid = pid
                    if (pid >= 0) and (pid < WAVE_TRACKED_PLAYER_SLOTS) then
                        set w.activeByPlayer[pid] = w.activeByPlayer[pid] - 1
                        if w.activeByPlayer[pid] < 0 then
                            set w.activeByPlayer[pid] = 0
                        endif
                    endif
                endif
                if ExternalIsBoss[hid] == 1 then 
                    set isBoss = true
                    set w.activeBosses = w.activeBosses - 1
                    set w.totalKilledBoss = w.totalKilledBoss - 1
                    set w.killsDoneBoss = w.killsDoneBoss + 1
                else                   
                    set w.activeUnits = w.activeUnits - 1
                    set w.totalKilledUnits = w.totalKilledUnits - 1
                    set w.killsDoneUnits = w.killsDoneUnits + 1
                endif
            endif

            if isExternal and isBoss then
                set deathKind = "external_boss"
            elseif isExternal then
                set deathKind = "external"
            elseif isBoss then
                set deathKind = "boss"
            endif

            if WAVE_DEBUG_ENABLED then
                call WaveDebugLog("OnUnitDeath w=" + I2S(w) + " kind=" + deathKind + " unit=" + WaveDebugUnitSummary(u) + " killer=" + WaveDebugUnitSummary(killer) + " external=" + I2S(WaveDebugBoolToInt(isExternal)) + " boss=" + I2S(WaveDebugBoolToInt(isBoss)) + " ownerPid=" + I2S(ownerPid) + " slotUnitId=" + I2S(slotUnitId) + " hid=" + I2S(hid))
            endif

            call w.untrackUnitByHandle(hid)
            call WaveFireDeath(w, u, killer, s, isBoss, isExternal)

            call WaveByUnit.remove(hid)
            call SlotByUnit.remove(hid)
            call ExternalIsBoss.remove(hid)
            call WaveExternalOwnerPidByUnit.remove(hid)
            call WaveExternalSpawnFxByUnit.remove(hid)
            call w.tryDestroyAfterTermination()
        endif

        call WaveHandleAffiliateDeath(hid)

        set killer = null
        set u = null
    endfunction

    function registerExternalUnit takes unit source, unit summoned, boolean isBoss returns nothing
            local integer srcId = GetHandleId(source)
            local Wave w

            if not WaveByUnit.has(srcId) then
                return
            endif
            set w = Wave(WaveByUnit[srcId])
            if w == 0 then
                return
            endif
            call w.registerExternalUnit(source, summoned, isBoss)
    endfunction

    function GetWaveByUnit takes unit u returns Wave
        if u == null then
            return 0
        endif
        if not WaveByUnit.has(GetHandleId(u)) then
            return 0
        endif
        return Wave(WaveByUnit[GetHandleId(u)])
    endfunction

    function WaveIsDefaultOwnerPlayerId takes integer pid returns boolean
        return (pid >= WAVE_DEFAULT_OWNER_MIN) and (pid <= WAVE_DEFAULT_OWNER_MAX) and (pid < bj_MAX_PLAYER_SLOTS)
    endfunction

    function WaveGetDefaultOwnerCount takes nothing returns integer
        return WAVE_DEFAULT_OWNER_MAX - WAVE_DEFAULT_OWNER_MIN + 1
    endfunction

    function WaveGetSpawnFxIdForUnit takes unit u returns integer
        local integer hid
        local WaveSlot s
        if u == null or GetUnitTypeId(u) == 0 then
            return 0
        endif
        set s = GetWaveSlotByUnit(u)
        if s != 0 then
            return s.fxId
        endif
        set hid = GetHandleId(u)
        if hid != 0 and WaveExternalSpawnFxByUnit.has(hid) then
            return WaveExternalSpawnFxByUnit[hid]
        endif
        return 0
    endfunction

    function WaveCanSpawnUnitFromDefaultOwnerPid takes unit source, integer pid returns boolean
        local Wave w
        if source == null or GetUnitTypeId(source) == 0 then
            return false
        endif
        if not WaveIsDefaultOwnerPlayerId(pid) or pid >= WAVE_TRACKED_PLAYER_SLOTS then
            return false
        endif
        set w = GetWaveByUnit(source)
        if w == 0 or w.isDestroyed then
            return false
        endif
        return w.activeByPlayer[pid] < w.perPlayerLimit
    endfunction

    function WaveSpawnUnitFromDefaultOwnerPid takes unit source, integer unitTypeId, integer pid, real x, real y returns unit
        local Wave w
        local unit summoned
        local integer fxId
        if unitTypeId == 0 then
            return null
        endif
        if not WaveCanSpawnUnitFromDefaultOwnerPid(source, pid) then
            return null
        endif
        set w = GetWaveByUnit(source)
        if w == 0 or w.isDestroyed then
            return null
        endif
        set fxId = WaveGetSpawnFxIdForUnit(source)
        if fxId > 0 and fxId <= FX_MAX then
            call DestroyEffect(AddSpecialEffect(FX_UnitIn[fxId], x, y))
        endif
        set summoned = CreateUnit(Player(pid), unitTypeId, x, y, 270.0)
        if summoned == null or GetUnitTypeId(summoned) == 0 then
            set summoned = null
            return null
        endif
        if fxId > 0 and fxId <= FX_MAX then
            call DestroyEffect(AddSpecialEffectTarget(FX_UnitOut[fxId], summoned, "origin"))
        endif
        if fxId > 0 then
            set WaveExternalSpawnFxByUnit[GetHandleId(summoned)] = fxId
        endif
        return summoned
    endfunction

    function WaveSpawnUnitFromDefaultOwners takes unit source, integer unitTypeId, real x, real y returns unit
        local Wave w
        local integer pid
        local unit summoned
        if source == null or GetUnitTypeId(source) == 0 or unitTypeId == 0 then
            return null
        endif
        set w = GetWaveByUnit(source)
        if w == 0 or w.isDestroyed then
            return null
        endif
        set pid = w.pickDefaultOwnerPid()
        if pid < 0 then
            return null
        endif
        set summoned = WaveSpawnUnitFromDefaultOwnerPid(source, unitTypeId, pid, x, y)
        return summoned
    endfunction
    
    //==================================================
    // Init
    //==================================================
    private function Init takes nothing returns nothing
        local trigger t = CreateTrigger()
        local integer i = 0

        set WaveByUnit = Table.create()
        set WaveByTimer = Table.create()
        set SlotByUnit = Table.create()
        set WaveByBoard = Table.create()
        set ExternalIsBoss = Table.create()
        set WaveActiveUnitByKey = Table.create()
        set WaveActivePosByUnit = Table.create()
        set WaveAffiliateWaveByUnit = Table.create()
        set WaveAffiliateModeByUnit = Table.create()
        set WaveExternalOwnerPidByUnit = Table.create()
        set WaveExternalSpawnFxByUnit = Table.create()
        set WaveEvtStart = CreateTrigger()
        set WaveEvtPause = CreateTrigger()
        set WaveEvtResume = CreateTrigger()
        set WaveEvtFinish = CreateTrigger()
        set WaveEvtSpawn = CreateTrigger()
        set WaveEvtDeath = CreateTrigger()
        set WaveEvtExternal = CreateTrigger()
        call InitFX()

        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
            set i = i + 1
        endloop

        call TriggerAddAction(t, function OnUnitDeath)
    endfunction 
endlibrary

