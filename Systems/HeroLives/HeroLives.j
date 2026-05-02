library HeroLives initializer Init requires PlayerUtils, TimerUtils, PreConfi, PlayerHeroState, WeaponSelectionSystem, WeaponInventoryCore

    globals
        public constant integer HERO_LIVES_BASE = 10
        public constant real HERO_LIVES_REVIVE_DELAY = 1.50
        public constant real HERO_LIVES_INVULN_DURATION = 2.00
        public constant string HERO_LIVES_REVIVE_FX = "Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl"
        public constant string HERO_LIVES_INVULN_FX = "Abilities\\Spells\\Human\\DivineShield\\DivineShieldTarget.mdl"

        private integer array HeroLivesCurrent
        private integer array HeroLivesState
        private timer array HeroLivesTimer
        private effect array HeroLivesFx
        private real array HeroLivesDeathX
        private real array HeroLivesDeathY
        private trigger HeroLivesDeathTrigger = null
        private trigger HeroLivesLeaveTrigger = null
    endglobals

    private function HeroLivesIsTrackedPlayer takes integer pid returns boolean
        return pid >= 0 and pid < bj_MAX_PLAYER_SLOTS and User.fromIndex(pid).isPlaying
    endfunction

    private function HeroLivesClearFx takes integer pid returns nothing
        if HeroLivesFx[pid] != null then
            call DestroyEffect(HeroLivesFx[pid])
            set HeroLivesFx[pid] = null
        endif
    endfunction

    private function HeroLivesAbort takes integer pid returns nothing
        local timer t = HeroLivesTimer[pid]
        local unit hero = PlayerHero[pid]

        set HeroLivesTimer[pid] = null
        if t != null then
            call ReleaseTimer(t)
        endif

        if hero != null and GetUnitTypeId(hero) != 0 then
            call SetUnitInvulnerable(hero, false)
        endif

        call HeroLivesClearFx(pid)
        set HeroLivesState[pid] = 0
        set HeroLivesDeathX[pid] = 0.0
        set HeroLivesDeathY[pid] = 0.0

        set hero = null
        set t = null
    endfunction

    function HeroLivesGetCurrent takes integer pid returns integer
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return 0
        endif
        return HeroLivesCurrent[pid]
    endfunction

    function HeroLivesGetRemaining takes integer pid returns integer
        return HeroLivesGetCurrent(pid)
    endfunction

    function HeroLivesSetCurrent takes integer pid, integer lives returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if lives < 0 then
            set lives = 0
        endif
        set HeroLivesCurrent[pid] = lives
    endfunction

    function HeroLivesCancelPlayerState takes integer pid returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        call HeroLivesAbort(pid)
    endfunction

    function HeroLivesInitHero takes integer pid, unit hero returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if hero == null or GetUnitTypeId(hero) == 0 then
            return
        endif
        call HeroLivesAbort(pid)
        set HeroLivesCurrent[pid] = HERO_LIVES_BASE
    endfunction

    function HeroLivesRefreshActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u

        loop
            exitwhen i >= User.AmountPlaying
            set u = User.fromPlaying(i)
            call HeroLivesAbort(u.id)
            set HeroLivesCurrent[u.id] = HERO_LIVES_BASE
            set i = i + 1
        endloop
    endfunction

    function HeroLivesRefreshAll takes nothing returns nothing
        call HeroLivesRefreshActivePlayers()
    endfunction

    private function HeroLivesEndInvulnerability takes nothing returns boolean
        local timer t = GetExpiredTimer()
        local integer pid = GetTimerData(t)
        local unit hero = PlayerHero[pid]

        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            call ReleaseTimer(t)
            set t = null
            return false
        endif

        if hero != null and GetUnitTypeId(hero) != 0 then
            call SetUnitInvulnerable(hero, false)
        endif
        call HeroLivesClearFx(pid)
        set HeroLivesState[pid] = 0
        set HeroLivesTimer[pid] = null
        call ReleaseTimer(t)

        set hero = null
        set t = null
        return false
    endfunction

    private function HeroLivesStartInvulnerability takes integer pid returns nothing
        local unit hero = PlayerHero[pid]
        local timer t = HeroLivesTimer[pid]

        if hero == null or GetUnitTypeId(hero) == 0 then
            set hero = null
            set t = null
            return
        endif

        call SetUnitInvulnerable(hero, true)
        call HeroLivesClearFx(pid)
        if HERO_LIVES_INVULN_FX != "" then
            set HeroLivesFx[pid] = AddSpecialEffectTarget(HERO_LIVES_INVULN_FX, hero, "origin")
        endif
        set HeroLivesState[pid] = 2
        if t == null then
            set t = NewTimer()
            call SetTimerDebugTag(t, TIMER_DEBUG_TAG_OTHER)
            set HeroLivesTimer[pid] = t
        endif
        call SetTimerData(t, pid)
        call TimerStart(t, HERO_LIVES_INVULN_DURATION, false, function HeroLivesEndInvulnerability)

        set hero = null
        set t = null
    endfunction

    private function HeroLivesReviveHero takes integer pid returns nothing
        local unit hero = PlayerHero[pid]
        local real x = HeroLivesDeathX[pid]
        local real y = HeroLivesDeathY[pid]
        local effect fx

        if hero == null or GetUnitTypeId(hero) == 0 then
            call HeroLivesAbort(pid)
            set hero = null
            return
        endif

        if not IsUnitType(hero, UNIT_TYPE_DEAD) then
            call HeroLivesAbort(pid)
            set hero = null
            return
        endif

        if ReviveHero(hero, x, y, true) then
            call SetUnitState(hero, UNIT_STATE_LIFE, GetUnitState(hero, UNIT_STATE_MAX_LIFE))
            call SetUnitState(hero, UNIT_STATE_MANA, GetUnitState(hero, UNIT_STATE_MAX_MANA))
            call EnsurePlayerDefaultWeaponProfile(Player(pid))
            if HERO_LIVES_REVIVE_FX != "" then
                set fx = AddSpecialEffect(HERO_LIVES_REVIVE_FX, x, y)
                call DestroyEffect(fx)
                set fx = null
            endif
            call HeroLivesStartInvulnerability(pid)
        else
            call HeroLivesAbort(pid)
        endif

        set hero = null
    endfunction

    private function HeroLivesOnReviveTimer takes nothing returns boolean
        local timer t = GetExpiredTimer()
        local integer pid = GetTimerData(t)
        local unit hero = PlayerHero[pid]

        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            call ReleaseTimer(t)
            set t = null
            return false
        endif

        if not HeroLivesIsTrackedPlayer(pid) then
            call HeroLivesAbort(pid)
            set hero = null
            set t = null
            return false
        endif

        if HeroLivesState[pid] == 1 then
            if hero == null or GetUnitTypeId(hero) == 0 then
                call HeroLivesAbort(pid)
            elseif not IsUnitType(hero, UNIT_TYPE_DEAD) then
                call HeroLivesAbort(pid)
            else
                call HeroLivesReviveHero(pid)
            endif
        else
            call HeroLivesAbort(pid)
        endif

        set hero = null
        set t = null
        return false
    endfunction

    private function HeroLivesHandleDeath takes unit hero returns nothing
        local integer pid = GetPlayerId(GetOwningPlayer(hero))
        local User u

        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            set hero = null
            return
        endif

        set u = User.fromIndex(pid)
        if not u.isPlaying then
            set hero = null
            return
        endif
        if PlayerHero[pid] != hero then
            set hero = null
            return
        endif

        call HeroLivesAbort(pid)

        if not isWavez then
            set hero = null
            return
        endif
        if HeroLivesCurrent[pid] <= 0 then
            set hero = null
            return
        endif

        set HeroLivesDeathX[pid] = GetUnitX(hero)
        set HeroLivesDeathY[pid] = GetUnitY(hero)
        set HeroLivesCurrent[pid] = HeroLivesCurrent[pid] - 1
        set HeroLivesState[pid] = 1
        call WeaponInventoryResetActiveSlotOnDeath(Player(pid))

        if HeroLivesTimer[pid] == null then
            set HeroLivesTimer[pid] = NewTimer()
            call SetTimerDebugTag(HeroLivesTimer[pid], TIMER_DEBUG_TAG_OTHER)
        endif
        call SetTimerData(HeroLivesTimer[pid], pid)
        call TimerStart(HeroLivesTimer[pid], HERO_LIVES_REVIVE_DELAY, false, function HeroLivesOnReviveTimer)

        set hero = null
    endfunction

    private function HeroLivesOnDeath takes nothing returns boolean
        local unit hero = GetDyingUnit()

        if hero == null or GetUnitTypeId(hero) == 0 then
            set hero = null
            return false
        endif
        if not IsUnitType(hero, UNIT_TYPE_HERO) then
            set hero = null
            return false
        endif

        call HeroLivesHandleDeath(hero)

        set hero = null
        return false
    endfunction

    private function HeroLivesOnLeave takes nothing returns boolean
        local integer pid = GetPlayerId(GetTriggerPlayer())

        if pid >= 0 and pid < bj_MAX_PLAYER_SLOTS then
            call HeroLivesAbort(pid)
            set HeroLivesCurrent[pid] = HERO_LIVES_BASE
        endif

        return false
    endfunction

    function ReviveAndHealHeroes takes nothing returns nothing
        local integer i = 0
        local User u
        local unit h

        loop
            exitwhen i >= User.AmountPlaying
            set u = User.fromPlaying(i)
            set h = PlayerHero[u.id]

            if h != null then
                if IsUnitType(h, UNIT_TYPE_DEAD) then
                    call ReviveHero(h, GetUnitX(h), GetUnitY(h), true)
                endif

                call SetUnitState(h, UNIT_STATE_LIFE, GetUnitState(h, UNIT_STATE_MAX_LIFE))
                call SetUnitState(h, UNIT_STATE_MANA, GetUnitState(h, UNIT_STATE_MAX_MANA))
            endif

            set i = i + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0

        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set HeroLivesCurrent[i] = HERO_LIVES_BASE
            set HeroLivesState[i] = 0
            set HeroLivesTimer[i] = null
            set HeroLivesFx[i] = null
            set HeroLivesDeathX[i] = 0.0
            set HeroLivesDeathY[i] = 0.0
            set i = i + 1
        endloop

        set HeroLivesDeathTrigger = CreateTrigger()
        set HeroLivesLeaveTrigger = CreateTrigger()

        set i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(HeroLivesDeathTrigger, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
            call TriggerRegisterPlayerEvent(HeroLivesLeaveTrigger, Player(i), EVENT_PLAYER_LEAVE)
            set i = i + 1
        endloop

        call TriggerAddCondition(HeroLivesDeathTrigger, Condition(function HeroLivesOnDeath))
        call TriggerAddCondition(HeroLivesLeaveTrigger, Condition(function HeroLivesOnLeave))
    endfunction
endlibrary

