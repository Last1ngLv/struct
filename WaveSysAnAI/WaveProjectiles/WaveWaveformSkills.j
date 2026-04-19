library WaveWaveformSkills initializer Init requires Table, TimerUtils, Missile, SpellIndex, WaveTest

    globals
        public constant integer WAVE_HWT3_UNIT_ID = 'hwt3'
        public constant integer WAVE_HWT3_BOSS_UNIT_ID = 'zA09'

        public constant string WAVE_HWT3_IMPACT_FX = "Abilities\\Spells\\Other\\CrushingWave\\CrushingWaveDamage.mdl"
        public constant string WAVE_HWT3_TRAIL_FX = "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl"
        public constant real WAVE_HWT3_TRAIL_INTERVAL = 0.10
        public constant real WAVE_HWT3_SPEED = 1200.0
        public constant real WAVE_HWT3_INITIAL_DELAY_MIN = 4.00
        public constant real WAVE_HWT3_INITIAL_DELAY_MAX = 6.50
        public constant real WAVE_HWT3_COOLDOWN_MIN = 3.00
        public constant real WAVE_HWT3_COOLDOWN_MAX = 5.00
        public constant real WAVE_HWT3_AOE = 250.0
        public constant real WAVE_HWT3_DAMAGE = 15.0

        public constant real WAVE_HWT3_BOSS_INITIAL_DELAY_MIN = 4.00
        public constant real WAVE_HWT3_BOSS_INITIAL_DELAY_MAX = 6.50
        public constant real WAVE_HWT3_BOSS_COOLDOWN_MIN = 1.00
        public constant real WAVE_HWT3_BOSS_COOLDOWN_MAX = 2.00
        public constant real WAVE_HWT3_BOSS_AOE = 500.0
        public constant real WAVE_HWT3_BOSS_DAMAGE = 30.0

        private Table WaveWaveformNextCastMs
        private Table WaveWaveformActiveMissileByUnit
        private real array WaveWaveformMissileAoe
        private real array WaveWaveformMissileDamage
        private real array WaveWaveformMissileTrailElapsed
    endglobals

    private function WaveWaveformSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveWaveformRandomMsRange takes real minSec, real maxSec returns integer
        local real lo = minSec
        local real hi = maxSec
        if hi < lo then
            set lo = maxSec
            set hi = minSec
        endif
        if hi <= 0.0 then
            return 0
        endif
        if lo < 0.0 then
            set lo = 0.0
        endif
        return WaveWaveformSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveWaveformUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveWaveformCreateImpactFx takes real x, real y returns nothing
        local effect fx = AddSpecialEffect(WAVE_HWT3_IMPACT_FX, x, y)
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private function WaveWaveformCanDamage takes Missile missile, unit target returns boolean
        if target == null or not UnitAlive(target) then
            return false
        endif
        if not IsUnitEnemy(target, missile.owner) then
            return false
        endif
        return true
    endfunction

    private struct WaveWaveformMissile extends array
        private static method onPeriod takes Missile missile returns boolean
            local unit hit
            local unit source = missile.source
            local real x = missile.x
            local real y = missile.y
            local effect fx
            if not WaveWaveformUnitAlive(source) then
                set source = null
                return true
            endif
            set WaveWaveformMissileTrailElapsed[missile] = WaveWaveformMissileTrailElapsed[missile] + 0.03125
            loop
                exitwhen WaveWaveformMissileTrailElapsed[missile] < WAVE_HWT3_TRAIL_INTERVAL
                set WaveWaveformMissileTrailElapsed[missile] = WaveWaveformMissileTrailElapsed[missile] - WAVE_HWT3_TRAIL_INTERVAL
                set fx = AddSpecialEffect(WAVE_HWT3_TRAIL_FX, x, y)
                call DestroyEffect(fx)
                set fx = null
            endloop
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, WaveWaveformMissileAoe[missile], null)
            loop
                set hit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen hit == null
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, hit)
                if WaveWaveformCanDamage(missile, hit) and not missile.hasHitWidget(hit) then
                    call missile.hitWidget(hit)
                    call UnitDamageTarget(source, hit, WaveWaveformMissileDamage[missile], false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, null)
                endif
            endloop
            set hit = null
            set source = null
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local unit hit
            local unit source = missile.source
            local real x = missile.x
            local real y = missile.y
            local effect fx
            if source != null and GetUnitTypeId(source) != 0 then
                call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, WaveWaveformMissileAoe[missile], null)
                loop
                    set hit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                    exitwhen hit == null
                    call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, hit)
                    if WaveWaveformCanDamage(missile, hit) then
                        call UnitDamageTarget(source, hit, WaveWaveformMissileDamage[missile], false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, null)
                    endif
                endloop
            endif
            call WaveWaveformCreateImpactFx(x, y)
            set hit = null
            set source = null
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            local unit source = missile.source
            local integer hid = 0
            if source != null and GetUnitTypeId(source) != 0 then
                set hid = GetHandleId(source)
                if hid != 0 and WaveWaveformActiveMissileByUnit.has(hid) and WaveWaveformActiveMissileByUnit[hid] == missile then
                    call WaveWaveformActiveMissileByUnit.remove(hid)
                endif
                call SetUnitPathing(source, true)
                call SetUnitTimeScale(source, 1.0)
                call SetUnitFlyHeight(source, 0.0, 99999.)
            endif
            set WaveWaveformMissileAoe[missile] = 0.0
            set WaveWaveformMissileDamage[missile] = 0.0
            set WaveWaveformMissileTrailElapsed[missile] = 0.0
            set source = null
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function WaveWaveformLaunch takes unit source, real tx, real ty, real aoe, real damage returns nothing
        local Missile missile
        if not WaveWaveformUnitAlive(source) then
            return
        endif
        if UnitAddAbility(source, 'Amrf') and UnitRemoveAbility(source, 'Amrf') then
        endif
        call SetUnitPathing(source, false)
        call SetUnitFlyHeight(source, 60.0, 99999.)
        set missile = Missile.createEx(source, tx, ty, 0.0)
        set missile.source = source
        set missile.owner = GetOwningPlayer(source)
        set missile.collision = 0.0
        call missile.setMovementSpeed(WAVE_HWT3_SPEED)
        set WaveWaveformMissileAoe[missile] = aoe
        set WaveWaveformMissileDamage[missile] = damage
        set WaveWaveformMissileTrailElapsed[missile] = 0.0
        set WaveWaveformActiveMissileByUnit[GetHandleId(source)] = missile
        call WaveWaveformMissile.launch(missile)
    endfunction

    private function WaveWaveformCleanupWaveDeath takes nothing returns nothing
        local unit deadUnit = GetWaveEventUnit()
        local integer hid
        local Missile missile
        local integer unitTypeId
        if deadUnit == null or GetUnitTypeId(deadUnit) == 0 then
            return
        endif
        set unitTypeId = GetUnitTypeId(deadUnit)
        if unitTypeId != WAVE_HWT3_UNIT_ID and unitTypeId != WAVE_HWT3_BOSS_UNIT_ID then
            return
        endif
        set hid = GetHandleId(deadUnit)
        if hid != 0 and WaveWaveformNextCastMs.has(hid) then
            call WaveWaveformNextCastMs.remove(hid)
        endif
        if hid != 0 and WaveWaveformActiveMissileByUnit.has(hid) then
            set missile = WaveWaveformActiveMissileByUnit[hid]
            call WaveWaveformActiveMissileByUnit.remove(hid)
            if missile != 0 then
                call missile.terminate()
            endif
        endif
    endfunction

    function WaveWaveformSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local real aoe
        local real damage
        local boolean isBoss = false
        if not WaveWaveformUnitAlive(source) then
            return false
        endif
        if GetUnitTypeId(source) == WAVE_HWT3_BOSS_UNIT_ID then
            set isBoss = true
        elseif GetUnitTypeId(source) != WAVE_HWT3_UNIT_ID then
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif
        if WaveWaveformActiveMissileByUnit.has(hid) and WaveWaveformActiveMissileByUnit[hid] != 0 then
            return true
        endif
        if not WaveWaveformNextCastMs.has(hid) then
            if isBoss then
                set WaveWaveformNextCastMs[hid] = nowMs + WaveWaveformRandomMsRange(WAVE_HWT3_BOSS_INITIAL_DELAY_MIN, WAVE_HWT3_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveWaveformNextCastMs[hid] = nowMs + WaveWaveformRandomMsRange(WAVE_HWT3_INITIAL_DELAY_MIN, WAVE_HWT3_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WaveWaveformNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "spell")
        if isBoss then
            set aoe = WAVE_HWT3_BOSS_AOE
            set damage = WAVE_HWT3_BOSS_DAMAGE
            set WaveWaveformNextCastMs[hid] = nowMs + WaveWaveformRandomMsRange(WAVE_HWT3_BOSS_COOLDOWN_MIN, WAVE_HWT3_BOSS_COOLDOWN_MAX)
        else
            set aoe = WAVE_HWT3_AOE
            set damage = WAVE_HWT3_DAMAGE
            set WaveWaveformNextCastMs[hid] = nowMs + WaveWaveformRandomMsRange(WAVE_HWT3_COOLDOWN_MIN, WAVE_HWT3_COOLDOWN_MAX)
        endif
        call WaveWaveformLaunch(source, GetUnitX(target), GetUnitY(target), aoe, damage)
        return true
    endfunction

    private function Init takes nothing returns nothing
        set WaveWaveformNextCastMs = Table.create()
        set WaveWaveformActiveMissileByUnit = Table.create()
        call RegisterWaveDeathEvent(function WaveWaveformCleanupWaveDeath)
    endfunction
endlibrary
