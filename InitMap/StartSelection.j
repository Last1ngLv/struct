library SelectionSystem requires PlayerUtils, PlayerMissileLoadout, OrderSmartChannel, Camera, MenuClient, HeroLives, TheEnd, PreConfi

globals
/*
    private constant real SPAWN_X = -29825.
    private constant real SPAWN_Y = 28665.
*/
/*
    private constant real SPAWN_X = -26400.
    private constant real SPAWN_Y = 14208.
*/

    private constant real SPAWN_X = -1536.
    private constant real SPAWN_Y = 24064.


    private constant real START_DELAY = 10.0
    private constant real SELECTION_PHASE_TIMEOUT = 10.0
    private constant integer SELECTION_PHASE_NONE = 0
    private constant integer SELECTION_PHASE_ELEMENT = 1
    private constant integer SELECTION_PHASE_HERO = 2

    private dialog array heroDialog
    private dialog array elementDialog

    private button array heroButton
    private button array elementButton

    private integer array heroChoice
    private integer array elementChoice
    private boolean array heroChosen
    private boolean array elementChosen
    private boolean array finished
    private integer totalElementChosen = 0
    private integer totalFinished = 0
    private trigger dialogTrig = null
    private timer selectionTimer = null
    private integer selectionPhase = SELECTION_PHASE_NONE
    unit array PlayerHero
    Camera array PlayerCamera
endglobals

struct SelectionSystem

//==================================================
// HERO UNIT IDS
//==================================================

    private static method getHeroUnitId takes integer index returns integer
        if index == 0 then
            return 'H01A'
        elseif index == 1 then
            return 'H001'
        elseif index == 2 then
            return 'H005'
        elseif index == 3 then
            return 'H006'
        elseif index == 4 then
            return 'H009'
        endif
        return 'H007'
    endmethod

//==================================================
// ELEMENT CONFIG
//==================================================

    private static method setupElement takes integer elementId, player p, unit hero returns nothing
        local integer abilityId
        local real speed
        local real damage
        local integer instances
        local string model
        local string overlay
        local string impactFx
        local string casterFx1 = ""
        local string casterFx2 = ""

        if elementId == 0 then
            set abilityId = 'AM05'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Blue.mdx"
            set overlay = "Miss\\Shot II Blue.mdx"
            set impactFx = "Flamestrike Mystic II.mdx"
            set casterFx1 = "Miss\\Windwalk Blue Soul.mdx"
            set casterFx2 = "Miss\\Valiant Charge Royal.mdx"
        elseif elementId == 1 then
            set abilityId = 'AM03'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Purple.mdx"
            set overlay = "Miss\\Shot II Purple.mdx"
            set impactFx = "Flamestrike Dark Void II.mdx"
            set casterFx1 = "Miss\\Windwalk.mdx"
            set casterFx2 = "Miss\\Valiant Charge Void.mdx"
        elseif elementId == 2 then
            set abilityId = 'AM01'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Red.mdx"
            set overlay = "Miss\\Shot II Red.mdx"
            set impactFx = "Flamestrike Blood II.mdx"
            set casterFx1 = "Miss\\Windwalk Blood.mdx"
            set casterFx2 = "Miss\\Valiant Charge.mdx"
        elseif elementId == 3 then
            set abilityId = 'AM06'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Yellow.mdx"
            set overlay = "Miss\\Shot II Yellow.mdx"
            set impactFx = "Flamestrike Fel II.mdx"
            set casterFx1 = "Miss\\Windwalk.mdx"
            set casterFx2 = "Miss\\Valiant Charge Holy.mdx"
        elseif elementId == 4 then
            set abilityId = 'AM02'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Green.mdx"
            set overlay = "Miss\\Shot II Green.mdx"
            set impactFx = "Flamestrike Nature II.mdx"
            set casterFx1 = "Miss\\Windwalk Necro Soul.mdx"
            set casterFx2 = "Miss\\Valiant Charge Fel.mdx"
        else
            set abilityId = 'AM04'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Orange.mdx"
            set overlay = "Miss\\Shot II Orange.mdx"
            set impactFx = "Flamestrike II.mdx"
            set casterFx1 = "Miss\\Windwalk Fire.mdx"
            set casterFx2 = "Miss\\Valiant Charge.mdx"
        endif

        call UnitAddAbility(hero, abilityId)
        call SetPlayerLeapCasterFx(p, casterFx1, casterFx2)
        call SetPlayerMissileLoadout(p, abilityId, speed, damage, instances, model, overlay)
        call SetPlayerLeapImpactFx(p, impactFx)
    endmethod

