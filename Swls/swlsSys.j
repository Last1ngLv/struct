
library WaveTest initializer Init /*

    */requires Table,/*
    */TimerUtils 

    globals
        Table WaveByUnit
        Table WaveByTimer
        Table SlotByUnit

        constant integer FX_MAX = 19
        string array FX_UnitIn
        string array FX_UnitOut
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
    // Spawn
    //==================================================
    function PendingSpawn_execute takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local PendingSpawn ps = GetTimerData(t)
            local unit u

            set u = CreateUnit(ps.slot.owner, ps.slot.unitId, ps.x, ps.y, 270.0)
            call DestroyEffect(AddSpecialEffectTarget(FX_UnitOut[ps.slot.fxId], u, "origin"))

            set SlotByUnit[GetHandleId(u)] = ps.slot
            set WaveByUnit[GetHandleId(u)] = ps.wave

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
        player owner
    endstruct

    struct PendingSpawn
        Wave wave
        WaveSlot slot
        integer pid
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
        method addSlot takes integer uId, integer amount, integer lim, integer prio, integer fxId, player p returns nothing
            local WaveSlot s = WaveSlot.create()

            set s.unitId    = uId
            set s.remaining = amount
            set s.active    = 0
            set s.limit     = lim
            set s.owner     = p
            set s.priority = prio
            set s.fxId = fxId

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
            local integer pid
            local PendingSpawn ps
            
            set s = this.pickSlot()

            if s == 0 then
                //call BJDebugMsg("No Spawn")
                return 
            endif

            if not this.selectSpawnPoint(256.0) then
                return
            endif

            set pid = GetPlayerId(s.owner)

            //set u = CreateUnit(s.owner, s.unitId, this.spawnX, this.spawnY, 270.0)
            //call BJDebugMsg("Spawn " + I2S(s.unitId) + " P" + I2S(pid))

            //set SlotByUnit[GetHandleId(u)] = s
            //set WaveByUnit[GetHandleId(u)] = this

            set this.activeByPlayer[pid] = this.activeByPlayer[pid] + 1
            set s.remaining              = s.remaining - 1
            set s.active                 = s.active + 1
            set this.activeOnMap         = this.activeOnMap + 1

            // 2. Crear pending spawn
            set ps = PendingSpawn.create()
            set ps.wave = this
            set ps.slot = s
            set ps.pid  = pid
            set ps.x    = this.spawnX
            set ps.y    = this.spawnY

            if s.fxId > 0 and s.fxId <= FX_MAX then
                call DestroyEffect(AddSpecialEffect(FX_UnitIn[s.fxId], ps.x, ps.y))
            endif

            // 4. Timer de spawn real
            set ps.t = NewTimer()
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

    function InitFX takes nothing returns nothing
        // 1. Teletransporte masivo humano
        set FX_UnitIn[1]  = "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl"
        set FX_UnitOut[1] = "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl"
        // 2. Resurrección humana
        set FX_UnitIn[2]  = "Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl"
        set FX_UnitOut[2] = "Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl"
        // 3. Animar muerto no-muerto
        set FX_UnitIn[3]  = "Abilities\\Spells\\Undead\\CarrionSwarm\\CarrionSwarmDamage.mdl"
        set FX_UnitOut[3] = "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl"
        // 4. Artefacto especial (AIil)
        set FX_UnitIn[4]  = "Abilities\\Spells\\Items\\AIil\\AIilTarget.mdl"
        set FX_UnitOut[4] = "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl"
        // 5. Disipación no-muerto
        set FX_UnitIn[5]  = "Objects\\Spawnmodels\\Undead\\UndeadDissipate\\UndeadDissipate.mdl"
        set FX_UnitOut[5] = "Abilities\\Spells\\Human\\MarkOfChaos\\MarkOfChaosDone.mdl"
        // 6. Purificación de objeto
        set FX_UnitIn[6]  = "Abilities\\Spells\\Items\\StaffOfPurification\\PurificationCaster.mdl"
        set FX_UnitOut[6] = "Abilities\\Spells\\Items\\StaffOfPurification\\PurificationTarget.mdl"
        // 7. Invocar esqueleto guerrero
        set FX_UnitIn[7]  = "Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl"
        set FX_UnitOut[7] = "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl"
        // 8.  / batalla
        set FX_UnitIn[8]  = "Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl"
        set FX_UnitOut[8] = "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl"
        // 9. Ola aplastante / daño
        set FX_UnitIn[9]  = "Abilities\\Spells\\Other\\CrushingWave\\CrushingWaveDamage.mdl"
        set FX_UnitOut[9] = "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl"
        // 10. Disipación / cancelación no-muerto
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
        // 18. Control mágico
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

        call InitFX()
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

        call w.addSlot('hpea', 8, 2, 1, 3, Player(11))
        call w.addSlot('ewsp', 8, 3, 1, 9, Player(11))
        call w.addSlot('ewsp', 4, 3, 2, 2, Player(10))
        call w.start()
    endfunction 

endlibrary
