library WaveProjectileBehaviors requires Missile, WaveProjectileConfig, SpellIndex

    globals
        private constant attacktype WAVE_PROJECTILE_ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype WAVE_PROJECTILE_DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
    endglobals

    private function CreateFxAtMissile takes Missile missile, string fxPath, string attach returns nothing
        local effect fx
        if fxPath == "" then
            return
        endif
        if missile.dummy != null then
            set fx = AddSpecialEffectTarget(fxPath, missile.dummy, attach)
        else
            set fx = AddSpecialEffect(fxPath, missile.x, missile.y)
        endif
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private function CreateFxAtWidget takes widget w, string fxPath, string attach returns nothing
        local effect fx
        if fxPath == "" then
            return
        endif
        set fx = AddSpecialEffectTarget(fxPath, w, attach)
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private function WaveProjectileCanHitUnit takes integer projectileId, Missile missile, unit hit returns boolean
        if hit == null or not UnitAlive(hit) then
            return false
        endif
        if not IsUnitEnemy(hit, missile.owner) then
            return false
        endif
        if not WaveProjectileCanHitStructures(projectileId) and IsUnitType(hit, UNIT_TYPE_STRUCTURE) then
            return false
        endif
        return true
    endfunction

    private function WaveProjectileDamageUnit takes Missile missile, unit hit, real damage returns nothing
        if damage <= 0. then
            return
        endif
        if missile.source == null or GetUnitTypeId(missile.source) == 0 then
            return
        endif
        call UnitDamageTarget(missile.source, hit, damage, false, false, WAVE_PROJECTILE_ATTACK_TYPE, WAVE_PROJECTILE_DAMAGE_TYPE, null)
    endfunction

    private function WaveProjectileDamageArea takes integer projectileId, Missile missile, real x, real y, real radius, real damage returns nothing
        local unit hit
        if radius <= 0. or damage <= 0. then
            return
        endif
        if missile.source == null or GetUnitTypeId(missile.source) == 0 then
            return
        endif
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, radius, null)
        loop
            set hit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen hit == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, hit)
            if WaveProjectileCanHitUnit(projectileId, missile, hit) then
                call WaveProjectileDamageUnit(missile, hit, damage)
            endif
        endloop
        set hit = null
    endfunction

    function WaveProjectileBehaviorOnUnit takes integer projectileId, Missile missile, unit hit, real damage returns boolean
        local integer family = WaveProjectileGetFamilyId(projectileId)
        if not WaveProjectileCanHitUnit(projectileId, missile, hit) then
            return false
        endif

        if family == WAVE_PROJECTILE_FAMILY_MISSILE or family == WAVE_PROJECTILE_FAMILY_CONTROL or family == WAVE_PROJECTILE_FAMILY_SPECIAL then
            call WaveProjectileDamageUnit(missile, hit, damage)
            call CreateFxAtWidget(hit, WaveProjectileGetImpactFxPath(projectileId), WaveProjectileGetImpactFxAttach(projectileId))
            return WaveProjectileStopsOnUnit(projectileId)
        endif
        return false
    endfunction

    function WaveProjectileBehaviorOnDestructable takes integer projectileId, Missile missile, destructable hit returns boolean
        if not WaveProjectileCollidesDestructable(projectileId) then
            return false
        endif
        call CreateFxAtMissile(missile, WaveProjectileGetImpactFxPath(projectileId), WaveProjectileGetImpactFxAttach(projectileId))
        return true
    endfunction

    function WaveProjectileBehaviorOnTerrain takes integer projectileId, Missile missile returns boolean
        if not WaveProjectileCollidesTerrain(projectileId) then
            return false
        endif
        call CreateFxAtMissile(missile, WaveProjectileGetImpactFxPath(projectileId), WaveProjectileGetImpactFxAttach(projectileId))
        return true
    endfunction

    function WaveProjectileBehaviorOnRemove takes integer projectileId, Missile missile returns nothing
        call CreateFxAtMissile(missile, WaveProjectileGetRemoveFxPath(projectileId), WaveProjectileGetRemoveFxAttach(projectileId))
    endfunction

    function WaveProjectileBehaviorOnFinish takes integer projectileId, Missile missile, real damage returns boolean
        local real radius = WaveProjectileGetFinishAoeRadius(projectileId)
        if radius > 0. then
            call WaveProjectileDamageArea(projectileId, missile, missile.x, missile.y, radius, damage)
            call CreateFxAtMissile(missile, WaveProjectileGetImpactFxPath(projectileId), WaveProjectileGetImpactFxAttach(projectileId))
        endif
        return true
    endfunction
endlibrary