//==================================================
// HERO VISUAL CONFIG
//==================================================

    private static method setupHeroVisual takes integer heroId, player p returns nothing
        local string dummyFx1 = ""
        local string dummyFx2 = ""
        local real dummyScale = .1
        local real dummyOffset = 0.
        local integer companionId = 'dumi'
        local User u = User[p]

        if heroId == 0 then
            //set dummyFx1 = "units\\human\\phoenix\\phoenix.mdl"
            set dummyScale = 1.25
            //set dummyOffset = -400.00
        elseif heroId == 1 then
            //set dummyFx1 = "units\\human\\GryphonRider\\GryphonRider.mdl"
            set dummyScale = 1.25
            //set dummyOffset = -400.
        elseif heroId == 2 then
            //set dummyFx1 = "units\\orc\\WyvernRider\\WyvernRider.mdl"
            set dummyScale = 1.25
            //set dummyOffset = -400.
        elseif heroId == 3 then
            //set dummyFx1 = "units\\undead\\FrostWyrm\\FrostWyrm.mdl"
            set dummyScale = 1.25
            //set dummyOffset = -400.
        elseif heroId == 4 then
            //set dummyFx1 = "units\\creeps\\NetherDragon\\NetherDragon.mdl"
            set dummyScale = 1.25
            //set dummyOffset = -400.
        elseif heroId == 5 then
            //set dummyFx1 = "Firebolt Rough Major.mdx"
            set dummyScale = 1.25
            //set dummyOffset = -400.00
        endif

        call SetPlayerLeapDummyFx(p, dummyFx1, dummyFx2)
        call SetPlayerLeapDummyScale(p, dummyScale)
        call SetPlayerLeapDummyFlightOffset(p, dummyOffset)
        
        call SetPlayerOrbLevel(p, 1)
        call SetPlayerMissileHealOnHit(p, 0.00)
        call SetPlayerPointsOfMana(p, 1)
        call SetPlayerMissileDamageValue(p, 0.50)
        call SetPlayerMissileUseRapidFire(p,true)

    endmethod

