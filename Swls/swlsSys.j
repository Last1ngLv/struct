
library WaveTest initializer Init /*

    */requires Table,/*
    */TimerUtils 

    globals
        Table WaveByUnit
        Table WaveByTimer
        Table SlotByUnit
    endglobals

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
    // WaveSlot
    //==================================================
    struct WaveSlot
        integer unitId
        integer remaining
        integer active
        integer limit
        integer priority
        player owner
    endstruct


    struct Wave
        integer slotCount
        WaveSlot array slots[100]

        integer perPlayerLimit
        integer array activeByPlayer[20] 

        integer activeOnMap

        //Timer
        real interval 
        timer loopTimer

        integer pointCount
        real array pointX[100]
        real array pointY[100]

        // --- NUEVO: spawn cerca de unidad ---
        integer nearUnitChance   // 0–100
        integer nearUnitCount
        unit array nearUnits[100]

        // --- cache del punto elegido ---
        real spawnX
        real spawnY
        

        static method create takes integer PlayerLim, integer nearChance, real sec returns Wave
            local Wave this = Wave.allocate()
            local integer i = 0

            set this.pointCount = 0
            set this.nearUnitChance = nearChance
            set this.nearUnitCount  = 0
            set this.slotCount = 0
            set this.activeOnMap = 0
            set this.perPlayerLimit = PlayerLim
            set this.interval  = sec

            loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                set this.activeByPlayer[i] = 0
                set i = i + 1
            endloop

            return this
        endmethod

        // Agregar un tipo de unidad
        method addSlot takes integer uId, integer amount, integer lim, integer prio, player p returns nothing
            local WaveSlot s = WaveSlot.create()

            set s.unitId    = uId
            set s.remaining = amount
            set s.active    = 0
            set s.limit     = lim
            set s.owner     = p
            set s.priority = prio

            set this.slots[this.slotCount] = s
            set this.slotCount = this.slotCount + 1
        endmethod

        method addPoint takes real x, real y returns nothing
            set this.pointX[this.pointCount] = x
            set this.pointY[this.pointCount] = y
            set this.pointCount = this.pointCount + 1
        endmethod

        method addNearUnit takes unit u returns nothing
            set this.nearUnits[this.nearUnitCount] = u
            set this.nearUnitCount = this.nearUnitCount + 1
        endmethod

        method getRandomPointIndex takes nothing returns integer
            if this.pointCount == 0 then
                call BJDebugMsg("Sin Punto")
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

                if u != null and GetUnitTypeId(u) != 0 then
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


        //method getNearUnitPoint takes real radius returns boolean


        // Iniciar la wave
        method start takes nothing returns nothing
            set this.loopTimer = NewTimer()
            set WaveByTimer[GetHandleId(this.loopTimer)] = this
            call TimerStart(this.loopTimer, this.interval, true, function Wave_onTick)
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

            // 1. Encontrar prioridad más alta válida
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    if s.priority > maxPrio then
                        set maxPrio = s.priority
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

                if s.priority == maxPrio and s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    set validCount = validCount + 1
                endif

                set i = i + 1
            endloop

            // 3. Elegir random entre ellos
            set pick = GetRandomInt(1, validCount)

            set i = 0
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if s.priority == maxPrio and s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    set pick = pick - 1
                    if pick == 0 then
                        return s
                    endif
                endif

                set i = i + 1
            endloop

            return 0 // seguridad
        endmethod

        //==================================================
        method trySpawn takes nothing returns nothing
            local WaveSlot s
            local unit u
            local integer pid
            local integer pIndex
            
            set s = this.pickSlot()

            if s == 0 then
                //call BJDebugMsg("No Spawn")
                return 
            endif
            
            set pid = GetPlayerId(s.owner)

            if not this.selectSpawnPoint(256.0) then
                return
            endif

            set u = CreateUnit(s.owner, s.unitId, this.spawnX, this.spawnY, 270.0)
            //call BJDebugMsg("Spawn " + I2S(s.unitId) + " P" + I2S(pid))

            set SlotByUnit[GetHandleId(u)] = s
            set WaveByUnit[GetHandleId(u)] = this

            set this.activeByPlayer[pid] = this.activeByPlayer[pid] + 1
            set s.remaining              = s.remaining - 1
            set s.active                 = s.active + 1
            set this.activeOnMap         = this.activeOnMap + 1

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

        //==================================================
        method onTick takes nothing returns nothing
            call this.trySpawn()

            if this.allSlotsEmpty() and this.activeOnMap <= 0 then
                call this.finish()
            endif
        endmethod

        //==================================================
        method finish takes nothing returns nothing
            call PauseTimer(this.loopTimer)
            call ReleaseTimer(this.loopTimer)
            call WaveByTimer.remove(GetHandleId(this.loopTimer))
            call BJDebugMsg("Wave terminada")
        endmethod
    endstruct

    //==================================================
    // Trigger de muerte
    //==================================================
    private function OnUnitDeath takes nothing returns nothing
        local unit u = GetDyingUnit()
        local integer hid = GetHandleId(u)
        local Wave w
        local WaveSlot s
        local integer pid

        if WaveByUnit.has(hid) then

            // slot dueño
            set w = Wave(WaveByUnit[hid])
            set s = WaveSlot(SlotByUnit[hid])


            set pid = GetPlayerId(s.owner)

            set w.activeByPlayer[pid] = w.activeByPlayer[pid] - 1
            set s.active = s.active - 1
            set w.activeOnMap = w.activeOnMap - 1

            call WaveByUnit.remove(hid)
            call SlotByUnit.remove(hid)
        endif

        set u = null
    endfunction

    //==================================================
    // Init
    //==================================================
    private function Init takes nothing returns nothing
        local trigger t = CreateTrigger()
        local integer i = 0
        local Wave w

        set WaveByUnit = Table.create()
        set WaveByTimer = Table.create()
        set SlotByUnit = Table.create()

        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
            set i = i + 1
        endloop

        call TriggerAddAction(t, function OnUnitDeath)
        /* Wave.create(globalLimit, interval)
           w.addSlot(unitId, count, slotLimit, player) */ 
        set w = Wave.create(3, 50, 1.00)
        call w.addPoint(0.0, 0.0)
        call w.addPoint(512.0, 0.0)
        call w.addPoint(0.0, 512.0)
        call w.addPoint(512.0, 512.0)
        call w.addNearUnit(gg_unit_hfoo_0013)

        call w.addSlot('hpea', 8, 2, 1, Player(11))
        call w.addSlot('ewsp', 8, 3, 1, Player(11))
        call w.addSlot('ewsp', 4, 3, 2, Player(10))
        call w.start()
    endfunction 

endlibrary
