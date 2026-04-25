library RestTimeTenderAudio requires PlayerUtils, PlayerHeroState, TenderSystem, RestTimeState

    private function RestTimeTenderAudioTrackCount takes nothing returns integer
        return 6
    endfunction

    private function RestTimeTenderAudioPath takes integer index returns string
        if index == 1 then
            return "war3mapImported\\Trader --- - Never Gonna Stay in The Abyss.wav"
        elseif index == 2 then
            return "war3mapImported\\Trader 1 - Meanwhile, in The Abyss.wav"
        elseif index == 3 then
            return "war3mapImported\\Trader 10 - Columba Noachi.wav"
        elseif index == 4 then
            return "war3mapImported\\Trader 11 - Cold Wind.wav"
        elseif index == 5 then
            return "war3mapImported\\Trader 12 - Crystal Breakin' Time.wav"
        elseif index == 6 then
            return "war3mapImported\\Trader 9 - Weapon Check-up.wav"
        endif
        return ""
    endfunction

    private function RestTimeTenderAudioPickTrack takes nothing returns integer
        local integer count = RestTimeTenderAudioTrackCount()
        local integer selected
        if count <= 1 then
            return 1
        endif
        set selected = GetRandomInt(1, count)
        if selected == RestTenderAudioLastTrackIndex then
            set selected = selected + 1
            if selected > count then
                set selected = 1
            endif
        endif
        return selected
    endfunction

    private function RestTimeTenderAudioStopForPid takes integer pid returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if RestTenderAudioActiveByPid[pid] then
            call StopSound(RestTenderAudioSoundByPid[pid], true, false)
            call KillSoundWhenDone(RestTenderAudioSoundByPid[pid])
            set RestTenderAudioSoundByPid[pid] = null
            set RestTenderAudioActiveByPid[pid] = false
        endif
    endfunction

    private function RestTimeTenderAudioStartForUser takes User u returns nothing
        local string path = ""
        if RestTenderAudioActiveByPid[u.id] then
            return
        endif
        if GetLocalPlayer() == u.toPlayer() then
            set path = RestTimeTenderAudioPath(RestTenderAudioTrackIndex)
        endif
        set RestTenderAudioSoundByPid[u.id] = CreateSound(path, true, false, false, 12700, 12700, "")
        call SetSoundVolume(RestTenderAudioSoundByPid[u.id], REST_TENDER_AUDIO_VOLUME)
        call SetSoundPitch(RestTenderAudioSoundByPid[u.id], 1.00)
        call StartSound(RestTenderAudioSoundByPid[u.id])
        set RestTenderAudioActiveByPid[u.id] = true
    endfunction

    private function RestTimeTenderAudioTick takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local boolean inRange

        if not RestTenderAudioRunning or RestPhaseState != REST_PHASE_PURCHASE then
            return
        endif

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            set inRange = IsUnitNearTender(hero, REST_TENDER_AUDIO_RADIUS)

            if inRange and not RestTenderAudioActiveByPid[u.id] then
                call RestTimeTenderAudioStartForUser(u)
            elseif not inRange and RestTenderAudioActiveByPid[u.id] then
                call RestTimeTenderAudioStopForPid(u.id)
            endif

            set i = i + 1
        endloop
        set hero = null
    endfunction

    function RestTimeTenderAudioStart takes nothing returns nothing
        if not REST_TENDER_AUDIO_ENABLED then
            return
        endif
        if RestTenderAudioRunning then
            return
        endif
        set RestTenderAudioTrackIndex = RestTimeTenderAudioPickTrack()
        set RestTenderAudioLastTrackIndex = RestTenderAudioTrackIndex
        set RestTenderAudioRunning = true
        if RestTenderAudioTimer == null then
            set RestTenderAudioTimer = CreateTimer()
        endif
        call TimerStart(RestTenderAudioTimer, REST_TENDER_AUDIO_TICK_SEC, true, function RestTimeTenderAudioTick)
        call RestTimeTenderAudioTick()
    endfunction

    function RestTimeTenderAudioStop takes nothing returns nothing
        local integer pid = 0
        set RestTenderAudioRunning = false
        if RestTenderAudioTimer != null then
            call PauseTimer(RestTenderAudioTimer)
        endif
        loop
            exitwhen pid >= bj_MAX_PLAYER_SLOTS
            call RestTimeTenderAudioStopForPid(pid)
            set pid = pid + 1
        endloop
        set RestTenderAudioTrackIndex = 0
    endfunction

endlibrary
