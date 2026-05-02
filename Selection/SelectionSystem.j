library SelectionSystem requires PlayerUtils, PlayerHeroState, InitialWaveMultiboard, SelectionElementConfig, SelectionHeroVisualConfig, SelectionHeroConfig, SelectionHeroSpawn, SelectionStartFlow

globals
    private constant real SELECTION_PHASE_TIMEOUT = 10.0
    private constant integer SELECTION_PHASE_NONE = 0
    private constant integer SELECTION_PHASE_HERO = 1

    private dialog array heroDialog

    private button array heroButton

    private integer array heroChoice
    private boolean array heroChosen
    private boolean array finished
    private integer totalFinished = 0
    private trigger dialogTrig = null
    private timer selectionTimer = null
    private integer selectionPhase = SELECTION_PHASE_NONE
endglobals

struct SelectionSystem

    private static method executeElement takes User u returns nothing
        call SelectionSetupElement(SelectionGetHeroProjectileElementId(heroChoice[u.id]), u.toPlayer(), PlayerHero[u.id])
        call SelectionSetupHeroVisual(heroChoice[u.id], u.toPlayer())
    endmethod

    private static method finishSelection takes User u returns nothing
        if finished[u.id] then
            return
        endif
        call SelectionEnsureHeroCreated(u, heroChoice[u.id])
        call DialogDisplay(u.toPlayer(), heroDialog[u.id], false)
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
            if not heroChosen[u.id] then
                call DialogDisplay(u.toPlayer(), heroDialog[u.id], true)
            endif
            set i = i + 1
        endloop

        call TimerStart(selectionTimer, SELECTION_PHASE_TIMEOUT, false, function thistype.onHeroTimeout)
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
            if heroChosen[u.id] and not finished[u.id] then
                call thistype.finishSelection(u)
            endif
            set i = i + 1
        endloop
    endmethod

    private static method onHeroTimeout takes nothing returns nothing
        call thistype.randomizeMissingHeroes()
        call thistype.checkAllFinished()
    endmethod

    private static method checkAllFinished takes nothing returns nothing
        if selectionPhase != SELECTION_PHASE_NONE and totalFinished >= User.AmountPlaying then
            set selectionPhase = SELECTION_PHASE_NONE
            call PauseTimer(selectionTimer)
            call thistype.onAllSelected()
        endif
    endmethod

    static method onAllSelected takes nothing returns nothing
        call SelectionStartGameAfterAllSelected()
    endmethod

    private static method onClick takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local User u = User[p]
        local integer i = 0
        local integer index

        loop
            exitwhen i == 6
            set index = u.id*6 + i

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

    private static method createDialogs takes nothing returns nothing
        local integer i = 0
        local User u
        local integer index

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)

            set heroDialog[u.id] = DialogCreate()
            call DialogSetMessage(heroDialog[u.id], "Elige tu heroe")
            set index = u.id*6
            set heroButton[index+0] = DialogAddButton(heroDialog[u.id], "Kael", 0)
            set heroButton[index+1] = DialogAddButton(heroDialog[u.id], "Military", 0)
            set heroButton[index+2] = DialogAddButton(heroDialog[u.id], "Lob", 0)
            set heroButton[index+3] = DialogAddButton(heroDialog[u.id], "Yetix", 0)
            set heroButton[index+4] = DialogAddButton(heroDialog[u.id], "Shinigami", 0)
            set heroButton[index+5] = DialogAddButton(heroDialog[u.id], "Yoshi", 0)
            call DialogDisplay(u.toPlayer(), heroDialog[u.id], false)

            set i = i + 1
        endloop
    endmethod

    static method start takes nothing returns nothing
        local integer i = 0
        local User u

        call thistype.createDialogs()
        call ShowInitialWaveMultiboard()
        set selectionPhase = SELECTION_PHASE_HERO

        if selectionTimer == null then
            set selectionTimer = CreateTimer()
        endif

        set dialogTrig = CreateTrigger()
        call TriggerAddAction(dialogTrig, function thistype.onClick)

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)

            call TriggerRegisterDialogEvent(dialogTrig, heroDialog[u.id])
            call DialogDisplay(u.toPlayer(), heroDialog[u.id], true)

            set i = i + 1
        endloop

        call TimerStart(selectionTimer, SELECTION_PHASE_TIMEOUT, false, function thistype.onHeroTimeout)
    endmethod

endstruct

endlibrary
