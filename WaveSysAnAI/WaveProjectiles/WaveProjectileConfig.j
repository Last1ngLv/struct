library WaveProjectileConfig initializer Init

    globals
        constant integer WAVE_PROJECTILE_FAMILY_MISSILE = 1
        constant integer WAVE_PROJECTILE_FAMILY_CONTROL = 2
        constant integer WAVE_PROJECTILE_FAMILY_SPECIAL = 10

        public constant integer WAVE_PROJECTILE_TYPE_BASIC = 1
        public constant integer WAVE_PROJECTILE_TYPE_DEATH_BURST = 2
        constant integer WAVE_PROJECTILE_TYPE_HRIF = 3

        constant real WAVE_HRIF_PROJECTILE_SPEED = 1000.
        public constant real WAVE_HRIF_PROJECTILE_DISTANCE = 1750.
        public constant real WAVE_HRIF_PROJECTILE_COLLISION = 50.
        public constant real WAVE_HRIF_PROJECTILE_SCALE = 1.00
        public constant real WAVE_HRIF_PROJECTILE_START_Z = 75.
        constant real WAVE_HRIF_PROJECTILE_DAMAGE = 5.
        constant real WAVE_HRIF_PROJECTILE_FINISH_AOE = 100.
        public constant string WAVE_HRIF_PROJECTILE_MODEL = "war3mapImported\\Shock Blast Orange.mdx"
        public constant string WAVE_HRIF_PROJECTILE_IMPACT_FX = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"

        private constant string WAVE_PROJECTILE_DEFAULT_ATTACH_POINT = "origin"

        private boolean array registered
        private integer array familyId
        private string array modelPath
        private real array moveSpeed
        private real array travelDistance
        private real array collisionSize
        private real array scaleValue
        private real array startZ
        private real array baseDamage
        private boolean array collideDestructable
        private boolean array collideTerrain
        private boolean array stopOnUnit
        private boolean array hitStructures
        private string array impactFxPath
        private string array impactFxAttach
        private string array removeFxPath
        private string array removeFxAttach
        private real array finishAoeRadius
    endglobals

    private function NormalizeAttachPoint takes string attach returns string
        if attach == "" then
            return WAVE_PROJECTILE_DEFAULT_ATTACH_POINT
        endif
        return attach
    endfunction

    function WaveProjectileRegister takes integer projectileId, integer family, string model, real speed, real distance, real collision, real scale, real z, real damage returns nothing
        if projectileId <= 0 then
            return
        endif
        set registered[projectileId] = true
        set familyId[projectileId] = family
        set modelPath[projectileId] = model
        set moveSpeed[projectileId] = speed
        set travelDistance[projectileId] = distance
        set collisionSize[projectileId] = collision
        set scaleValue[projectileId] = scale
        set startZ[projectileId] = z
        set baseDamage[projectileId] = damage
        set collideDestructable[projectileId] = true
        set collideTerrain[projectileId] = true
        set stopOnUnit[projectileId] = true
        set hitStructures[projectileId] = false
        set impactFxPath[projectileId] = ""
        set impactFxAttach[projectileId] = WAVE_PROJECTILE_DEFAULT_ATTACH_POINT
        set removeFxPath[projectileId] = ""
        set removeFxAttach[projectileId] = WAVE_PROJECTILE_DEFAULT_ATTACH_POINT
        set finishAoeRadius[projectileId] = 0.
    endfunction

    function WaveProjectileSetCollisionProfile takes integer projectileId, boolean collideDestFlag, boolean collideTerrainFlag, boolean stopOnUnitFlag, boolean hitStructuresFlag returns nothing
        if projectileId <= 0 or not registered[projectileId] then
            return
        endif
        set collideDestructable[projectileId] = collideDestFlag
        set collideTerrain[projectileId] = collideTerrainFlag
        set stopOnUnit[projectileId] = stopOnUnitFlag
        set hitStructures[projectileId] = hitStructuresFlag
    endfunction

    function WaveProjectileSetImpactFx takes integer projectileId, string fxPath, string attach returns nothing
        if projectileId <= 0 or not registered[projectileId] then
            return
        endif
        set impactFxPath[projectileId] = fxPath
        set impactFxAttach[projectileId] = NormalizeAttachPoint(attach)
    endfunction

    function WaveProjectileSetRemoveFx takes integer projectileId, string fxPath, string attach returns nothing
        if projectileId <= 0 or not registered[projectileId] then
            return
        endif
        set removeFxPath[projectileId] = fxPath
        set removeFxAttach[projectileId] = NormalizeAttachPoint(attach)
    endfunction

    function WaveProjectileSetFinishAoe takes integer projectileId, real radius returns nothing
        if projectileId <= 0 or not registered[projectileId] then
            return
        endif
        if radius < 0. then
            set radius = 0.
        endif
        set finishAoeRadius[projectileId] = radius
    endfunction

    function WaveProjectileIsRegistered takes integer projectileId returns boolean
        if projectileId <= 0 then
            return false
        endif
        return registered[projectileId]
    endfunction

    function WaveProjectileGetFamilyId takes integer projectileId returns integer
        return familyId[projectileId]
    endfunction

    function WaveProjectileGetModelPath takes integer projectileId returns string
        return modelPath[projectileId]
    endfunction

    function WaveProjectileGetMoveSpeed takes integer projectileId returns real
        return moveSpeed[projectileId]
    endfunction

    function WaveProjectileGetTravelDistance takes integer projectileId returns real
        return travelDistance[projectileId]
    endfunction

    function WaveProjectileGetCollisionSize takes integer projectileId returns real
        return collisionSize[projectileId]
    endfunction

    function WaveProjectileGetScale takes integer projectileId returns real
        return scaleValue[projectileId]
    endfunction

    function WaveProjectileGetStartZ takes integer projectileId returns real
        return startZ[projectileId]
    endfunction

    function WaveProjectileGetBaseDamage takes integer projectileId returns real
        return baseDamage[projectileId]
    endfunction

    function WaveProjectileCollidesDestructable takes integer projectileId returns boolean
        return collideDestructable[projectileId]
    endfunction

    function WaveProjectileCollidesTerrain takes integer projectileId returns boolean
        return collideTerrain[projectileId]
    endfunction

    function WaveProjectileStopsOnUnit takes integer projectileId returns boolean
        return stopOnUnit[projectileId]
    endfunction

    function WaveProjectileCanHitStructures takes integer projectileId returns boolean
        return hitStructures[projectileId]
    endfunction

    function WaveProjectileGetImpactFxPath takes integer projectileId returns string
        return impactFxPath[projectileId]
    endfunction

    function WaveProjectileGetImpactFxAttach takes integer projectileId returns string
        return impactFxAttach[projectileId]
    endfunction

    function WaveProjectileGetRemoveFxPath takes integer projectileId returns string
        return removeFxPath[projectileId]
    endfunction

    function WaveProjectileGetRemoveFxAttach takes integer projectileId returns string
        return removeFxAttach[projectileId]
    endfunction

    function WaveProjectileGetFinishAoeRadius takes integer projectileId returns real
        return finishAoeRadius[projectileId]
    endfunction

    private function Init takes nothing returns nothing
        call WaveProjectileRegister(WAVE_PROJECTILE_TYPE_BASIC, WAVE_PROJECTILE_FAMILY_MISSILE, "Miss\\Shot Blue.mdx", 1400., 1600., 96., 1.00, 75., 25.)
        call WaveProjectileSetCollisionProfile(WAVE_PROJECTILE_TYPE_BASIC, true, true, true, false)
        call WaveProjectileSetImpactFx(WAVE_PROJECTILE_TYPE_BASIC, "Abilities\\Weapons\\Bolt\\BoltImpact.mdl", "origin")

        call WaveProjectileRegister(WAVE_PROJECTILE_TYPE_DEATH_BURST, WAVE_PROJECTILE_FAMILY_SPECIAL, "Abilities\\Weapons\\SentinelMissile\\SentinelMissile.mdl", 1200., 1500., 96., 1.00, 75., 35.)
        call WaveProjectileSetCollisionProfile(WAVE_PROJECTILE_TYPE_DEATH_BURST, true, true, true, false)
        call WaveProjectileSetImpactFx(WAVE_PROJECTILE_TYPE_DEATH_BURST, "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl", "origin")
        call WaveProjectileSetRemoveFx(WAVE_PROJECTILE_TYPE_DEATH_BURST, "Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", "origin")

        call WaveProjectileRegister(WAVE_PROJECTILE_TYPE_HRIF, WAVE_PROJECTILE_FAMILY_MISSILE, WAVE_HRIF_PROJECTILE_MODEL, WAVE_HRIF_PROJECTILE_SPEED, WAVE_HRIF_PROJECTILE_DISTANCE, WAVE_HRIF_PROJECTILE_COLLISION, WAVE_HRIF_PROJECTILE_SCALE, WAVE_HRIF_PROJECTILE_START_Z, WAVE_HRIF_PROJECTILE_DAMAGE)
        call WaveProjectileSetCollisionProfile(WAVE_PROJECTILE_TYPE_HRIF, false, false, false, false)
        call WaveProjectileSetImpactFx(WAVE_PROJECTILE_TYPE_HRIF, WAVE_HRIF_PROJECTILE_IMPACT_FX, "origin")
        call WaveProjectileSetFinishAoe(WAVE_PROJECTILE_TYPE_HRIF, WAVE_HRIF_PROJECTILE_FINISH_AOE)
    endfunction
endlibrary
