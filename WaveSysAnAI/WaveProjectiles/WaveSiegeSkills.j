library WaveSiegeSkills initializer Init requires Table, TimerUtils, Missile, SpellIndex, WaveTest, TerrainPathability, WaveProjectileConfig, WaveSkillVisuals, PlayerHeroState

    globals
        public constant integer WAVE_HMIL_UNIT_ID = 'hmil'
        public constant integer WAVE_HMIL_BOSS_UNIT_ID = 'zA01'

        public constant string WAVE_HMIL_PROJECTILE_MODEL = "Abilities\\Weapons\\Mortar\\MortarMissile.mdl"
        public constant string WAVE_HMIL_IMPACT_FX = "Abilities\\Spells\\Human\\FlameStrike\\FlameStrike1.mdl"
        public constant string WAVE_HMIL_TARGET_MARKER_MODEL = "war3mapImported\\Spell Marker Green.mdx"
        public constant real WAVE_HMIL_PROJECTILE_SPEED = 900.0
        public constant real WAVE_HMIL_PROJECTILE_START_Z = 90.0
        public constant real WAVE_HMIL_PROJECTILE_ARC = 0.75
        public constant real WAVE_HMIL_IMPACT_DAMAGE = 5.0
        public constant real WAVE_HMIL_IMPACT_AOE = 150.0
        public constant real WAVE_HMIL_INITIAL_DELAY_MIN = 2.50
        public constant real WAVE_HMIL_INITIAL_DELAY_MAX = 4.50
        public constant real WAVE_HMIL_COOLDOWN_MIN = 8.00
        public constant real WAVE_HMIL_COOLDOWN_MAX = 12.00

        public constant real WAVE_HMIL_BOSS_IMPACT_DAMAGE = 10.0
        public constant real WAVE_HMIL_BOSS_IMPACT_AOE = 360.0
        public constant integer WAVE_HMIL_BOSS_PROJECTILE_COUNT = 2
        public constant real WAVE_HMIL_BOSS_SECONDARY_RANDOM_RADIUS = 275.0
        public constant real WAVE_HMIL_BOSS_INITIAL_DELAY_MIN = 4.00
        public constant real WAVE_HMIL_BOSS_INITIAL_DELAY_MAX = 6.00
        public constant real WAVE_HMIL_BOSS_COOLDOWN_MIN = 15.00
        public constant real WAVE_HMIL_BOSS_COOLDOWN_MAX = 20.00

        private Table WaveSiegeNextCastMs

        private real array WaveSiegeMissileDamage
        private real array WaveSiegeMissileAoe
        private real array WaveSiegeMissileImpactX
        private real array WaveSiegeMissileImpactY
        private integer array WaveSiegeMissileMarker
    endglobals

    private function WaveSiegeSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveSiegeRandomMsRange takes real minSec, real maxSec returns integer
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
        return WaveSiegeSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveSiegeUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveSiegeIsHmil takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HMIL_UNIT_ID
    endfunction

    private function WaveSiegeIsHmilBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HMIL_BOSS_UNIT_ID
    endfunction

    private function WaveSiegeCanDamageTarget takes Missile missile, unit hit returns boolean
        if hit == null or not UnitAlive(hit) then
            return false
        endif
        if not IsUnitEnemy(hit, missile.owner) then
            return false
        endif
        return true
    endfunction

    private function WaveSiegeCreateImpactFx takes real x, real y returns nothing
        local effect fx = AddSpecialEffect(WAVE_HMIL_IMPACT_FX, x, y)
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private struct WaveSiegeMissile extends array
        private static method onFinish takes Missile missile returns boolean
            local unit hit
            local unit source = missile.source
            if source != null and GetUnitTypeId(source) != 0 then
                call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, WaveSiegeMissileImpactX[missile], WaveSiegeMissileImpactY[missile], WaveSiegeMissileAoe[missile], null)
                loop
                    set hit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                    exitwhen hit == null
                    call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, hit)
                    if WaveSiegeCanDamageTarget(missile, hit) then
                        call UnitDamageTarget(source, hit, WaveSiegeMissileDamage[missile], false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, null)
                    endif
                endloop
            endif
            call WaveSiegeCreateImpactFx(WaveSiegeMissileImpactX[missile], WaveSiegeMissileImpactY[missile])
            if WaveSiegeMissileMarker[missile] != 0 then
                call WaveSkillVisualDestroy(WaveSiegeMissileMarker[missile])
                set WaveSiegeMissileMarker[missile] = 0
            endif
            set hit = null
            set source = null
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            set WaveSiegeMissileDamage[missile] = 0.0
            set WaveSiegeMissileAoe[missile] = 0.0
            set WaveSiegeMissileImpactX[missile] = 0.0
            set WaveSiegeMissileImpactY[missile] = 0.0
            if WaveSiegeMissileMarker[missile] != 0 then
                call WaveSkillVisualDestroy(WaveSiegeMissileMarker[missile])
                set WaveSiegeMissileMarker[missile] = 0
            endif
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function WaveSiegeLaunchProjectile takes unit source, real tx, real ty, real damage, real aoe returns nothing
        local Missile missile
        local real sx
        local real sy
        if not WaveSiegeUnitAlive(source) then
            return
        endif
        set sx = GetUnitX(source)
        set sy = GetUnitY(source)
        set missile = Missile.createXYZ(sx, sy, WAVE_HMIL_PROJECTILE_START_Z, tx, ty, WAVE_HMIL_PROJECTILE_START_Z)
        set missile.source = source
        set missile.owner = GetOwningPlayer(source)
        set missile.model = WAVE_HMIL_PROJECTILE_MODEL
        set missile.scale = 1.0
        set missile.collision = 0.0
        call missile.setMovementSpeed(WAVE_HMIL_PROJECTILE_SPEED)
        set missile.arc = WAVE_HMIL_PROJECTILE_ARC

        set WaveSiegeMissileDamage[missile] = damage
        set WaveSiegeMissileAoe[missile] = aoe
        set WaveSiegeMissileImpactX[missile] = tx
        set WaveSiegeMissileImpactY[missile] = ty
        set WaveSiegeMissileMarker[missile] = WaveSkillVisualCreateTimedMarker(tx, ty, 0.0, WAVE_HMIL_TARGET_MARKER_MODEL, aoe, 30.0)
        call WaveSiegeMissile.launch(missile)
    endfunction

    private function WaveSiegeLaunchBossProjectiles takes unit source, unit primaryTarget returns nothing
        local integer launched = 0
        local integer i = 0
        local unit hero
        local real tx
        local real ty
        local real angle
        local real radius
        if not WaveSiegeUnitAlive(source) then
            return
        endif
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS or launched >= WAVE_HMIL_BOSS_PROJECTILE_COUNT
            set hero = PlayerHero[i]
            if WaveSiegeUnitAlive(hero) and IsUnitEnemy(hero, GetOwningPlayer(source)) then
                call WaveSiegeLaunchProjectile(source, GetUnitX(hero), GetUnitY(hero), WAVE_HMIL_BOSS_IMPACT_DAMAGE, WAVE_HMIL_BOSS_IMPACT_AOE)
                set launched = launched + 1
            endif
            set i = i + 1
        endloop

        if launched < WAVE_HMIL_BOSS_PROJECTILE_COUNT and WaveSiegeUnitAlive(primaryTarget) then
            loop
                exitwhen launched >= WAVE_HMIL_BOSS_PROJECTILE_COUNT
                set angle = GetRandomReal(0.0, 360.0)*bj_DEGTORAD
                set radius = GetRandomReal(96.0, WAVE_HMIL_BOSS_SECONDARY_RANDOM_RADIUS)
                set tx = GetUnitX(primaryTarget) + radius*Cos(angle)
                set ty = GetUnitY(primaryTarget) + radius*Sin(angle)
                call WaveSiegeLaunchProjectile(source, tx, ty, WAVE_HMIL_BOSS_IMPACT_DAMAGE, WAVE_HMIL_BOSS_IMPACT_AOE)
                set launched = launched + 1
            endloop
        endif
        set hero = null
    endfunction

    private function WaveSiegeCleanupWaveDeath takes nothing returns nothing
        local unit deadUnit = GetWaveEventUnit()
        local integer hid
        if deadUnit == null or GetUnitTypeId(deadUnit) == 0 then
            return
        endif
        if GetUnitTypeId(deadUnit) == WAVE_HMIL_UNIT_ID or GetUnitTypeId(deadUnit) == WAVE_HMIL_BOSS_UNIT_ID then
            if WAVE_DEBUG_ENABLED then
                call WaveDebugLog("WaveSiegeCleanupWaveDeath enter " + WaveDeathDebugContextSummary())
            endif
            set hid = GetHandleId(deadUnit)
            if hid != 0 and WaveSiegeNextCastMs.has(hid) then
                call WaveSiegeNextCastMs.remove(hid)
            endif
            if WAVE_DEBUG_ENABLED then
                call WaveDebugLog("WaveSiegeCleanupWaveDeath exit source " + WaveDeathDebugContextSummary())
            endif
        endif
    endfunction

    function WaveSiegeSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        return false
    endfunction

    private function Init takes nothing returns nothing
        set WaveSiegeNextCastMs = Table.create()
        call RegisterWaveDeathEvent(function WaveSiegeCleanupWaveDeath)
    endfunction
endlibrary

