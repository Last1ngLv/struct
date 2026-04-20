library TenderAudio requires PlayerUtils, TenderSystem
    globals
        private constant boolean TENDER_AUDIO_DEBUG = false
        private constant boolean TENDER_AUDIO_ENABLED = false
        private constant integer TRADER_TRACK_COUNT = 6
        private constant integer TENDER_SOUND_VOLUME = 127
        private constant real TENDER_SOUND_PITCH = 1.00
        private constant real TENDER_SOUND_RADIUS = 500.0
        private constant real TENDER_SOUND_TICK = 0.10
        private timer TenderSoundTimer = null
        private integer CurrentTenderTrackIndex = 0
        private integer TraderTrackBagRemaining = 0
        private integer TraderTrackSeed = 1
        private integer array TraderTrackBag
        private sound array TenderSoundByPid
        private boolean array InRangeByPid
        private boolean array SoundActiveByPid
    endglobals
    private function TenderAudioDebug takes string msg returns nothing
        if TENDER_AUDIO_DEBUG then
            call BJDebugMsg("|cff99ccff[TenderAudio]|r " + msg)
        endif
    endfunction
    private function GetTraderTrackPath takes integer idx returns string
        if idx == 1 then
            return "war3mapImported\\Trader --- - Never Gonna Stay in The Abyss.wav"
        elseif idx == 2 then
            return "war3mapImported\\Trader 1 - Meanwhile, in The Abyss.wav"
        elseif idx == 3 then
            return "war3mapImported\\Trader 10 - Columba Noachi.wav"
        elseif idx == 4 then
            return "war3mapImported\\Trader 11 - Cold Wind.wav"
        elseif idx == 5 then
            return "war3mapImported\\Trader 12 - Crystal Breakin' Time.wav"
        elseif idx == 6 then
            return "war3mapImported\\Trader 9 - Weapon Check-up.wav"
        endif
        return ""
    endfunction
    private function ResetTraderTrackBag takes nothing returns nothing
        local integer i = 1
        loop
            exitwhen i > TRADER_TRACK_COUNT
            set TraderTrackBag[i] = i
            set i = i + 1
        endloop
        set TraderTrackBagRemaining = TRADER_TRACK_COUNT
    endfunction
    private function PickTraderTrackIndex takes integer waveIndex, integer lastIndex returns integer
        local integer pickSlot
        local integer pickedTrack
        local integer swapValue
        if TRADER_TRACK_COUNT <= 1 then
            return 1
        endif
        if TraderTrackBagRemaining <= 0 then
            call ResetTraderTrackBag()
        endif
        set TraderTrackSeed = ModuloInteger(TraderTrackSeed + (waveIndex * 17) + (lastIndex * 7) + 29, 104729)
        if TraderTrackSeed <= 0 then
            set TraderTrackSeed = 1
        endif
        set pickSlot = ModuloInteger(TraderTrackSeed, TraderTrackBagRemaining) + 1
        set pickedTrack = TraderTrackBag[pickSlot]
        if pickedTrack == lastIndex and TraderTrackBagRemaining > 1 then
            set pickSlot = pickSlot + 1
            if pickSlot > TraderTrackBagRemaining then
                set pickSlot = 1
            endif
            set pickedTrack = TraderTrackBag[pickSlot]
        endif
        set swapValue = TraderTrackBag[TraderTrackBagRemaining]
        set TraderTrackBag[TraderTrackBagRemaining] = TraderTrackBag[pickSlot]
        set TraderTrackBag[pickSlot] = swapValue
        set TraderTrackBagRemaining = TraderTrackBagRemaining - 1
        return pickedTrack
    endfunction
    private function ResetTenderAudioState takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set InRangeByPid[i] = false
            set SoundActiveByPid[i] = false
            set i = i + 1
        endloop
    endfunction
    private function StopTenderSoundTracker takes nothing returns nothing
        if TenderSoundTimer != null then
            call PauseTimer(TenderSoundTimer)
            call DestroyTimer(TenderSoundTimer)
            set TenderSoundTimer = null
            call TenderAudioDebug("tracker stop")
        endif
    endfunction
    private function StopPlayerTenderSound takes integer pid returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if TenderSoundByPid[pid] != null then
            call StopSound(TenderSoundByPid[pid], true, false)
            call KillSoundWhenDone(TenderSoundByPid[pid])
            set TenderSoundByPid[pid] = null
        endif
        set SoundActiveByPid[pid] = false
        set InRangeByPid[pid] = false
    endfunction
    private function StartPlayerTenderSound takes User u returns nothing
        local string trackPath = ""
        if not TENDER_AUDIO_ENABLED then
            return
        endif
        if CurrentTenderTrackIndex < 1 or CurrentTenderTrackIndex > TRADER_TRACK_COUNT then
            return
        endif
        call StopPlayerTenderSound(u.id)
        set trackPath = GetTraderTrackPath(CurrentTenderTrackIndex)
        set TenderSoundByPid[u.id] = CreateSound(trackPath, true, false, false, 12700, 12700, "")
        if TenderSoundByPid[u.id] != null then
            call SetSoundPitch(TenderSoundByPid[u.id], TENDER_SOUND_PITCH)
            call SetSoundVolume(TenderSoundByPid[u.id], TENDER_SOUND_VOLUME)
            call StartSound(TenderSoundByPid[u.id])
        endif
        set SoundActiveByPid[u.id] = true
        call TenderAudioDebug("player sound start pid=" + I2S(u.id) + " track=" + I2S(CurrentTenderTrackIndex))
    endfunction
    private function OnTenderSoundTick takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local boolean inRange
        if CurrentTenderTrackIndex < 1 or CurrentTenderTrackIndex > TRADER_TRACK_COUNT then
            set hero = null
            return
        endif
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            set inRange = false
            if hero != null and GetUnitTypeId(hero) != 0 then
                set inRange = IsUnitNearTender(hero, TENDER_SOUND_RADIUS)
            endif
            set InRangeByPid[u.id] = inRange
            if InRangeByPid[u.id] != SoundActiveByPid[u.id] then
                if InRangeByPid[u.id] then
                    call StartPlayerTenderSound(u)
                else
                    call StopPlayerTenderSound(u.id)
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction
    private function StartTenderSoundTracker takes nothing returns nothing
        if not TENDER_AUDIO_ENABLED then
            return
        endif
        call StopTenderSoundTracker()
        set TenderSoundTimer = CreateTimer()
        call TimerStart(TenderSoundTimer, TENDER_SOUND_TICK, true, function OnTenderSoundTick)
        call TenderAudioDebug("tracker start tick=" + R2S(TENDER_SOUND_TICK))
    endfunction
    function TenderAudioStop takes nothing returns nothing
        local integer i = 0
        call StopTenderSoundTracker()
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call StopPlayerTenderSound(i)
            set i = i + 1
        endloop
        call ResetTenderAudioState()
        set CurrentTenderTrackIndex = 0
        call TenderAudioDebug("stop all player sounds")
    endfunction
    function TenderAudioStartRest takes integer waveIndex, integer lastIndex returns integer
        local integer nextTrack = PickTraderTrackIndex(waveIndex, lastIndex)
        call TenderAudioStop()
        if not TENDER_AUDIO_ENABLED then
            call TenderAudioDebug("start rest disabled wave=" + I2S(waveIndex))
            return nextTrack
        endif
        if nextTrack < 1 or nextTrack > TRADER_TRACK_COUNT or GetTraderTrackPath(nextTrack) == "" then
            call TenderAudioDebug("start rest skipped wave=" + I2S(waveIndex) + " track=" + I2S(nextTrack))
            return lastIndex
        endif
        call ResetTenderAudioState()
        set CurrentTenderTrackIndex = nextTrack
        call TenderAudioDebug("start rest wave=" + I2S(waveIndex) + " last=" + I2S(lastIndex) + " next=" + I2S(nextTrack))
        call StartTenderSoundTracker()
        call OnTenderSoundTick()
        return nextTrack
    endfunction
endlibrary