//==================================================
// APPLY FINAL CONFIG
//==================================================

    private static method executeElement takes User u returns nothing
        local integer e = elementChoice[u.id]
        local integer h = heroChoice[u.id]
        local unit hero = PlayerHero[u.id]
        local player p = u.toPlayer()

        call thistype.setupElement(e, p, hero)
        call thistype.setupHeroVisual(h, p)
    endmethod

    private static method createClients takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]

            if hero != null and GetUnitTypeId(hero) != 0 then
                if Client[hero] == 0 then
                    set client = Client.create(hero)
                else
                    set client = Client[hero]
                endif
            endif

            set i = i + 1
        endloop
    endmethod

    private static method showClients takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]

            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]

                if client != 0 and PlayerCamera[u.id] != 0 then
                    call client.show(true, PlayerCamera[u.id])
                endif

                if (User.Local == u.handle) then
                    call SelectUnit(hero, true)
                    call PanCameraToTimed(GetUnitX(hero), GetUnitY(hero), 0)
                endif
            endif

            set i = i + 1
        endloop
    endmethod

    private static method ensureHeroCreated takes User u returns nothing
        local player p = u.toPlayer()
        if PlayerHero[u.id] != null and GetUnitTypeId(PlayerHero[u.id]) != 0 then
            return
        endif
        set PlayerHero[u.id] = CreateUnit(p, thistype.getHeroUnitId(heroChoice[u.id]), SPAWN_X, SPAWN_Y, 270.)
        call SILENCE_TESTUNIT_AMOV(PlayerHero[u.id])
        call HeroLivesInitHero(u.id, PlayerHero[u.id])

        if PlayerCamera[u.id] == 0 then
            set PlayerCamera[u.id] = Camera.create()
        endif

        call SetPlayerAllianceStateBJ(Player(bj_PLAYER_NEUTRAL_EXTRA), u.handle, bj_ALLIANCE_ALLIED_VISION)
        call SetPlayerAllianceStateBJ(u.handle, Player(bj_PLAYER_NEUTRAL_EXTRA), bj_ALLIANCE_ALLIED_VISION)
    endmethod

    private static method finishSelection takes User u returns nothing
        if finished[u.id] then
            return
        endif
        call thistype.ensureHeroCreated(u)
        call DialogDisplay(u.toPlayer(), heroDialog[u.id], false)
        call DialogDisplay(u.toPlayer(), elementDialog[u.id], false)
        call thistype.executeElement(u)
        set finished[u.id] = true
        set totalFinished = totalFinished + 1
    endmethod

    private static method startHeroPhase takes nothing returns nothing
        local integer i = 0
        local User u

        set selectionPhase = SELECTION_PHASE_HERO
        if selectionTimer == null then
            set selectionTimer = CreateTimer()
        endif

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            call DialogDisplay(u.toPlayer(), elementDialog[u.id], false)
            if not heroChosen[u.id] then
                call DialogDisplay(u.toPlayer(), heroDialog[u.id], true)
            endif
            set i = i + 1
        endloop

        call TimerStart(selectionTimer, SELECTION_PHASE_TIMEOUT, false, function thistype.onHeroTimeout)
    endmethod

    private static method checkAllElementsChosen takes nothing returns nothing
        if totalElementChosen >= User.AmountPlaying then
            call PauseTimer(selectionTimer)
            call thistype.startHeroPhase()
        endif
    endmethod

    private static method randomizeMissingElements takes nothing returns nothing
        local integer i = 0
        local User u
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            if not elementChosen[u.id] then
                set elementChoice[u.id] = GetRandomInt(0, 5)
                set elementChosen[u.id] = true
                set totalElementChosen = totalElementChosen + 1
            endif
            set i = i + 1
        endloop
    endmethod

    private static method randomizeMissingHeroes takes nothing returns nothing
        local integer i = 0
        local User u
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            if not heroChosen[u.id] then
                set heroChoice[u.id] = GetRandomInt(0, 5)
                set heroChosen[u.id] = true
            endif
            if heroChosen[u.id] and elementChosen[u.id] and not finished[u.id] then
                call thistype.finishSelection(u)
            endif
            set i = i + 1
        endloop
    endmethod

    private static method onElementTimeout takes nothing returns nothing
        call thistype.randomizeMissingElements()
        call thistype.startHeroPhase()
    endmethod

    private static method onHeroTimeout takes nothing returns nothing
        call thistype.randomizeMissingHeroes()
        call thistype.checkAllFinished()
    endmethod

//==================================================
// CHECK ALL
//==================================================

    private static method checkAllFinished takes nothing returns nothing
        if selectionPhase != SELECTION_PHASE_NONE and totalFinished >= User.AmountPlaying then
            set selectionPhase = SELECTION_PHASE_NONE
            call PauseTimer(selectionTimer)
            call thistype.onAllSelected()
        endif
    endmethod

    static method onAllSelected takes nothing returns nothing
        call thistype.createClients()
        call thistype.showClients()
        call ShowInitialWaveMultiboard()
        set WaveTgg = "Trig_w1_Actions"
        call StartInitialWaveCountdown()
    endmethod

