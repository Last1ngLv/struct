library TenderEscInteraction initializer Init requires PlayerUtils, PlayerHeroState, TenderSystem, RestTimeState, MenuClient, GameState

    globals
        private constant real TENDER_ESC_RADIUS = 500.0
        private constant real TENDER_ESC_PROMPT_TICK = 0.50
        private timer TenderEscPromptTimer = null
        private boolean array TenderEscPromptShownByPid
    endglobals

    private function HasValidHero takes integer pid returns boolean
        return PlayerHero[pid] != null and GetUnitTypeId(PlayerHero[pid]) != 0
    endfunction

    private function IsHeroInTenderRange takes integer pid returns boolean
        if not HasValidHero(pid) then
            return false
        endif
        return IsUnitNearTender(PlayerHero[pid], TENDER_ESC_RADIUS)
    endfunction

    private function RefreshTenderClient takes integer pid returns nothing
        local unit hero
        local Client client

        if not HasValidHero(pid) then
            return
        endif

        set hero = PlayerHero[pid]
        set client = Client[hero]

        if client != 0 and PlayerCamera[pid] != 0 then
            call client.show(true, PlayerCamera[pid])
        endif

        set hero = null
    endfunction

    private function ShowToPlayer takes player p, string text returns nothing
        call DisplayTimedTextToPlayer(p, 0.52, 0.82, 1.50, text)
    endfunction

    private function CloseTenderForPid takes integer pid returns nothing
        if isTender[pid] then
            set isTender[pid] = false
            call RefreshTenderClient(pid)
        endif
    endfunction

    private function ToggleTenderForEsc takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p)

        if pid < 0 or pid > 7 then
            set p = null
            return
        endif

        if RestPhaseState != REST_PHASE_PURCHASE then
            call CloseTenderForPid(pid)
            set TenderEscPromptShownByPid[pid] = false
            set p = null
            return
        endif

        if isTender[pid] then
            call CloseTenderForPid(pid)
            call ShowToPlayer(p, "|cffffcc00Tender cerrado.|r")
        elseif IsHeroInTenderRange(pid) then
            set isTender[pid] = true
            call RefreshTenderClient(pid)
            call ShowToPlayer(p, "|cff00ff99Tender abierto.|r")
        else
            call ShowToPlayer(p, "|cffffcc00Acercate al Tender para abrir la tienda.|r")
        endif

        set p = null
    endfunction

    private function PromptTenderEsc takes nothing returns nothing
        local integer i = 0
        local User u
        local boolean shouldPrompt

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set shouldPrompt = RestPhaseState == REST_PHASE_PURCHASE and not isTender[u.id] and IsHeroInTenderRange(u.id)

            if shouldPrompt and not TenderEscPromptShownByPid[u.id] then
                call ShowToPlayer(u.toPlayer(), "|cff00ccffPresiona ESC para abrir el Tender|r")
                set TenderEscPromptShownByPid[u.id] = true
            elseif not shouldPrompt then
                set TenderEscPromptShownByPid[u.id] = false
            endif

            set i = i + 1
        endloop
    endfunction

    private function RegisterEscForActivePlayers takes trigger t returns nothing
        local integer i = 0
        local User u

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            call TriggerRegisterPlayerEvent(t, u.toPlayer(), EVENT_PLAYER_END_CINEMATIC)
            set i = i + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        local trigger escTrigger = CreateTrigger()

        call RegisterEscForActivePlayers(escTrigger)
        call TriggerAddAction(escTrigger, function ToggleTenderForEsc)

        set TenderEscPromptTimer = CreateTimer()
        call TimerStart(TenderEscPromptTimer, TENDER_ESC_PROMPT_TICK, true, function PromptTenderEsc)

        set escTrigger = null
    endfunction

endlibrary
