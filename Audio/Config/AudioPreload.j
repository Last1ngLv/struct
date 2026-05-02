library AudioPreloadConfig

    globals
        private timer PreloadResTimer = null
        private integer PreloadResCursor = 1
    endglobals

    private function WarmupSound takes string path returns nothing
        local sound s
        if path == null or path == "" then
            return
        endif
        call Preload(path)
        set s = CreateSound(path, false, false, false, 10, 10, "")
        if s != null then
            call SetSoundVolume(s, 0)
            call StartSound(s)
            call KillSoundWhenDone(s)
        endif
        set s = null
    endfunction

    private function GetPreloadSoundPath takes integer idx returns string
        if idx == 1 then
            return "war3mapImported\\announcer_1stblood_01.wav"
        elseif idx == 2 then
            return "war3mapImported\\RDK_RompeRacha.mp3"
        elseif idx == 3 then
            return "war3mapImported\\RDK_RompeCombo1.mp3"
        elseif idx == 4 then
            return "war3mapImported\\RDK_RompeCombo2.mp3"
        elseif idx == 5 then
            return "war3mapImported\\announcer_kill_spree_01.mp3"
        elseif idx == 6 then
            return "war3mapImported\\announcer_kill_dominate_01.mp3"
        elseif idx == 7 then
            return "war3mapImported\\announcer_kill_mega_01.mp3"
        elseif idx == 8 then
            return "war3mapImported\\announcer_kill_unstop_01.mp3"
        elseif idx == 9 then
            return "war3mapImported\\announcer_kill_wicked_01.mp3"
        elseif idx == 10 then
            return "war3mapImported\\announcer_kill_monster_01.mp3"
        elseif idx == 11 then
            return "war3mapImported\\announcer_kill_godlike_01.mp3"
        elseif idx == 12 then
            return "war3mapImported\\announcer_kill_holy_01.mp3"
        elseif idx == 13 then
            return "war3mapImported\\announcer_kill_double_01.mp3"
        elseif idx == 14 then
            return "war3mapImported\\announcer_kill_triple_01.mp3"
        elseif idx == 15 then
            return "war3mapImported\\announcer_kill_ultra_01.mp3"
        elseif idx == 16 then
            return "war3mapImported\\announcer_kill_rampage_01.mp3"
        elseif idx == 17 then
            return "war3mapImported\\Trader --- - Never Gonna Stay in The Abyss.wav"
        elseif idx == 18 then
            return "war3mapImported\\Trader 1 - Meanwhile, in The Abyss.wav"
        elseif idx == 19 then
            return "war3mapImported\\Trader 10 - Columba Noachi.wav"
        elseif idx == 20 then
            return "war3mapImported\\Trader 11 - Cold Wind.wav"
        elseif idx == 21 then
            return "war3mapImported\\Trader 12 - Crystal Breakin' Time.wav"
        elseif idx == 22 then
            return "war3mapImported\\Trader 9 - Weapon Check-up.wav"
        elseif idx == 23 then
            return "war3mapImported\\SurvivalEnd.wav"
        endif
        return ""
    endfunction

    private function PreloadMapResourcesTick takes nothing returns nothing
        local string path = GetPreloadSoundPath(PreloadResCursor)
        if path == "" then
            call PauseTimer(PreloadResTimer)
            call DestroyTimer(PreloadResTimer)
            set PreloadResTimer = null
            return
        endif
        call WarmupSound(path)
        set PreloadResCursor = PreloadResCursor + 1
    endfunction

    function PreloadMapResources takes nothing returns nothing
        set PreloadResCursor = 1
        if PreloadResTimer != null then
            call PauseTimer(PreloadResTimer)
            call DestroyTimer(PreloadResTimer)
        endif
        set PreloadResTimer = CreateTimer()
        call TimerStart(PreloadResTimer, 0.10, true, function PreloadMapResourcesTick)
    endfunction

endlibrary
