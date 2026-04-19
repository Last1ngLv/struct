//TESH.scrollpos=0
//TESH.alwaysfold=0
library UnitTypeMissileLoadout initializer Init uses Table /* v1.0
*************************************************************************************
*
*   Almacena configuraciÃ³n de missile por tipo de unidad.
*   Valores almacenados:
*       - real missile speed
*       - real damage value
*       - string missile model path
*       - string missile overlay model path
*       - boolean useRapidFire
*       - real rapidFireDuration
*       - real rapidFireInterval
*       - string castAnimation
*       - real castAnimationDelay
*       - real castAnimationTimeScale
*       - string casterWaitFx (efecto en caster durante espera)
*       - real dummyModel (efecto especial en punto de caste)
*       - string dummyImpactFx (efecto en punto cuando el missile impacta)
*       - real dummyScale
*       - real dummyArea (area usada para escalar el dummy)
*       - real dummyDelay (tiempo antes de lanzar missile)
*       - real missileArc
*       - real missileFlyHeight
*       - real missileCollision
*       - boolean impactOnPath (si puede explotar al tocar enemigo durante el trayecto)
*       - boolean specialEnabled (habilita proyectil especial)
*       - integer specialAfterNormalShots (sale especial tras N normales)
*       - string specialMissileModel
*       - string specialOverlayModel
*       - real specialDamageMult
*       - real specialAreaMult
*       - real specialSpeedMult
*       - real specialMissileScaleMult
*       - real specialDummyScaleMult
*       - string sndCastStart
*       - string sndWaitStart
*       - string sndWaitEnd
*       - string sndImpact
*       - string sndLastMissile
*       - string sndDummyClear
*       - string sndInterrupted
*       - string sndChannelComplete
*       - real missileScale
*       - real manaCost
*
*   API:
*       call SetUnitTypeMissileLoadout(integer unitType, real speed, real damage, string missileModel, string overlayModel)
*       call SetUnitTypeUseRapidFire(integer unitType, boolean use, real duration, real interval)
*       call SetUnitTypeCastAnimation(integer unitType, string animation, real delay, real timeScale)
*       call SetUnitTypeCasterWaitFx(integer unitType, string fx)
*       call SetUnitTypeDummyConfig(integer unitType, string model, real scale, real delay)
*       call SetUnitTypeDummyImpactFx(integer unitType, string fx)
*       call SetUnitTypeDummyArea(integer unitType, real area)
*       call SetUnitTypeMissileConfig(integer unitType, real arc, real flyHeight, real collision, real scale)
*       call SetUnitTypeImpactOnPath(integer unitType, boolean enabled)
*       call SetUnitTypeSpecialMissile(integer unitType, boolean enabled, integer afterNormalShots, string specialModel, string specialOverlay)
*       call SetUnitTypeSpecialMultipliers(integer unitType, real damageMult, real areaMult, real speedMult, real missileScaleMult, real dummyScaleMult)
*       call SetUnitTypeMissileSounds(integer unitType, string castStart, string waitStart, string waitEnd, string impact, string lastMissile, string dummyClear, string interrupted, string channelComplete)
*       call SetUnitTypeMissileStartZ(integer unitType, real startZ)
*       call SetUnitTypeManaCost(integer unitType, real cost)
*
*       real    s = GetUnitTypeMissileSpeed(integer unitType)
*       real    d = GetUnitTypeMissileDamage(integer unitType)
*       string  m = GetUnitTypeMissileModel(integer unitType)
*       string  o = GetUnitTypeMissileOverlayModel(integer unitType)
*       boolean u = GetUnitTypeUseRapidFire(integer unitType)
*       real    rfd = GetUnitTypeRapidFireDuration(integer unitType)
*       real    rfi = GetUnitTypeRapidFireInterval(integer unitType)
*       string  ca = GetUnitTypeCastAnimation(integer unitType)
*       real    cad = GetUnitTypeCastAnimationDelay(integer unitType)
*       real    cats = GetUnitTypeCastAnimationTimeScale(integer unitType)
*       string  cwf = GetUnitTypeCasterWaitFx(integer unitType)
*       string  dm = GetUnitTypeDummyModel(integer unitType)
*       string  dif = GetUnitTypeDummyImpactFx(integer unitType)
*       real    ds = GetUnitTypeDummyScale(integer unitType)
*       real    da = GetUnitTypeDummyArea(integer unitType)
*       real    dd = GetUnitTypeDummyDelay(integer unitType)
*       real    ma = GetUnitTypeMissileArc(integer unitType)
*       real    msz = GetUnitTypeMissileStartZ(integer unitType)
*       real    mfh = GetUnitTypeMissileFlyHeight(integer unitType)
*       real    mc = GetUnitTypeMissileCollision(integer unitType)
*       boolean iop = GetUnitTypeImpactOnPath(integer unitType)
*       boolean se = GetUnitTypeSpecialEnabled(integer unitType)
*       integer sns = GetUnitTypeSpecialAfterNormalShots(integer unitType)
*       string  sm = GetUnitTypeSpecialMissileModel(integer unitType)
*       string  so = GetUnitTypeSpecialOverlayModel(integer unitType)
*       real    sdm = GetUnitTypeSpecialDamageMult(integer unitType)
*       real    sam = GetUnitTypeSpecialAreaMult(integer unitType)
*       real    ssm = GetUnitTypeSpecialSpeedMult(integer unitType)
*       real    ssm2 = GetUnitTypeSpecialMissileScaleMult(integer unitType)
*       real    sdum = GetUnitTypeSpecialDummyScaleMult(integer unitType)
*       string  scs = GetUnitTypeSoundCastStart(integer unitType)
*       string  sws = GetUnitTypeSoundWaitStart(integer unitType)
*       string  swe = GetUnitTypeSoundWaitEnd(integer unitType)
*       string  sim = GetUnitTypeSoundImpact(integer unitType)
*       string  slm = GetUnitTypeSoundLastMissile(integer unitType)
*       string  sdc = GetUnitTypeSoundDummyClear(integer unitType)
*       string  sint = GetUnitTypeSoundInterrupted(integer unitType)
*       string  scc = GetUnitTypeSoundChannelComplete(integer unitType)
*       real    ms = GetUnitTypeMissileScale(integer unitType)
*       real    mnc = GetUnitTypeManaCost(integer unitType)
*
************************************************************************************/
    globals
        private constant real    DEFAULT_SPEED = 1000.
        private constant real    DEFAULT_DAMAGE = 1.
        private constant string  DEFAULT_MISSILE_MODEL = "Miss\\Shot Blue.mdx"
        private constant string  DEFAULT_OVERLAY_MODEL = "Miss\\Shot II Blue.mdx"

        private constant boolean DEFAULT_USE_RAPID_FIRE = true
        private constant real    DEFAULT_RAPID_FIRE_DURATION = 1.20
        private constant real    DEFAULT_RAPID_FIRE_INTERVAL = 0.40

        private constant string  DEFAULT_CAST_ANIMATION = "attack"
        private constant real    DEFAULT_CAST_ANIMATION_DELAY = 0.03
        private constant real    DEFAULT_CAST_ANIMATION_TIME_SCALE = 3.25
        private constant string  DEFAULT_CASTER_WAIT_FX = "war3mapImported\\Bondage Blue SD.mdx"

        private constant string  DEFAULT_DUMMY_MODEL = "war3mapImported\\OrbFireX.mdx"
        private constant string  DEFAULT_DUMMY_IMPACT_FX = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        private constant real    DEFAULT_DUMMY_SCALE = 1.0
        private constant real    DEFAULT_DUMMY_AREA = 200.
        private constant real    DEFAULT_DUMMY_DELAY = 1.00

        private constant real    DEFAULT_MISSILE_ARC = 500.
        private constant real    DEFAULT_MISSILE_START_Z = 75.
        private constant real    DEFAULT_MISSILE_FLY_HEIGHT = 0.
        private constant real    DEFAULT_MISSILE_COLLISION = 200.
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

        private Table byType
        private integer nextSlot = 0

        private real array typeSpeed
        private real array typeDamage
        private string array typeModel
        private string array typeOverlay

        private boolean array typeUseRapidFire
        private real array typeRapidFireDuration
        private real array typeRapidFireInterval

        private string array typeCastAnimation
        private real array typeCastAnimDelay
        private real array typeCastAnimTimeScale
        private string array typeCasterWaitFx

        private string array typeDummyModel
        private string array typeDummyImpactFx
        private real array typeDummyScale
        private real array typeDummyArea
        private real array typeDummyDelay

        private real array typeMissileArc
        private real array typeMissileStartZ
        private real array typeMissileFlyHeight
        private real array typeMissileCollision
        private boolean array typeImpactOnPath
        private boolean array typeSpecialEnabled
        private integer array typeSpecialAfterNormalShots
        private string array typeSpecialMissileModel
        private string array typeSpecialOverlayModel
        private real array typeSpecialDamageMult
        private real array typeSpecialAreaMult
        private real array typeSpecialSpeedMult
        private real array typeSpecialMissileScaleMult
        private real array typeSpecialDummyScaleMult
        private string array typeSoundCastStart
        private string array typeSoundWaitStart
        private string array typeSoundWaitEnd
        private string array typeSoundImpact
        private string array typeSoundLastMissile
        private string array typeSoundDummyClear
        private string array typeSoundInterrupted
        private string array typeSoundChannelComplete
        private real array typeMissileScale

        private real array typeManaCost
    endglobals

    private function SlotOfType takes integer unitType returns integer
        local integer slot
        if unitType == 0 then
            return 0
        endif
        if byType.has(unitType) then
            return byType[unitType]
        endif

        set nextSlot = nextSlot + 1
        set slot = nextSlot
        set byType[unitType] = slot

        // Defaults so partial setters don't leave fields undefined.
        set typeSpeed[slot] = DEFAULT_SPEED
        set typeDamage[slot] = DEFAULT_DAMAGE
        set typeModel[slot] = DEFAULT_MISSILE_MODEL
        set typeOverlay[slot] = DEFAULT_OVERLAY_MODEL

        set typeUseRapidFire[slot] = DEFAULT_USE_RAPID_FIRE
        set typeRapidFireDuration[slot] = DEFAULT_RAPID_FIRE_DURATION
        set typeRapidFireInterval[slot] = DEFAULT_RAPID_FIRE_INTERVAL

        set typeCastAnimation[slot] = DEFAULT_CAST_ANIMATION
        set typeCastAnimDelay[slot] = DEFAULT_CAST_ANIMATION_DELAY
        set typeCastAnimTimeScale[slot] = DEFAULT_CAST_ANIMATION_TIME_SCALE
        set typeCasterWaitFx[slot] = DEFAULT_CASTER_WAIT_FX

        set typeDummyModel[slot] = DEFAULT_DUMMY_MODEL
        set typeDummyImpactFx[slot] = DEFAULT_DUMMY_IMPACT_FX
        set typeDummyScale[slot] = DEFAULT_DUMMY_SCALE
        set typeDummyArea[slot] = DEFAULT_DUMMY_AREA
        set typeDummyDelay[slot] = DEFAULT_DUMMY_DELAY

        set typeMissileArc[slot] = DEFAULT_MISSILE_ARC
        set typeMissileStartZ[slot] = DEFAULT_MISSILE_START_Z
        set typeMissileFlyHeight[slot] = DEFAULT_MISSILE_FLY_HEIGHT
        set typeMissileCollision[slot] = DEFAULT_MISSILE_COLLISION
        set typeImpactOnPath[slot] = DEFAULT_IMPACT_ON_PATH
        set typeSpecialEnabled[slot] = DEFAULT_SPECIAL_ENABLED
        set typeSpecialAfterNormalShots[slot] = DEFAULT_SPECIAL_AFTER_NORMAL_SHOTS
        set typeSpecialMissileModel[slot] = DEFAULT_SPECIAL_MISSILE_MODEL
        set typeSpecialOverlayModel[slot] = DEFAULT_SPECIAL_OVERLAY_MODEL
        set typeSpecialDamageMult[slot] = DEFAULT_SPECIAL_DAMAGE_MULT
        set typeSpecialAreaMult[slot] = DEFAULT_SPECIAL_AREA_MULT
        set typeSpecialSpeedMult[slot] = DEFAULT_SPECIAL_SPEED_MULT
        set typeSpecialMissileScaleMult[slot] = DEFAULT_SPECIAL_MISSILE_SCALE_MULT
        set typeSpecialDummyScaleMult[slot] = DEFAULT_SPECIAL_DUMMY_SCALE_MULT
        set typeSoundCastStart[slot] = DEFAULT_SOUND_CAST_START
        set typeSoundWaitStart[slot] = DEFAULT_SOUND_WAIT_START
        set typeSoundWaitEnd[slot] = DEFAULT_SOUND_WAIT_END
        set typeSoundImpact[slot] = DEFAULT_SOUND_IMPACT
        set typeSoundLastMissile[slot] = DEFAULT_SOUND_LAST_MISSILE
        set typeSoundDummyClear[slot] = DEFAULT_SOUND_DUMMY_CLEAR
        set typeSoundInterrupted[slot] = DEFAULT_SOUND_INTERRUPTED
        set typeSoundChannelComplete[slot] = DEFAULT_SOUND_CHANNEL_COMPLETE
        set typeMissileScale[slot] = DEFAULT_MISSILE_SCALE

        set typeManaCost[slot] = DEFAULT_MANA_COST

        return slot
    endfunction

    function SetUnitTypeMissileLoadout takes integer unitType, real speed, real damage, string missileModel, string overlayModel returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        set typeSpeed[slot] = speed
        set typeDamage[slot] = damage
        set typeModel[slot] = missileModel
        set typeOverlay[slot] = overlayModel
    endfunction

    function SetUnitTypeUseRapidFire takes integer unitType, boolean use, real duration, real interval returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if duration < 0. then
            set duration = 0.
        endif
        if interval <= 0. then
            set interval = DEFAULT_RAPID_FIRE_INTERVAL
        endif
        set typeUseRapidFire[slot] = use
        set typeRapidFireDuration[slot] = duration
        set typeRapidFireInterval[slot] = interval
    endfunction

    function SetUnitTypeCastAnimation takes integer unitType, string animation, real delay, real timeScale returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if delay < 0. then
            set delay = 0.
        endif
        if timeScale <= 0. then
            set timeScale = 0.01
        endif
        set typeCastAnimation[slot] = animation
        set typeCastAnimDelay[slot] = delay
        set typeCastAnimTimeScale[slot] = timeScale
    endfunction

    function SetUnitTypeCasterWaitFx takes integer unitType, string fx returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        set typeCasterWaitFx[slot] = fx
    endfunction

    function SetUnitTypeDummyConfig takes integer unitType, string model, real scale, real delay returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if scale <= 0. then
            set scale = 0.01
        endif
        if delay < 0. then
            set delay = 0.
        endif
        set typeDummyModel[slot] = model
        set typeDummyScale[slot] = scale
        set typeDummyDelay[slot] = delay
    endfunction

    function SetUnitTypeDummyImpactFx takes integer unitType, string fx returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        set typeDummyImpactFx[slot] = fx
    endfunction

    function SetUnitTypeDummyArea takes integer unitType, real area returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if area <= 0. then
            set area = DEFAULT_DUMMY_AREA
        endif
        set typeDummyArea[slot] = area
        set typeMissileCollision[slot] = area
    endfunction

    function SetUnitTypeMissileConfig takes integer unitType, real arc, real flyHeight, real collision, real scale returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if collision < 0. then
            set collision = 0.
        endif
        if scale <= 0. then
            set scale = 0.01
        endif
        set typeMissileArc[slot] = arc
        set typeMissileFlyHeight[slot] = flyHeight
        set typeMissileCollision[slot] = collision
        set typeMissileScale[slot] = scale
        set typeDummyArea[slot] = collision
    endfunction

    function SetUnitTypeImpactOnPath takes integer unitType, boolean enabled returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        set typeImpactOnPath[slot] = enabled
    endfunction

    function SetUnitTypeSpecialMissile takes integer unitType, boolean enabled, integer afterNormalShots, string specialModel, string specialOverlay returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if afterNormalShots < 1 then
            set afterNormalShots = 1
        endif
        set typeSpecialEnabled[slot] = enabled
        set typeSpecialAfterNormalShots[slot] = afterNormalShots
        set typeSpecialMissileModel[slot] = specialModel
        set typeSpecialOverlayModel[slot] = specialOverlay
    endfunction

    function SetUnitTypeSpecialMultipliers takes integer unitType, real damageMult, real areaMult, real speedMult, real missileScaleMult, real dummyScaleMult returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if damageMult < 0. then
            set damageMult = 0.
        endif
        if areaMult < 0. then
            set areaMult = 0.
        endif
        if speedMult <= 0. then
            set speedMult = 0.01
        endif
        if missileScaleMult <= 0. then
            set missileScaleMult = 0.01
        endif
        if dummyScaleMult <= 0. then
            set dummyScaleMult = 0.01
        endif
        set typeSpecialDamageMult[slot] = damageMult
        set typeSpecialAreaMult[slot] = areaMult
        set typeSpecialSpeedMult[slot] = speedMult
        set typeSpecialMissileScaleMult[slot] = missileScaleMult
        set typeSpecialDummyScaleMult[slot] = dummyScaleMult
    endfunction

    function SetUnitTypeMissileSounds takes integer unitType, string castStart, string waitStart, string waitEnd, string impact, string lastMissile, string dummyClear, string interrupted, string channelComplete returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        set typeSoundCastStart[slot] = castStart
        set typeSoundWaitStart[slot] = waitStart
        set typeSoundWaitEnd[slot] = waitEnd
        set typeSoundImpact[slot] = impact
        set typeSoundLastMissile[slot] = lastMissile
        set typeSoundDummyClear[slot] = dummyClear
        set typeSoundInterrupted[slot] = interrupted
        set typeSoundChannelComplete[slot] = channelComplete
    endfunction

    function SetUnitTypeMissileStartZ takes integer unitType, real startZ returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        set typeMissileStartZ[slot] = startZ
    endfunction

    function SetUnitTypeManaCost takes integer unitType, real cost returns nothing
        local integer slot = SlotOfType(unitType)
        if slot == 0 then
            return
        endif
        if cost < 0. then
            set cost = 0.
        endif
        set typeManaCost[slot] = cost
    endfunction

    function GetUnitTypeMissileSpeed takes integer unitType returns real
        return typeSpeed[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileDamage takes integer unitType returns real
        return typeDamage[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileModel takes integer unitType returns string
        return typeModel[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileOverlayModel takes integer unitType returns string
        return typeOverlay[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeUseRapidFire takes integer unitType returns boolean
        return typeUseRapidFire[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeRapidFireDuration takes integer unitType returns real
        return typeRapidFireDuration[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeRapidFireInterval takes integer unitType returns real
        return typeRapidFireInterval[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeCastAnimation takes integer unitType returns string
        return typeCastAnimation[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeCastAnimationDelay takes integer unitType returns real
        return typeCastAnimDelay[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeCastAnimationTimeScale takes integer unitType returns real
        return typeCastAnimTimeScale[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeCasterWaitFx takes integer unitType returns string
        return typeCasterWaitFx[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeDummyModel takes integer unitType returns string
        return typeDummyModel[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeDummyImpactFx takes integer unitType returns string
        return typeDummyImpactFx[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeDummyScale takes integer unitType returns real
        return typeDummyScale[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeDummyArea takes integer unitType returns real
        return typeDummyArea[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeDummyDelay takes integer unitType returns real
        return typeDummyDelay[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileArc takes integer unitType returns real
        return typeMissileArc[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileStartZ takes integer unitType returns real
        return typeMissileStartZ[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileFlyHeight takes integer unitType returns real
        return typeMissileFlyHeight[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileCollision takes integer unitType returns real
        return typeMissileCollision[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeImpactOnPath takes integer unitType returns boolean
        return typeImpactOnPath[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialEnabled takes integer unitType returns boolean
        return typeSpecialEnabled[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialAfterNormalShots takes integer unitType returns integer
        return typeSpecialAfterNormalShots[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialMissileModel takes integer unitType returns string
        return typeSpecialMissileModel[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialOverlayModel takes integer unitType returns string
        return typeSpecialOverlayModel[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialDamageMult takes integer unitType returns real
        return typeSpecialDamageMult[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialAreaMult takes integer unitType returns real
        return typeSpecialAreaMult[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialSpeedMult takes integer unitType returns real
        return typeSpecialSpeedMult[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialMissileScaleMult takes integer unitType returns real
        return typeSpecialMissileScaleMult[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSpecialDummyScaleMult takes integer unitType returns real
        return typeSpecialDummyScaleMult[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundCastStart takes integer unitType returns string
        return typeSoundCastStart[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundWaitStart takes integer unitType returns string
        return typeSoundWaitStart[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundWaitEnd takes integer unitType returns string
        return typeSoundWaitEnd[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundImpact takes integer unitType returns string
        return typeSoundImpact[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundLastMissile takes integer unitType returns string
        return typeSoundLastMissile[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundDummyClear takes integer unitType returns string
        return typeSoundDummyClear[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundInterrupted takes integer unitType returns string
        return typeSoundInterrupted[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeSoundChannelComplete takes integer unitType returns string
        return typeSoundChannelComplete[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeMissileScale takes integer unitType returns real
        return typeMissileScale[SlotOfType(unitType)]
    endfunction

    function GetUnitTypeManaCost takes integer unitType returns real
        return typeManaCost[SlotOfType(unitType)]
    endfunction

    function HasUnitTypeMissileConfig takes integer unitType returns boolean
        return byType.has(unitType)
    endfunction

    private function Init takes nothing returns nothing
        set byType = Table.create()
    endfunction
endlibrary
