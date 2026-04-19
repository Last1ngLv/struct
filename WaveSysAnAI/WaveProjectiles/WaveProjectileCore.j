library WaveProjectileCore requires Missile, WaveProjectileConfig, WaveProjectileBehaviors

    globals
        private integer array WaveProjectileTypeByMissile
        private real array WaveProjectileDamageByMissile
    endglobals

    private keyword WaveProjectileStruct

    private function WaveProjectileClampDamage takes integer projectileId, real damage returns real
        if damage > 0. then
            return damage
        endif
        return WaveProjectileGetBaseDamage(projectileId)
    endfunction

    private function WaveProjectileApplyTemplate takes integer projectileId, unit source, Missile missile, real damage returns nothing
        set missile.source = source
        set missile.owner = GetOwningPlayer(source)
        set missile.model = WaveProjectileGetModelPath(projectileId)
        set missile.scale = WaveProjectileGetScale(projectileId)
        set missile.collision = WaveProjectileGetCollisionSize(projectileId)
        set missile.damage = WaveProjectileClampDamage(projectileId, damage)
        call missile.setMovementSpeed(WaveProjectileGetMoveSpeed(projectileId))

        set WaveProjectileTypeByMissile[missile] = projectileId
        set WaveProjectileDamageByMissile[missile] = missile.damage
    endfunction

    private struct WaveProjectileStruct extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            local integer projectileId = WaveProjectileTypeByMissile[missile]
            return WaveProjectileBehaviorOnUnit(projectileId, missile, hit, WaveProjectileDamageByMissile[missile])
        endmethod

        private static method onDestructable takes Missile missile, destructable hit returns boolean
            local integer projectileId = WaveProjectileTypeByMissile[missile]
            return WaveProjectileBehaviorOnDestructable(projectileId, missile, hit)
        endmethod

        private static method onTerrain takes Missile missile returns boolean
            local integer projectileId = WaveProjectileTypeByMissile[missile]
            return WaveProjectileBehaviorOnTerrain(projectileId, missile)
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local integer projectileId = WaveProjectileTypeByMissile[missile]
            return WaveProjectileBehaviorOnFinish(projectileId, missile, WaveProjectileDamageByMissile[missile])
        endmethod

        private static method onRemove takes Missile missile returns boolean
            local integer projectileId = WaveProjectileTypeByMissile[missile]
            call WaveProjectileBehaviorOnRemove(projectileId, missile)
            set WaveProjectileTypeByMissile[missile] = 0
            set WaveProjectileDamageByMissile[missile] = 0.
            return true
        endmethod

        implement MissileStruct
    endstruct

    function WaveProjectileLaunch takes integer projectileId, unit source, real startX, real startY, real angleInRadians, real damage returns Missile
        local Missile missile
        local real z
        if source == null or GetUnitTypeId(source) == 0 then
            return 0
        endif
        if not WaveProjectileIsRegistered(projectileId) then
            return 0
        endif
        set z = WaveProjectileGetStartZ(projectileId)
        set missile = Missile.create(startX, startY, z, angleInRadians, WaveProjectileGetTravelDistance(projectileId), z)
        call WaveProjectileApplyTemplate(projectileId, source, missile, damage)
        call WaveProjectileStruct.launch(missile)
        return missile
    endfunction

    function WaveProjectileLaunchFromSourceAngle takes integer projectileId, unit source, real angleInRadians, real damage returns Missile
        if source == null or GetUnitTypeId(source) == 0 then
            return 0
        endif
        return WaveProjectileLaunch(projectileId, source, GetUnitX(source), GetUnitY(source), angleInRadians, damage)
    endfunction

    function WaveProjectileLaunchFromSourceToPoint takes integer projectileId, unit source, real tx, real ty, real damage returns Missile
        local real x
        local real y
        if source == null or GetUnitTypeId(source) == 0 then
            return 0
        endif
        set x = GetUnitX(source)
        set y = GetUnitY(source)
        return WaveProjectileLaunch(projectileId, source, x, y, Atan2(ty - y, tx - x), damage)
    endfunction

    function WaveProjectileLaunchFromSourceToUnit takes integer projectileId, unit source, unit target, real damage returns Missile
        if target == null or GetUnitTypeId(target) == 0 then
            return 0
        endif
        return WaveProjectileLaunchFromSourceToPoint(projectileId, source, GetUnitX(target), GetUnitY(target), damage)
    endfunction

    function WaveProjectileLaunchToPointExact takes integer projectileId, unit source, real startX, real startY, real tx, real ty, real damage returns Missile
        local Missile missile
        local real z
        if source == null or GetUnitTypeId(source) == 0 then
            return 0
        endif
        if not WaveProjectileIsRegistered(projectileId) then
            return 0
        endif
        set z = WaveProjectileGetStartZ(projectileId)
        set missile = Missile.createXYZ(startX, startY, z, tx, ty, z)
        call WaveProjectileApplyTemplate(projectileId, source, missile, damage)
        call WaveProjectileStruct.launch(missile)
        return missile
    endfunction

    function WaveProjectileLaunchFromSourceToPointExact takes integer projectileId, unit source, real tx, real ty, real damage returns Missile
        if source == null or GetUnitTypeId(source) == 0 then
            return 0
        endif
        return WaveProjectileLaunchToPointExact(projectileId, source, GetUnitX(source), GetUnitY(source), tx, ty, damage)
    endfunction
endlibrary
