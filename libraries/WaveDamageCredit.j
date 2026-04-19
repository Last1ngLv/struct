library WaveDamageCredit initializer Init requires Table, HealthBarTextTags

    globals
        // Fallback window for last-damage credit. Short on purpose:
        // it covers death-event latency / proxy damage, but avoids carrying
        // stale damage credit across later unrelated deaths.
        private constant real WAVE_DAMAGE_CREDIT_TTL = 1.50

        private Table WaveDamageCreditOwnerPidByTarget
        private Table WaveDamageCreditSourceHidByTarget
        private Table WaveDamageCreditTimeByTarget
        private timer WaveDamageCreditClock = null
    endglobals

    private function WaveDamageCreditNow takes nothing returns real
        return TimerGetElapsed(WaveDamageCreditClock)
    endfunction

    private function WaveDamageCreditResolveOwnerPid takes unit source returns integer
        local integer pid
        if source == null or GetUnitTypeId(source) == 0 then
            return -1
        endif
        set pid = GetPlayerId(GetOwningPlayer(source))
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return -1
        endif
        return pid
    endfunction

    function WaveRecordDamageCredit takes unit source, unit target returns nothing
        local integer hid
        local integer pid
        if source == null or target == null then
            return
        endif
        if GetUnitTypeId(source) == 0 or GetUnitTypeId(target) == 0 then
            return
        endif
        set pid = WaveDamageCreditResolveOwnerPid(source)
        if pid < 0 then
            return
        endif
        set hid = GetHandleId(target)
        set WaveDamageCreditOwnerPidByTarget[hid] = pid
        set WaveDamageCreditSourceHidByTarget[hid] = GetHandleId(source)
        set WaveDamageCreditTimeByTarget.real[hid] = WaveDamageCreditNow()
        call HealthBarsNotifyEnemyDamaged(source, target)
    endfunction

    function WaveClearDamageCredit takes unit target returns nothing
        local integer hid
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        if WaveDamageCreditOwnerPidByTarget.has(hid) then
            call WaveDamageCreditOwnerPidByTarget.remove(hid)
        endif
        if WaveDamageCreditSourceHidByTarget.has(hid) then
            call WaveDamageCreditSourceHidByTarget.remove(hid)
        endif
        if WaveDamageCreditTimeByTarget.real.has(hid) then
            call WaveDamageCreditTimeByTarget.real.remove(hid)
        endif
    endfunction

    function WaveGetDamageCreditOwnerPid takes unit target returns integer
        local integer hid
        local real age
        if target == null or GetUnitTypeId(target) == 0 then
            return -1
        endif
        set hid = GetHandleId(target)
        if not WaveDamageCreditOwnerPidByTarget.has(hid) then
            return -1
        endif
        set age = WaveDamageCreditNow() - WaveDamageCreditTimeByTarget.real[hid]
        if age < 0.00 or age > WAVE_DAMAGE_CREDIT_TTL then
            call WaveClearDamageCredit(target)
            return -1
        endif
        return WaveDamageCreditOwnerPidByTarget[hid]
    endfunction

    private function WaveDamageCreditClockNoop takes nothing returns nothing
    endfunction

    private function Init takes nothing returns nothing
        set WaveDamageCreditOwnerPidByTarget = Table.create()
        set WaveDamageCreditSourceHidByTarget = Table.create()
        set WaveDamageCreditTimeByTarget = Table.create()
        set WaveDamageCreditClock = CreateTimer()
        call TimerStart(WaveDamageCreditClock, 864000.00, false, function WaveDamageCreditClockNoop)
    endfunction
endlibrary