//==================================================
// CLICK
//==================================================

    private static method onClick takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local User u = User[p]
        local integer i = 0
        local integer index

        loop
            exitwhen i == 6
            set index = u.id*6 + i

            if GetClickedButton() == elementButton[index] and selectionPhase == SELECTION_PHASE_ELEMENT then
                set elementChoice[u.id] = i
                call DialogDisplay(p, elementDialog[u.id], false)
                if not elementChosen[u.id] then
                    set elementChosen[u.id] = true
                    set totalElementChosen = totalElementChosen + 1
                endif
                call thistype.checkAllElementsChosen()
                return
            endif

            if GetClickedButton() == heroButton[index] and selectionPhase == SELECTION_PHASE_HERO then
                set heroChoice[u.id] = i
                set heroChosen[u.id] = true
                call thistype.finishSelection(u)
                call thistype.checkAllFinished()
                return
            endif

            set i = i + 1
        endloop
    endmethod

//==================================================
// CREATE DIALOGS
//==================================================

    private static method createDialogs takes nothing returns nothing
        local integer i = 0
        local User u
        local integer index

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)

            // HERO DIALOG
            set heroDialog[u.id] = DialogCreate()
            call DialogSetMessage(heroDialog[u.id], "Elige tu héroe")
            set index = u.id*6
            set heroButton[index+0] = DialogAddButton(heroDialog[u.id], "Kael", 0)
            set heroButton[index+1] = DialogAddButton(heroDialog[u.id], "Military", 0)
            set heroButton[index+2] = DialogAddButton(heroDialog[u.id], "Lob", 0)
            set heroButton[index+3] = DialogAddButton(heroDialog[u.id], "Yetix", 0)
            set heroButton[index+4] = DialogAddButton(heroDialog[u.id], "Shinigami", 0)
            set heroButton[index+5] = DialogAddButton(heroDialog[u.id], "Yoshi", 0)
            call DialogDisplay(u.toPlayer(), heroDialog[u.id], false)

            // ELEMENT DIALOG
            set elementDialog[u.id] = DialogCreate()
            call DialogSetMessage(elementDialog[u.id], "Elige tu elemento")
            set elementButton[index+0] = DialogAddButton(elementDialog[u.id], "Rayo", 0)
            set elementButton[index+1] = DialogAddButton(elementDialog[u.id], "Dark", 0)
            set elementButton[index+2] = DialogAddButton(elementDialog[u.id], "Blood", 0)
            set elementButton[index+3] = DialogAddButton(elementDialog[u.id], "Wind", 0)
            set elementButton[index+4] = DialogAddButton(elementDialog[u.id], "Venom", 0)
            set elementButton[index+5] = DialogAddButton(elementDialog[u.id], "Fire", 0)
            call DialogDisplay(u.toPlayer(), elementDialog[u.id], true)

            set i = i + 1
        endloop
    endmethod

//==================================================
// START
//==================================================

    static method start takes nothing returns nothing
        local integer i = 0
        local User u

        call thistype.createDialogs()
        call ShowInitialWaveMultiboard()
        set selectionPhase = SELECTION_PHASE_ELEMENT

        if selectionTimer == null then
            set selectionTimer = CreateTimer()
        endif

        set dialogTrig = CreateTrigger()
        call TriggerAddAction(dialogTrig, function thistype.onClick)

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)

            call TriggerRegisterDialogEvent(dialogTrig, heroDialog[u.id])
            call TriggerRegisterDialogEvent(dialogTrig, elementDialog[u.id])

            set i = i + 1
        endloop

        call TimerStart(selectionTimer, SELECTION_PHASE_TIMEOUT, false, function thistype.onElementTimeout)
    endmethod

endstruct

endlibrary
