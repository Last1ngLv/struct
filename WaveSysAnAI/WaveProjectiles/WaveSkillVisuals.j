library WaveSkillVisuals initializer Init requires TimerUtils

    globals
        public constant integer WAVE_SKILL_VISUAL_DUMMY_ID = 'dumi'
        public constant integer WAVE_SKILL_VISUAL_LOCUST_ID = 'Aloc'
        public constant integer WAVE_SKILL_VISUAL_INVUL_ID = 'Avul'
        public constant string WAVE_SKILL_VISUAL_ATTACH_POINT = "origin"
        public constant real WAVE_SKILL_VISUAL_TICK = 0.05

        private constant integer WAVE_SKILL_VISUAL_KIND_FOLLOWER = 1
        private constant integer WAVE_SKILL_VISUAL_KIND_TIMED = 2

        private timer WaveSkillVisualTimer
        private boolean WaveSkillVisualTimerRunning = false
        private integer WaveSkillVisualHead = 0
        private integer WaveSkillVisualCount = 0

        private integer array WaveSkillVisualNext
        private integer array WaveSkillVisualPrev
        private integer array WaveSkillVisualKind
        private unit array WaveSkillVisualSource
        private unit array WaveSkillVisualDummy
        private effect array WaveSkillVisualFx
        private real array WaveSkillVisualRemaining
    endglobals

    private function WaveSkillVisualUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    function WaveSkillVisualScaleForRadius takes real radius returns real
        if radius <= 0.0 then
            return 0.01
        endif
        return radius/100.0
    endfunction

    function WaveSkillVisualShieldScaleForRadius takes real radius returns real
        if radius <= 0.0 then
            return 0.01
        endif
        return radius/300.0
    endfunction

    private function WaveSkillVisualAdd takes integer visualId returns nothing
        set WaveSkillVisualPrev[visualId] = 0
        set WaveSkillVisualNext[visualId] = WaveSkillVisualHead
        if WaveSkillVisualHead != 0 then
            set WaveSkillVisualPrev[WaveSkillVisualHead] = visualId
        endif
        set WaveSkillVisualHead = visualId
    endfunction

    private function WaveSkillVisualRemove takes integer visualId returns nothing
        local integer p = WaveSkillVisualPrev[visualId]
        local integer n = WaveSkillVisualNext[visualId]
        if p != 0 then
            set WaveSkillVisualNext[p] = n
        else
            set WaveSkillVisualHead = n
        endif
        if n != 0 then
            set WaveSkillVisualPrev[n] = p
        endif
        set WaveSkillVisualPrev[visualId] = 0
        set WaveSkillVisualNext[visualId] = 0
    endfunction

    private function WaveSkillVisualCreateDummy takes real x, real y, real facing, real scale returns unit
        local unit dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), WAVE_SKILL_VISUAL_DUMMY_ID, x, y, facing)
        if dummy != null and GetUnitTypeId(dummy) != 0 then
            call UnitAddAbility(dummy, WAVE_SKILL_VISUAL_LOCUST_ID)
            call UnitAddAbility(dummy, WAVE_SKILL_VISUAL_INVUL_ID)
            call SetUnitPathing(dummy, false)
            call SetUnitScale(dummy, scale, scale, scale)
        endif
        return dummy
    endfunction

    function WaveSkillVisualDestroy takes integer visualId returns nothing
        local unit dummy
        if visualId <= 0 or WaveSkillVisualKind[visualId] == 0 then
            return
        endif
        call WaveSkillVisualRemove(visualId)
        set dummy = WaveSkillVisualDummy[visualId]
        if WaveSkillVisualFx[visualId] != null then
            call DestroyEffect(WaveSkillVisualFx[visualId])
            set WaveSkillVisualFx[visualId] = null
        endif
        if dummy != null and GetUnitTypeId(dummy) != 0 then
            call RemoveUnit(dummy)
        endif
        set WaveSkillVisualDummy[visualId] = null
        set WaveSkillVisualSource[visualId] = null
        set WaveSkillVisualKind[visualId] = 0
        set WaveSkillVisualRemaining[visualId] = 0.0
    endfunction

    function WaveSkillVisualSetPosition takes integer visualId, real x, real y, real facing returns nothing
        local unit dummy = WaveSkillVisualDummy[visualId]
        if visualId <= 0 or dummy == null or GetUnitTypeId(dummy) == 0 then
            set dummy = null
            return
        endif
        call SetUnitX(dummy, x)
        call SetUnitY(dummy, y)
        call SetUnitFacing(dummy, facing)
        set dummy = null
    endfunction

    function WaveSkillVisualSetRemaining takes integer visualId, real duration returns nothing
        if visualId <= 0 then
            return
        endif
        if duration <= 0.0 then
            call WaveSkillVisualDestroy(visualId)
            return
        endif
        set WaveSkillVisualRemaining[visualId] = duration
    endfunction

    private function WaveSkillVisualTick takes nothing returns nothing
        local integer visualId = WaveSkillVisualHead
        local integer nextVisualId
        local unit source
        loop
            exitwhen visualId == 0
            set nextVisualId = WaveSkillVisualNext[visualId]
            if WaveSkillVisualKind[visualId] == WAVE_SKILL_VISUAL_KIND_FOLLOWER then
                set source = WaveSkillVisualSource[visualId]
                if not WaveSkillVisualUnitAlive(source) then
                    call WaveSkillVisualDestroy(visualId)
                else
                    call WaveSkillVisualSetPosition(visualId, GetUnitX(source), GetUnitY(source), GetUnitFacing(source))
                endif
            elseif WaveSkillVisualKind[visualId] == WAVE_SKILL_VISUAL_KIND_TIMED then
                set WaveSkillVisualRemaining[visualId] = WaveSkillVisualRemaining[visualId] - WAVE_SKILL_VISUAL_TICK
                if WaveSkillVisualRemaining[visualId] <= 0.0 then
                    call WaveSkillVisualDestroy(visualId)
                endif
            else
                call WaveSkillVisualDestroy(visualId)
            endif
            set visualId = nextVisualId
            set source = null
        endloop

        if WaveSkillVisualHead == 0 and WaveSkillVisualTimerRunning then
            call PauseTimer(WaveSkillVisualTimer)
            set WaveSkillVisualTimerRunning = false
        endif
    endfunction

    private function WaveSkillVisualEnsureTimer takes nothing returns nothing
        if not WaveSkillVisualTimerRunning then
            set WaveSkillVisualTimerRunning = true
            call TimerStart(WaveSkillVisualTimer, WAVE_SKILL_VISUAL_TICK, true, function WaveSkillVisualTick)
        endif
    endfunction

    function WaveSkillVisualCreateFollowerScaled takes unit source, string modelPath, real scale returns integer
        local integer visualId
        local unit dummy
        if not WaveSkillVisualUnitAlive(source) or modelPath == "" then
            return 0
        endif
        set visualId = WaveSkillVisualCount + 1
        set WaveSkillVisualCount = visualId
        set dummy = WaveSkillVisualCreateDummy(GetUnitX(source), GetUnitY(source), GetUnitFacing(source), scale)
        if dummy == null or GetUnitTypeId(dummy) == 0 then
            set dummy = null
            return 0
        endif
        set WaveSkillVisualKind[visualId] = WAVE_SKILL_VISUAL_KIND_FOLLOWER
        set WaveSkillVisualSource[visualId] = source
        set WaveSkillVisualDummy[visualId] = dummy
        set WaveSkillVisualFx[visualId] = AddSpecialEffectTarget(modelPath, dummy, WAVE_SKILL_VISUAL_ATTACH_POINT)
        set WaveSkillVisualRemaining[visualId] = 0.0
        call WaveSkillVisualAdd(visualId)
        call WaveSkillVisualEnsureTimer()
        set dummy = null
        return visualId
    endfunction

    function WaveSkillVisualCreateFollower takes unit source, string modelPath, real radius returns integer
        return WaveSkillVisualCreateFollowerScaled(source, modelPath, WaveSkillVisualScaleForRadius(radius))
    endfunction

    function WaveSkillVisualCreateTimedMarkerScaled takes real x, real y, real facing, string modelPath, real scale, real duration returns integer
        local integer visualId
        local unit dummy
        if modelPath == "" or duration <= 0.0 then
            return 0
        endif
        set visualId = WaveSkillVisualCount + 1
        set WaveSkillVisualCount = visualId
        set dummy = WaveSkillVisualCreateDummy(x, y, facing, scale)
        if dummy == null or GetUnitTypeId(dummy) == 0 then
            set dummy = null
            return 0
        endif
        set WaveSkillVisualKind[visualId] = WAVE_SKILL_VISUAL_KIND_TIMED
        set WaveSkillVisualSource[visualId] = null
        set WaveSkillVisualDummy[visualId] = dummy
        set WaveSkillVisualFx[visualId] = AddSpecialEffectTarget(modelPath, dummy, WAVE_SKILL_VISUAL_ATTACH_POINT)
        set WaveSkillVisualRemaining[visualId] = duration
        call WaveSkillVisualAdd(visualId)
        call WaveSkillVisualEnsureTimer()
        set dummy = null
        return visualId
    endfunction

    function WaveSkillVisualCreateTimedMarker takes real x, real y, real facing, string modelPath, real radius, real duration returns integer
        return WaveSkillVisualCreateTimedMarkerScaled(x, y, facing, modelPath, WaveSkillVisualScaleForRadius(radius), duration)
    endfunction

    private function Init takes nothing returns nothing
        set WaveSkillVisualTimer = NewTimer()
        call SetTimerDebugTag(WaveSkillVisualTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)
        set WaveSkillVisualTimerRunning = true
        call TimerStart(WaveSkillVisualTimer, WAVE_SKILL_VISUAL_TICK, true, function WaveSkillVisualTick)
    endfunction
endlibrary
