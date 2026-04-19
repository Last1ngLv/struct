library WaveMortarSkills initializer Init requires Table, TimerUtils, Missile, SpellIndex, WaveTest, WaveSkillVisuals

    globals
        public constant integer WAVE_HMTM_UNIT_ID = 'hmtm'
        public constant integer WAVE_HMTM_BOSS_UNIT_ID = 'zA05'

        public constant string WAVE_HMTM_PROJECTILE_MODEL = "Abilities\\Weapons\\Mortar\\MortarMissile.mdl"
        public constant string WAVE_HMTM_IMPACT_FX = "Abilities\\Spells\\Human\\FlameStrike\\FlameStrike1.mdl"
        public constant string WAVE_HMTM_TARGET_MARKER_MODEL = "war3mapImported\\Spell Marker Green.mdx"
        public constant real WAVE_HMTM_PROJECTILE_SPEED = 1350.0
        public constant real WAVE_HMTM_PROJECTILE_START_Z = 90.0
        public constant real WAVE_HMTM_PROJECTILE_ARC = 0.75
        public constant real WAVE_HMTM_CAST_RANGE = 2000.0

        public constant real WAVE_HMTM_IMPACT_DAMAGE = 15.0
        public constant real WAVE_HMTM_IMPACT_AOE = 250.0
        public constant real WAVE_HMTM_INITIAL_DELAY_MIN = 1.50
        public constant real WAVE_HMTM_INITIAL_DELAY_MAX = 2.50
        public constant real WAVE_HMTM_COOLDOWN = 3.50

        public constant real WAVE_HMTM_BOSS_IMPACT_DAMAGE = 30.0
        public constant real WAVE_HMTM_BOSS_IMPACT_AOE = 250.0
        public constant integer WAVE_HMTM_BOSS_VOLLEY_COUNT = 10
        public constant real WAVE_HMTM_BOSS_VOLLEY_INTERVAL = 0.20
        public constant real WAVE_HMTM_BOSS_INITIAL_DELAY_MIN = 3.00
        public constant real WAVE_HMTM_BOSS_INITIAL_DELAY_MAX = 4.00
        public constant real WAVE_HMTM_BOSS_COOLDOWN_MIN = 12.00
        public constant real WAVE_HMTM_BOSS_COOLDOWN_MAX = 15.00
        public constant real WAVE_HMTM_BARRAGE_TICK = 0.05

        private Table WaveMortarNextCastMs
        private Table WaveMortarActiveBarrageByUnit
        private timer WaveMortarBarrageTimer
        private boolean WaveMortarBarrageTimerRunning = false
        private integer WaveMortarBarrageHead = 0
        private integer WaveMortarBarrageCount = 0

        private real array WaveMortarMissileDamage
        private real array WaveMortarMissileAoe
        private real array WaveMortarMissileImpactX
        private real array WaveMortarMissileImpactY
        private integer array WaveMortarMissileMarker

        private integer array WaveMortarBarrageNext
        private integer array WaveMortarBarragePrev
        private integer array WaveMortarBarrageShotsRemaining
        private real array WaveMortarBarrageAccumulator
        private unit array WaveMortarBarrageSource
    endglobals

    private function WaveMortarSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveMortarRandomMsRange takes real minSec, real maxSec returns integer
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
        return WaveMortarSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveMortarUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveMortarTargetInCastRange takes unit source, unit target returns boolean
        local real dx
        local real dy
        if not WaveMortarUnitAlive(source) or not WaveMortarUnitAlive(target) then
            return false
        endif
        set dx = GetUnitX(target) - GetUnitX(source)
        set dy = GetUnitY(target) - GetUnitY(source)
        return dx*dx + dy*dy <= WAVE_HMTM_CAST_RANGE*WAVE_HMTM_CAST_RANGE
    endfunction

    private function WaveMortarCanDamageTarget takes Missile missile, unit hit returns boolean
        if hit == null or not UnitAlive(hit) then
            return false
        endif
        if not IsUnitEnemy(hit, missile.owner) then
            return false
        endif
        return true
    endfunction

    private function WaveMortarTravelDuration takes real sx, real sy, real tx, real ty returns real
        local real dx = tx - sx
        local real dy = ty - sy
        local real duration = SquareRoot(dx*dx + dy*dy)/WAVE_HMTM_PROJECTILE_SPEED
        if duration < 0.10 then
            set duration = 0.10
        endif
        return duration
    endfunction

    private function WaveMortarCreateImpactFx takes real x, real y returns nothing
        local effect fx = AddSpecialEffect(WAVE_HMTM_IMPACT_FX, x, y)
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private struct WaveMortarMissile extends array
        private static method onFinish takes Missile missile returns boolean
            local unit hit
            local unit source = missile.source
            if source != null and GetUnitTypeId(source) != 0 then
                call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, WaveMortarMissileImpactX[missile], WaveMortarMissileImpactY[missile], WaveMortarMissileAoe[missile], null)
                loop
                    set hit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                    exitwhen hit == null
                    call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, hit)
                    if WaveMortarCanDamageTarget(missile, hit) then
                        call UnitDamageTarget(source, hit, WaveMortarMissileDamage[missile], false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, null)
                    endif
                endloop
            endif
            call WaveMortarCreateImpactFx(WaveMortarMissileImpactX[missile], WaveMortarMissileImpactY[missile])
            if WaveMortarMissileMarker[missile] != 0 then
                call WaveSkillVisualDestroy(WaveMortarMissileMarker[missile])
                set WaveMortarMissileMarker[missile] = 0
            endif
            set hit = null
            set source = null
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            set WaveMortarMissileDamage[missile] = 0.0
            set WaveMortarMissileAoe[missile] = 0.0
            set WaveMortarMissileImpactX[missile] = 0.0
            set WaveMortarMissileImpactY[missile] = 0.0
            if WaveMortarMissileMarker[missile] != 0 then
                call WaveSkillVisualDestroy(WaveMortarMissileMarker[missile])
                set WaveMortarMissileMarker[missile] = 0
            endif
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function WaveMortarLaunchProjectile takes unit source, real tx, real ty, real damage, real aoe returns nothing
        local Missile missile
        local real sx
        local real sy
        if not WaveMortarUnitAlive(source) then
            return
        endif
        set sx = GetUnitX(source)
        set sy = GetUnitY(source)
        set missile = Missile.createXYZ(sx, sy, WAVE_HMTM_PROJECTILE_START_Z, tx, ty, WAVE_HMTM_PROJECTILE_START_Z)
        set missile.source = source
        set missile.owner = GetOwningPlayer(source)
        set missile.model = WAVE_HMTM_PROJECTILE_MODEL
        set missile.scale = WaveSkillVisualScaleForRadius(aoe)
        set missile.collision = 0.0
        call missile.setMovementSpeed(WAVE_HMTM_PROJECTILE_SPEED)
        set missile.arc = WAVE_HMTM_PROJECTILE_ARC

        set WaveMortarMissileDamage[missile] = damage
        set WaveMortarMissileAoe[missile] = aoe
        set WaveMortarMissileImpactX[missile] = tx
        set WaveMortarMissileImpactY[missile] = ty
        set WaveMortarMissileMarker[missile] = WaveSkillVisualCreateTimedMarker(tx, ty, 0.0, WAVE_HMTM_TARGET_MARKER_MODEL, aoe, WaveMortarTravelDuration(sx, sy, tx, ty))
        call WaveMortarMissile.launch(missile)
    endfunction

    private function WaveMortarBarrageAdd takes integer barrageId returns nothing
        set WaveMortarBarragePrev[barrageId] = 0
        set WaveMortarBarrageNext[barrageId] = WaveMortarBarrageHead
        if WaveMortarBarrageHead != 0 then
            set WaveMortarBarragePrev[WaveMortarBarrageHead] = barrageId
        endif
        set WaveMortarBarrageHead = barrageId
    endfunction

    private function WaveMortarBarrageRemove takes integer barrageId returns nothing
        local integer p = WaveMortarBarragePrev[barrageId]
        local integer n = WaveMortarBarrageNext[barrageId]
        if p != 0 then
            set WaveMortarBarrageNext[p] = n
        else
            set WaveMortarBarrageHead = n
        endif
        if n != 0 then
            set WaveMortarBarragePrev[n] = p
        endif
        set WaveMortarBarragePrev[barrageId] = 0
        set WaveMortarBarrageNext[barrageId] = 0
    endfunction

    private function WaveMortarBarrageDestroy takes integer barrageId returns nothing
        local unit source = WaveMortarBarrageSource[barrageId]
        local integer hid = 0
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
            call PauseUnit(source, false)
        endif
        call WaveMortarBarrageRemove(barrageId)
        if hid != 0 and WaveMortarActiveBarrageByUnit.has(hid) and WaveMortarActiveBarrageByUnit[hid] == barrageId then
            call WaveMortarActiveBarrageByUnit.remove(hid)
        endif
        set WaveMortarBarrageShotsRemaining[barrageId] = 0
        set WaveMortarBarrageAccumulator[barrageId] = 0.0
        set WaveMortarBarrageSource[barrageId] = null
    endfunction

    private function WaveMortarFireBossRound takes integer barrageId returns nothing
        local unit source = WaveMortarBarrageSource[barrageId]
        local integer playerId = 0
        local unit hero
        local boolean fired = false
        if not WaveMortarUnitAlive(source) then
            set source = null
            return
        endif
        call SetUnitAnimation(source, "attack")
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set hero = PlayerHero[playerId]
            if WaveMortarUnitAlive(hero) and IsUnitType(hero, UNIT_TYPE_HERO) and IsUnitEnemy(hero, GetOwningPlayer(source)) then
                call WaveMortarLaunchProjectile(source, GetUnitX(hero), GetUnitY(hero), WAVE_HMTM_BOSS_IMPACT_DAMAGE, WAVE_HMTM_BOSS_IMPACT_AOE)
                set fired = true
            endif
            set playerId = playerId + 1
        endloop
        if not fired then
            call WaveMortarLaunchProjectile(source, GetUnitX(source), GetUnitY(source), WAVE_HMTM_BOSS_IMPACT_DAMAGE, WAVE_HMTM_BOSS_IMPACT_AOE)
        endif
        set hero = null
        set source = null
    endfunction

    private function WaveMortarOnBarrageTick takes nothing returns nothing
        local integer barrageId = WaveMortarBarrageHead
        local integer nextBarrageId
        loop
            exitwhen barrageId == 0
            set nextBarrageId = WaveMortarBarrageNext[barrageId]
            if not WaveMortarUnitAlive(WaveMortarBarrageSource[barrageId]) then
                call WaveMortarBarrageDestroy(barrageId)
            else
                set WaveMortarBarrageAccumulator[barrageId] = WaveMortarBarrageAccumulator[barrageId] + WAVE_HMTM_BARRAGE_TICK
                loop
                    exitwhen WaveMortarBarrageShotsRemaining[barrageId] <= 0 or WaveMortarBarrageAccumulator[barrageId] < WAVE_HMTM_BOSS_VOLLEY_INTERVAL
                    set WaveMortarBarrageAccumulator[barrageId] = WaveMortarBarrageAccumulator[barrageId] - WAVE_HMTM_BOSS_VOLLEY_INTERVAL
                    call WaveMortarFireBossRound(barrageId)
                    set WaveMortarBarrageShotsRemaining[barrageId] = WaveMortarBarrageShotsRemaining[barrageId] - 1
                endloop
                if WaveMortarBarrageShotsRemaining[barrageId] <= 0 then
                    call WaveMortarBarrageDestroy(barrageId)
                endif
            endif
            set barrageId = nextBarrageId
        endloop
        if WaveMortarBarrageHead == 0 and WaveMortarBarrageTimerRunning then
            call PauseTimer(WaveMortarBarrageTimer)
            set WaveMortarBarrageTimerRunning = false
        endif
    endfunction

    private function WaveMortarEnsureBarrageTimer takes nothing returns nothing
        if not WaveMortarBarrageTimerRunning then
            set WaveMortarBarrageTimerRunning = true
            call TimerStart(WaveMortarBarrageTimer, WAVE_HMTM_BARRAGE_TICK, true, function WaveMortarOnBarrageTick)
        endif
    endfunction

    private function WaveMortarStartBossBarrage takes unit source returns nothing
        local integer barrageId = WaveMortarBarrageCount + 1
        local integer hid = GetHandleId(source)
        set WaveMortarBarrageCount = barrageId
        set WaveMortarBarrageShotsRemaining[barrageId] = WAVE_HMTM_BOSS_VOLLEY_COUNT
        set WaveMortarBarrageAccumulator[barrageId] = WAVE_HMTM_BOSS_VOLLEY_INTERVAL
        set WaveMortarBarrageSource[barrageId] = source
        call WaveMortarBarrageAdd(barrageId)
        set WaveMortarActiveBarrageByUnit[hid] = barrageId
        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "attack")
        call PauseUnit(source, true)
        call WaveMortarEnsureBarrageTimer()
    endfunction

    private function WaveMortarCleanupWaveDeath takes nothing returns nothing
        local unit deadUnit = GetWaveEventUnit()
        local integer hid
        local integer barrageId
        if deadUnit == null or GetUnitTypeId(deadUnit) == 0 then
            return
        endif
        if GetUnitTypeId(deadUnit) == WAVE_HMTM_UNIT_ID or GetUnitTypeId(deadUnit) == WAVE_HMTM_BOSS_UNIT_ID then
            set hid = GetHandleId(deadUnit)
            if hid != 0 and WaveMortarNextCastMs.has(hid) then
                call WaveMortarNextCastMs.remove(hid)
            endif
            if hid != 0 and WaveMortarActiveBarrageByUnit.has(hid) then
                set barrageId = WaveMortarActiveBarrageByUnit[hid]
                call WaveMortarBarrageDestroy(barrageId)
            endif
        endif
    endfunction

    function WaveMortarSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local boolean isBoss = false
        if not WaveMortarUnitAlive(source) then
            return false
        endif
        if GetUnitTypeId(source) == WAVE_HMTM_BOSS_UNIT_ID then
            set isBoss = true
        elseif GetUnitTypeId(source) != WAVE_HMTM_UNIT_ID then
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif
        if not WaveMortarTargetInCastRange(source, target) then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif

        if isBoss and WaveMortarActiveBarrageByUnit.has(hid) then
            return true
        endif

        if not WaveMortarNextCastMs.has(hid) then
            if isBoss then
                set WaveMortarNextCastMs[hid] = nowMs + WaveMortarRandomMsRange(WAVE_HMTM_BOSS_INITIAL_DELAY_MIN, WAVE_HMTM_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveMortarNextCastMs[hid] = nowMs + WaveMortarRandomMsRange(WAVE_HMTM_INITIAL_DELAY_MIN, WAVE_HMTM_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WaveMortarNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        if isBoss then
            call WaveMortarStartBossBarrage(source)
            set WaveMortarNextCastMs[hid] = nowMs + WaveMortarRandomMsRange(WAVE_HMTM_BOSS_COOLDOWN_MIN, WAVE_HMTM_BOSS_COOLDOWN_MAX)
            return true
        endif

        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "attack")
        call WaveMortarLaunchProjectile(source, GetUnitX(target), GetUnitY(target), WAVE_HMTM_IMPACT_DAMAGE, WAVE_HMTM_IMPACT_AOE)
        set WaveMortarNextCastMs[hid] = nowMs + WaveMortarSecToMs(WAVE_HMTM_COOLDOWN)
        return true
    endfunction

    private function Init takes nothing returns nothing
        set WaveMortarNextCastMs = Table.create()
        set WaveMortarActiveBarrageByUnit = Table.create()
        set WaveMortarBarrageTimer = NewTimer()
        call SetTimerDebugTag(WaveMortarBarrageTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)
        call RegisterWaveDeathEvent(function WaveMortarCleanupWaveDeath)
    endfunction
endlibrary
