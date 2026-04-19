//TESH.scrollpos=0
//TESH.alwaysfold=0
library UnitTypeMissileConfig initializer Init uses UnitTypeMissileLoadout
//******************************************************************************
// Configuracion de missile por tipo de unidad.
//******************************************************************************
    globals
        private constant real    DEFAULT_SPEED = 1500.
        private constant real    DEFAULT_DAMAGE = 10.
        private constant string  DEFAULT_MISSILE_MODEL = "Miss\\Shot Blue.mdx"
        private constant string  DEFAULT_OVERLAY_MODEL = "Miss\\Shot II Blue.mdx"

        private constant boolean DEFAULT_USE_RAPID_FIRE = false
        private constant real    DEFAULT_RAPID_FIRE_DURATION = 1.20
        private constant real    DEFAULT_RAPID_FIRE_INTERVAL = 0.40

        private constant string  DEFAULT_CAST_ANIMATION = "attack"
        private constant real    DEFAULT_CAST_ANIMATION_DELAY = 0.03
        private constant real    DEFAULT_CAST_ANIMATION_TIME_SCALE = 1.25
        private constant string  DEFAULT_CASTER_WAIT_FX = "war3mapImported\\Bondage Blue SD.mdx"

        private constant string  DEFAULT_DUMMY_MODEL = "war3mapImported\\Spell Marker Red.mdx"
        private constant string  DEFAULT_DUMMY_IMPACT_FX = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        private constant real    DEFAULT_DUMMY_SCALE = 1.0
        private constant real    DEFAULT_DUMMY_AREA = 200.
        private constant real    DEFAULT_DUMMY_DELAY = 1.00

        private constant real    DEFAULT_MISSILE_ARC = 200.
        private constant real    DEFAULT_MISSILE_START_Z = 75.
        private constant real    DEFAULT_MISSILE_FLY_HEIGHT = 0.
        private constant real    DEFAULT_MISSILE_COLLISION = 100.
        private constant boolean DEFAULT_IMPACT_ON_PATH = false
        private constant boolean DEFAULT_SPECIAL_ENABLED = false
        private constant integer DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS = 3
        private constant string  DEFAULT_SPECIAL_MISSILE_MODEL = ""
        private constant string  DEFAULT_SPECIAL_OVERLAY_MODEL = ""
        private constant real    DEFAULT_SPECIAL_DAMAGE_MULT = 2.00
        private constant real    DEFAULT_SPECIAL_AREA_MULT = 2.00
        private constant real    DEFAULT_SPECIAL_SPEED_MULT = 1.00
        private constant real    DEFAULT_SPECIAL_MISSILE_SCALE_MULT = 1.00
        private constant real    DEFAULT_SPECIAL_DUMMY_SCALE_MULT = 2.00
        private constant string  DEFAULT_SOUND_CAST_START = ""
        private constant string  DEFAULT_SOUND_WAIT_START = ""
        private constant string  DEFAULT_SOUND_WAIT_END = ""
        private constant string  DEFAULT_SOUND_IMPACT = ""
        private constant string  DEFAULT_SOUND_LAST_MISSILE = ""
        private constant string  DEFAULT_SOUND_DUMMY_CLEAR = ""
        private constant string  DEFAULT_SOUND_INTERRUPTED = ""
        private constant string  DEFAULT_SOUND_CHANNEL_COMPLETE = ""
        private constant real    DEFAULT_MISSILE_SCALE = 1.0
        private constant real    DEFAULT_MANA_COST = 0.
    endglobals

    private function Configure_hpea takes nothing returns nothing
        local integer unitType = 'hpea'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        // Overrides de hpea aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hmil takes nothing returns nothing
        local integer unitType = 'hmtm'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        
        // Overrides de hmil aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hfoo takes nothing returns nothing
        local integer unitType = 'hfoo'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        // Overrides de hfoo aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hrif takes nothing returns nothing
        local integer unitType = 'hrif'
        local real speed = 1600.
        local real damage = 10.
        local string missileModel = "war3mapImported\\Shock Blast Orange.mdx"
        local string overlayModel = "war3mapImported\\Shock Blast Orange.mdx"

        local boolean useRapidFire = false
        local real rapidFireDuration = 0.55
        local real rapidFireInterval = 0.25

        local string castAnimation = "attack"
        local real castAnimationDelay = 0.03
        local real castAnimationTimeScale = 1.25
        local string casterWaitFx = "war3mapImported\\Bondage Blue SD.mdx"

        local string dummyModel = "war3mapImported\\Spell Marker Green.mdx"
        local string dummyImpactFx = ""
        local real dummyScale = 1.0
        local real dummyArea = 100.
        local real dummyDelay = 1.00

        local real missileArc = 0.
        local real missileStartZ = 75.
        local real missileFlyHeight = 0.
        local real missileCollision = 100.
        local real missileScale = 1.0

        local boolean impactOnPath = true
        local boolean specialEnabled = false
        local integer specialAfterNormalShots = 3
        local string specialMissileModel = ""
        local string specialOverlayModel = ""
        local real specialDamageMult = 2.00
        local real specialAreaMult = 2.00
        local real specialSpeedMult = 1.00
        local real specialMissileScaleMult = 1.00
        local real specialDummyScaleMult = 2.00

        local string soundCastStart = ""
        local string soundWaitStart = ""
        local string soundWaitEnd = ""
        local string soundImpact = ""
        local string soundLastMissile = ""
        local string soundDummyClear = ""
        local string soundInterrupted = ""
        local string soundChannelComplete = ""

        local real manaCost = 0.
        // Overrides de hrif aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hkni takes nothing returns nothing
        local integer unitType = 'hkni'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        // Overrides de hkni aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hmtm takes nothing returns nothing
        local integer unitType = 'hmtm'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        // Overrides de hmtm aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hmpr takes nothing returns nothing
        local integer unitType = 'hmpr'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        
        // Overrides de hmpr aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hsor takes nothing returns nothing
        local integer unitType = 'hsor'
        local real speed = 750.
        local real damage = 15.
        local string missileModel = "war3mapImported\\Farm.mdx"
        local string overlayModel = "Objects\\Spawnmodels\\Human\\HCancelDeath\\HCancelDeath.mdl"

        local boolean useRapidFire = false
        local real rapidFireDuration = 0.55
        local real rapidFireInterval = 0.25

        local string castAnimation = "attack"
        local real castAnimationDelay = 0.03
        local real castAnimationTimeScale = 1.25
        local string casterWaitFx = "war3mapImported\\Bondage Blue SD.mdx"

        local string dummyModel = "war3mapImported\\Spell Marker Blue.mdx"
        local string dummyImpactFx = "Objects\\Spawnmodels\\Human\\HCancelDeath\\HCancelDeath.mdl"
        local real dummyScale = 1.0
        local real dummyArea = 150.
        local real dummyDelay = 1.00

        local real missileArc = 0.
        local real missileStartZ = 75.
        local real missileFlyHeight = 0.
        local real missileCollision = 150.
        local real missileScale = 1.0

        local boolean impactOnPath = true
        local boolean specialEnabled = false
        local integer specialAfterNormalShots = 3
        local string specialMissileModel = ""
        local string specialOverlayModel = ""
        local real specialDamageMult = 2.00
        local real specialAreaMult = 2.00
        local real specialSpeedMult = 1.00
        local real specialMissileScaleMult = 1.00
        local real specialDummyScaleMult = 2.00

        local string soundCastStart = ""
        local string soundWaitStart = ""
        local string soundWaitEnd = ""
        local string soundImpact = ""
        local string soundLastMissile = ""
        local string soundDummyClear = ""
        local string soundInterrupted = ""
        local string soundChannelComplete = ""

        local real manaCost = 0.
        // Overrides de hsor aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hmtt takes nothing returns nothing
        local integer unitType = 'hmtt'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        // Overrides de hmtt aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction
    private function Configure_hwt3 takes nothing returns nothing
        local integer unitType = 'hwt3'
        local real speed = DEFAULT_SPEED
        local real damage = DEFAULT_DAMAGE
        local string missileModel = DEFAULT_MISSILE_MODEL
        local string overlayModel = DEFAULT_OVERLAY_MODEL
        local boolean useRapidFire = DEFAULT_USE_RAPID_FIRE
        local real rapidFireDuration = DEFAULT_RAPID_FIRE_DURATION
        local real rapidFireInterval = DEFAULT_RAPID_FIRE_INTERVAL
        local string castAnimation = DEFAULT_CAST_ANIMATION
        local real castAnimationDelay = DEFAULT_CAST_ANIMATION_DELAY
        local real castAnimationTimeScale = DEFAULT_CAST_ANIMATION_TIME_SCALE
        local string casterWaitFx = DEFAULT_CASTER_WAIT_FX
        local string dummyModel = DEFAULT_DUMMY_MODEL
        local string dummyImpactFx = DEFAULT_DUMMY_IMPACT_FX
        local real dummyScale = DEFAULT_DUMMY_SCALE
        local real dummyArea = DEFAULT_DUMMY_AREA
        local real dummyDelay = DEFAULT_DUMMY_DELAY
        local real missileArc = DEFAULT_MISSILE_ARC
        local real missileStartZ = DEFAULT_MISSILE_START_Z
        local real missileFlyHeight = DEFAULT_MISSILE_FLY_HEIGHT
        local real missileCollision = DEFAULT_MISSILE_COLLISION
        local real missileScale = DEFAULT_MISSILE_SCALE
        local boolean impactOnPath = DEFAULT_IMPACT_ON_PATH
        local boolean specialEnabled = DEFAULT_SPECIAL_ENABLED
        local integer specialAfterNormalShots = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        local string specialMissileModel = DEFAULT_SPECIAL_MISSILE_MODEL
        local string specialOverlayModel = DEFAULT_SPECIAL_OVERLAY_MODEL
        local real specialDamageMult = DEFAULT_SPECIAL_DAMAGE_MULT
        local real specialAreaMult = DEFAULT_SPECIAL_AREA_MULT
        local real specialSpeedMult = DEFAULT_SPECIAL_SPEED_MULT
        local real specialMissileScaleMult = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        local real specialDummyScaleMult = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        local string soundCastStart = DEFAULT_SOUND_CAST_START
        local string soundWaitStart = DEFAULT_SOUND_WAIT_START
        local string soundWaitEnd = DEFAULT_SOUND_WAIT_END
        local string soundImpact = DEFAULT_SOUND_IMPACT
        local string soundLastMissile = DEFAULT_SOUND_LAST_MISSILE
        local string soundDummyClear = DEFAULT_SOUND_DUMMY_CLEAR
        local string soundInterrupted = DEFAULT_SOUND_INTERRUPTED
        local string soundChannelComplete = DEFAULT_SOUND_CHANNEL_COMPLETE
        local real manaCost = DEFAULT_MANA_COST
        // Overrides de hwt3 aqui.
        call SetUnitTypeMissileLoadout(unitType, speed, damage, missileModel, overlayModel)
        call SetUnitTypeUseRapidFire(unitType, useRapidFire, rapidFireDuration, rapidFireInterval)
        call SetUnitTypeCastAnimation(unitType, castAnimation, castAnimationDelay, castAnimationTimeScale)
        call SetUnitTypeCasterWaitFx(unitType, casterWaitFx)
        call SetUnitTypeDummyConfig(unitType, dummyModel, dummyScale, dummyDelay)
        call SetUnitTypeDummyImpactFx(unitType, dummyImpactFx)
        call SetUnitTypeDummyArea(unitType, dummyArea)
        call SetUnitTypeMissileConfig(unitType, missileArc, missileFlyHeight, missileCollision, missileScale)
        call SetUnitTypeImpactOnPath(unitType, impactOnPath)
        call SetUnitTypeSpecialMissile(unitType, specialEnabled, specialAfterNormalShots, specialMissileModel, specialOverlayModel)
        call SetUnitTypeSpecialMultipliers(unitType, specialDamageMult, specialAreaMult, specialSpeedMult, specialMissileScaleMult, specialDummyScaleMult)
        call SetUnitTypeMissileSounds(unitType, soundCastStart, soundWaitStart, soundWaitEnd, soundImpact, soundLastMissile, soundDummyClear, soundInterrupted, soundChannelComplete)
        call SetUnitTypeMissileStartZ(unitType, missileStartZ)
        call SetUnitTypeManaCost(unitType, manaCost)
    endfunction

    private function Init takes nothing returns nothing
        call Configure_hpea()
        call Configure_hmil()
        call Configure_hfoo()
        call Configure_hrif()
        call Configure_hkni()
        call Configure_hmtm()
        call Configure_hmpr()
        call Configure_hsor()
        call Configure_hmtt()
        call Configure_hwt3()
    endfunction
endlibrary

