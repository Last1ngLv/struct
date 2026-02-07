
library WaveTest initializer Init /*

    */requires Table,/*
    */TimerUtils 
    /*
    # Wave System Documentation

    ## Overview

    The **Wave System** is a modular, instance-based enemy spawning framework for Warcraft III (vJASS).

    It supports:

    * Multiple simultaneous wave instances
    * Per-player spawn limits
    * Slot-based unit definitions
    * Boss vs normal units
    * Priority-based spawning
    * Kill-gated spawns
    * Spawn points and near-unit spawning
    * Delayed spawn effects (FX In / FX Out)
    * External unit registration (summons, invocations)
    * Multiboard title integration via ExecuteFunc
    * Clean destruction and memory safety

    The system is designed as a **core engine**, decoupled from UI and gameplay logic.

    ---

    ## Core Concepts

    ### Wave

    A `Wave` represents **one independent spawning instance**.

    Each wave owns:

    * Its own timer
    * Its own slots
    * Its own counters
    * Its own multiboard context

    Multiple waves can run at the same time without interfering with each other.

    ---

    ### WaveSlot

    A `WaveSlot` defines **what** can be spawned.

    Each slot represents:

    * A unit type
    * An owner (player)
    * How many units can spawn
    * How many can be active at once
    * Priority and gating rules

    Slots do **not** spawn by themselves; they are selected by the Wave scheduler.

    ---

    ## Creating a Wave

    ```jass
    set w = Wave.create(
        perPlayerLimit,     // max active units per player
        nearUnitChance,     // % chance to spawn near a unit
        interval,           // spawn tick interval
        multiboard,         // optional (null allowed)
        titleFuncName,      // string for ExecuteFunc ("" allowed)
        waveIndex,          // current wave number
        waveTotal           // total waves
    )
    ```

    ### Notes

    * If `multiboard == null`, no UI is created or updated
    * `titleFuncName` must be a global function name (string)
    * `nearUnitChance` is 0–100

    ---

    ## Adding Spawn Points

    ```jass
    call w.addPoint(x, y)
    ```

    * Points are stored internally as `real` arrays
    * Used as fallback when near-unit spawning fails
    * No `location` handles are used

    ---

    ## Adding Near Units

    ```jass
    call w.addNearUnit(unit)
    ```

    * These units are used as anchors for near-unit spawning
    * Spawn location is validated for walkability

    ---

    ## Adding Slots

    ```jass
    call w.addSlot(
        unitId,     // rawcode
        amount,     // total to spawn
        slotLimit,  // max active from this slot
        priority,   // higher = spawned first
        fxId,       // FX index (0 = none)
        killGate,   // -1 = no gate, else required kills
        isBoss,     // true = boss unit
        player      // owner
    )
    ```

    ### Slot Rules

    * Higher priority slots are always selected first
    * Slots with the same priority are chosen randomly
    * `killGate` delays spawning until total kills drop below or equal to the value

    ---

    ## Starting the Wave

    ```jass
    call w.start()
    ```

    This:

    * Creates the internal timer
    * Begins periodic spawning

    ---

    ## External Unit Registration

    Used for summons or units created outside the wave system.

    ```jass
    call registerExternalUnit(sourceUnit, summonedUnit, isBoss)
    ```

    ### Rules

    * The `sourceUnit` **must already belong to a wave**
    * The summoned unit inherits the same wave
    * External units are counted in all relevant counters

    If the source unit does not belong to a wave, the call is ignored.

    ---

    ## Counters (Wave API)

    Each wave maintains live counters usable by UI systems:

    ### Wave Progress

    * `waveIndex`
    * `waveTotal`

    ### Spawn Tracking

    * `totalToSpawn`
    * `remainingToSpawn`

    ### Units

    * `totalUnits`
    * `remainingUnits`
    * `activeUnits`
    * `totalKilledUnits`

    ### Bosses

    * `totalBosses`
    * `remainingBosses`
    * `activeBosses`
    * `totalKilledBoss`

    ### Global

    * `activeOnMap`
    * `totalKilled`

    All counters are automatically updated on spawn and death.

    ---

    ## Multiboard Integration

    ### Design

    * The Wave system **does not own UI logic**
    * It only provides data and execution context

    ### How it Works

    1. A multiboard is passed during `Wave.create`
    2. A function name (string) is stored
    3. On each tick and unit death:

    ```jass
    set CurrentBoardContext = w.board
    call ExecuteFunc(w.titleFunc)
    set CurrentBoardContext = null
    ```

    The called function retrieves the wave using:

    * `CurrentBoardContext`
    * `WaveByBoard[GetHandleId(board)]`

    This allows fully custom board designs.

    ---

    ## Wave Completion

    A wave finishes automatically when:

    * All slots are empty
    * `activeOnMap == 0`

    ```jass
    call w.finish()
    ```

    Internally this triggers destruction.

    ---

    ## Cleanup and Destruction

    When a wave ends:

    * Timers are stopped and released
    * Slots are destroyed
    * Tables are cleaned
    * Multiboard references are removed
    * The wave instance is destroyed

    No global state leaks.

    ---

    ## Design Principles

    * Instance-based (no globals for state)
    * Explicit APIs (no hidden magic)
    * Deterministic behavior
    * UI-decoupled
    * Multiplayer-safe
    * Scales to complex boss logic

    ---

    ## Typical Usage Flow

    1. Create wave
    2. Add points / near units
    3. Add slots
    4. Start wave
    5. (Optional) register external units
    6. Wave auto-finishes and cleans itself

    ---

    ## Future Implementations

    * Pause / Resume
    * Phase-based waves
    * Difficulty scaling
    * Save/Load wave state
    * Debug visualizers

    ---

    **This system is intended to be reused as a foundation for advanced PvE maps.** 
    
    Usage Examples

    Example 1: Basic Wave (no multiboard)
    local Wave w


    set w = Wave.create(3, 1.00, null, 0, 0)
    call w.addSlot('ewsp', 10, 3, Player(10), false, -1)
    call w.addSlot('ewsp', 10, 3, Player(11), false, -1)
    call w.start()
    Example 2: Wave with Bosses
    local Wave w


    set w = Wave.create(4, 1.25, "WaveBoard_Update", 2, 10)
    call w.addSlot('hfoo', 15, 5, Player(11), false, -1) // normal units
    call w.addSlot('Ogrh', 2, 1, Player(11), true, -1)   // bosses
    call w.start()
    Example 3: Kill-Gated Spawn (unlock after 10 kills)
    call w.addSlot('hfoo', 20, 4, Player(11), false, 10)

    Units from this slot will only start spawning once w.totalKilled >= 10.

    Example 4: Spawn Near Units (probabilistic)
    set w = Wave.create(3, 1.00, "WaveBoard_Update", 1, 5)
    call w.addSpawnPoint(0.0, 0.0)
    call w.addSpawnPoint(512.0, 256.0)
    call w.addUnitXY(casterUnit)

    If spawnNearChance > 0, the system will attempt to spawn near registered units.

    Example 5: Register External / Summoned Units
    call w.registerExternalUnit(u)

    This makes the unit part of:

    activeOnMap

    kill counters

    multiboard stats

    Example 6: Multiboard Update Function
    function WaveBoard_Update takes nothing returns nothing
        local Wave w = Wave(WaveBoardContext)
        call MultiboardSetTitleText(w.board, w.getBoardTitle())
    endfunction

    The system calls this via ExecuteFunc when state changes.

    Example 7: Query API (for UI or logic)
    call BJDebugMsg(I2S(w.getRemainingUnits()))
    call BJDebugMsg(I2S(w.getRemainingBosses()))
    call BJDebugMsg(I2S(w.getActiveOnMap()))

    These examples cover 90% of practical use cases. More advanced patterns (phases, scaling, chaining waves) can be built on top without modifying the core system. */


    globals
        Table WaveByUnit
        Table WaveByTimer
        Table SlotByUnit
        Table WaveByBoard
        Table ExternalIsBoss

        constant integer FX_MAX = 19
        string array FX_UnitIn
        string array FX_UnitOut

        multiboard CurrentBoardContext
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
        integer total
        boolean isBoss
        integer killGate
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

        multiboard board
        string titleFunc

        // --- Referenciales ---
        integer waveIndex
        integer waveTotal

        // --- Totales ---
        integer totalToSpawn

        integer totalUnits
        integer totalBosses

        // --- Dinámicos ---
        integer remainingToSpawn
        
        integer remainingUnits
        integer remainingBosses

        integer activeBosses
        integer activeUnits

        integer totalKilled
        
        integer totalKilledUnits
        integer totalKilledBoss

        static method create takes integer PlayerLim, integer nearChance, real sec, multiboard mb, string titleFunc, integer wIndex, integer wTotal returns Wave 
            local Wave this = Wave.allocate()
            local integer i = 0

            if mb != null then
                set this.board = mb
                set WaveByBoard[GetHandleId(mb)] = this
                set this.titleFunc  = titleFunc
                set this.waveIndex  = wIndex
                set this.waveTotal  = wTotal
            else
                set this.board = null
            endif

            set this.pointCount = 0
            set this.nearUnitChance = nearChance
            set this.nearUnitCount  = 0
            set this.slotCount = 0
            set this.activeOnMap = 0
            set this.perPlayerLimit = PlayerLim
            set this.interval  = sec

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


            loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                set this.activeByPlayer[i] = 0
                set i = i + 1
            endloop

            return this
        endmethod

        // Agregar un tipo de unidad
        method addSlot takes integer uId, integer amount, integer lim, integer prio, integer fxId, integer killGate, boolean isBoss, player p returns nothing  
            local WaveSlot s = WaveSlot.create()

            set s.unitId    = uId
            set s.remaining = amount
            set s.active    = 0
            set s.limit     = lim
            set s.owner     = p
            set s.priority = prio
            set s.fxId = fxId
            set s.killGate  = killGate

            set s.total     = amount
            
            set s.isBoss    = isBoss

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

        method registerExternalUnit takes unit source, unit summoned, boolean isBoss returns nothing
            local integer srcId = GetHandleId(source)
            local integer uId   = GetHandleId(summoned)
            local Wave w

            // El invocador NO pertenece a ninguna wave → ignorar
            if not WaveByUnit.has(srcId) then
                return
            endif

            set w = Wave(WaveByUnit[srcId])

            // Seguridad extra: no doble registro
            if WaveByUnit.has(uId) then
                return
            endif

            set WaveByUnit[uId] = w

            set w.activeOnMap = w.activeOnMap + 1
            set w.totalToSpawn = w.totalToSpawn + 1
            set w.totalKilled = w.totalKilled + 1

            if isBoss then
                //set w.remainingBosses = w.remainingBosses + 1
                set w.totalBosses = w.totalBosses + 1
                set ExternalIsBoss[uId] = 1
                set w.totalKilledBoss = w.totalKilledBoss + 1
                set w.activeBosses    = w.activeBosses + 1
            else
                //set w.remainingUnits = w.remainingUnits + 1
                set w.totalUnits = w.totalUnits + 1
                set ExternalIsBoss[uId] = 0
                set w.totalKilledUnits = w.totalKilledUnits + 1
                set w.activeUnits    = w.activeUnits + 1
            endif
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
                    if s.killGate == -1 or this.totalKilled <= s.killGate then
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

                if s.priority == maxPrio and s.remaining > 0 and s.active < s.limit and this.activeByPlayer[pid] < this.perPlayerLimit then
                    if s.killGate == -1 or this.totalKilled <= s.killGate then
                        set validCount = validCount + 1
                    endif
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
                    if s.killGate == -1 or this.totalKilled <= s.killGate then
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

            if this.board != null and this.titleFunc != "" then
                set CurrentBoardContext = this.board
                call ExecuteFunc(this.titleFunc)
                set CurrentBoardContext = null
            endif

            if this.allSlotsEmpty() and this.activeOnMap <= 0 then
                call this.finish()
            endif
        endmethod

        //==================================================
        method finish takes nothing returns nothing
            call this.destroyWave()
        endmethod

        method destroyWave takes nothing returns nothing
            local integer i = 0

            // Timer
            if this.loopTimer != null then
                call PauseTimer(this.loopTimer)
                call ReleaseTimer(this.loopTimer)
                call WaveByTimer.remove(GetHandleId(this.loopTimer))
                set this.loopTimer = null
            endif

            // Multiboard
            if this.board != null then
                call WaveByBoard.remove(GetHandleId(this.board))
                set this.board = null
                set this.titleFunc = ""
            endif

            // Slots
            loop
                exitwhen i >= this.slotCount
                call this.slots[i].destroy()
                set this.slots[i] = 0
                set i = i + 1
            endloop

            call BJDebugMsg("Wave destroyed")

            call this.destroy()
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
            set w.activeOnMap = w.activeOnMap - 1

            set w.activeByPlayer[pid] = w.activeByPlayer[pid] - 1
            set w.totalKilled = w.totalKilled - 1
            
            if SlotByUnit.has(hid) then
                set s.active = s.active - 1
                if s.isBoss then
                    set w.activeBosses = w.activeBosses - 1
                    set w.totalKilledBoss = w.totalKilledBoss - 1
                else
                    set w.activeUnits = w.activeUnits - 1
                    set w.totalKilledUnits = w.totalKilledUnits - 1
                endif
            elseif ExternalIsBoss.has(hid) then
                if ExternalIsBoss[hid] == 1 then 
                    set w.activeBosses = w.activeBosses - 1
                    set w.totalKilledBoss = w.totalKilledBoss - 1
                else                   
                    set w.activeUnits = w.activeUnits - 1
                    set w.totalKilledUnits = w.totalKilledUnits - 1
                endif
            endif

            if w.board != null and w.titleFunc != "" then
                set CurrentBoardContext = w.board
                call ExecuteFunc(w.titleFunc)
                set CurrentBoardContext = null
            endif

            call WaveByUnit.remove(hid)
            call SlotByUnit.remove(hid)
        endif

        set u = null
    endfunction

    function registerExternalUnit takes unit source, unit summoned, boolean isBoss returns nothing
            local integer srcId = GetHandleId(source)
            local integer uId   = GetHandleId(summoned)
            local Wave w

            // El invocador NO pertenece a ninguna wave → ignorar
            if not WaveByUnit.has(srcId) then
                return
            endif

            set w = Wave(WaveByUnit[srcId])

            // Seguridad extra: no doble registro
            if WaveByUnit.has(uId) then
                return
            endif

            set WaveByUnit[uId] = w

            set w.activeOnMap = w.activeOnMap + 1
            set w.totalToSpawn = w.totalToSpawn + 1
            set w.totalKilled = w.totalKilled + 1

            if isBoss then
                //set w.remainingBosses = w.remainingBosses + 1
                set w.totalBosses = w.totalBosses + 1
                set ExternalIsBoss[uId] = 1
                set w.totalKilledBoss = w.totalKilledBoss + 1
                set w.activeBosses    = w.activeBosses + 1
            else
                //set w.remainingUnits = w.remainingUnits + 1
                set w.totalUnits = w.totalUnits + 1
                set ExternalIsBoss[uId] = 0
                set w.totalKilledUnits = w.totalKilledUnits + 1
                set w.activeUnits    = w.activeUnits + 1
            endif
            if w.board != null and w.titleFunc != "" then
                set CurrentBoardContext = w.board
                call ExecuteFunc(w.titleFunc)
                set CurrentBoardContext = null
            endif
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
        call InitFX()

        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
            set i = i + 1
        endloop

        call TriggerAddAction(t, function OnUnitDeath)
    endfunction 
endlibrary
