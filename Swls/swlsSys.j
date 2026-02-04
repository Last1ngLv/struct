
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

        static method create takes integer PlayerLim, real sec returns Wave
            local Wave this = Wave.allocate()
            local integer i = 0

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
        method addSlot takes integer uId, integer amount, integer lim, player p returns nothing
            local WaveSlot s = WaveSlot.create()

            set s.unitId    = uId
            set s.remaining = amount
            set s.active    = 0
            set s.limit     = lim
            set s.owner     = p

            set this.slots[this.slotCount] = s
            set this.slotCount = this.slotCount + 1
        endmethod

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

            // 1. Contar slots válidos
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    set validCount = validCount + 1
                endif

                set i = i + 1
            endloop
            call BJDebugMsg("xxcxx")
            call BJDebugMsg(I2S(validCount))

            if validCount == 0 then
                return 0
            endif

            // 2. Elegir random
            set pick = GetRandomInt(1, validCount)

            // 3. Buscar el slot elegido
            set i = 0
            loop
                exitwhen i >= this.slotCount
                set s = this.slots[i]
                set pid = GetPlayerId(s.owner)

                if s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
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

            set s = this.pickSlot()

            if s == 0 then
                //call BJDebugMsg("No Spawn")
                return 
            endif

            set pid = GetPlayerId(s.owner)

            set u = CreateUnit(s.owner, s.unitId, 0.0, 0.0, 270.0)

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
        set w = Wave.create(3, 1.00)
        call w.addSlot('ewsp', 8, 2, Player(11))
        call w.addSlot('ewsp', 8, 3, Player(10))
        call w.start()
    endfunction 

endlibrary
