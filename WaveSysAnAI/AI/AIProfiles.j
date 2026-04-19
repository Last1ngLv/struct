library AIProfiles initializer Init requires Table

    globals
        constant integer AI_TARGET_NONE = 0
        constant integer AI_TARGET_UNIT = 1
        constant integer AI_TARGET_POINT = 2

        constant integer AI_BEHAVIOR_KEEP_DISTANCE = 1
        constant integer AI_BEHAVIOR_LOW_HP_BIAS = 2

        constant integer AI_DEFAULT_PROFILE_ID = 1
        constant integer AI_PROFILE_MELEE = 2
        constant integer AI_PROFILE_RANGED = 3
        constant integer AI_PROFILE_CASTER = 4
        constant integer AI_MAX_RULES_PER_PROFILE = 24

        private constant integer AI_RULE_KEY_STRIDE = 64

        private Table AIProfThinkInterval
        private Table AIProfRetargetInterval
        private Table AIProfOrderInterval
        private Table AIProfAcquireRange
        private Table AIProfLeashRange
        private Table AIProfPreferredRange
        private Table AIProfChaseBias
        private Table AIProfDefaultFlags
        private Table AIProfRuleCount
        private Table AIProfTeleportEnabled
        private Table AIProfTeleportPrioritizeFarthest
        private Table AIProfTeleportCooldownMin
        private Table AIProfTeleportCooldownMax
        private Table AIProfTeleportEntryDelayMin
        private Table AIProfTeleportEntryDelayMax
        private Table AIProfTeleportOffsetMin
        private Table AIProfTeleportOffsetMax
        private Table AIProfTeleportPreFxPath

        private Table AIRuleAbilityId
        private Table AIRuleOrderString
        private Table AIRuleTargetType
        private Table AIRuleMinRange
        private Table AIRuleMaxRange
        private Table AIRuleSelfHpMaxPct
        private Table AIRuleEnemyHpMaxPct
        private Table AIRuleMinEnemiesInRadius
        private Table AIRuleRadius
        private Table AIRulePriority
        private Table AIRuleLocalCooldown
        private Table AIRuleIsChanneling
        private Table AIRuleChannelLock

        private Table AIDefaultProfileByUnitType
    endglobals

    private function AIRuleKey takes integer profileId, integer slot returns integer
        return profileId*AI_RULE_KEY_STRIDE + slot
    endfunction

    function AIRegisterProfile takes integer profileId, real thinkInterval, real retargetInterval, real acquireRange, real leashRange, real preferredRange returns nothing
        if profileId <= 0 then
            return
        endif

        if thinkInterval <= 0.0 then
            set thinkInterval = 0.25
        endif
        if retargetInterval <= 0.0 then
            set retargetInterval = 0.50
        endif
        if acquireRange <= 0.0 then
            set acquireRange = 900.0
        endif
        if leashRange <= 0.0 then
            set leashRange = acquireRange + 500.0
        endif
        if preferredRange <= 0.0 then
            set preferredRange = 180.0
        endif

        set AIProfThinkInterval.real[profileId] = thinkInterval
        set AIProfRetargetInterval.real[profileId] = retargetInterval
        set AIProfOrderInterval.real[profileId] = 0.35
        set AIProfAcquireRange.real[profileId] = acquireRange
        set AIProfLeashRange.real[profileId] = leashRange
        set AIProfPreferredRange.real[profileId] = preferredRange

        if not AIProfChaseBias.real.has(profileId) then
            set AIProfChaseBias.real[profileId] = 1.00
        endif
        if not AIProfDefaultFlags.has(profileId) then
            set AIProfDefaultFlags[profileId] = 0
        endif
        if not AIProfRuleCount.has(profileId) then
            set AIProfRuleCount[profileId] = 0
        endif
        if not AIProfTeleportEnabled.has(profileId) then
            set AIProfTeleportEnabled[profileId] = 0
        endif
        if not AIProfTeleportPrioritizeFarthest.has(profileId) then
            set AIProfTeleportPrioritizeFarthest[profileId] = 0
        endif
        if not AIProfTeleportCooldownMin.real.has(profileId) then
            set AIProfTeleportCooldownMin.real[profileId] = 0.0
        endif
        if not AIProfTeleportCooldownMax.real.has(profileId) then
            set AIProfTeleportCooldownMax.real[profileId] = 0.0
        endif
        if not AIProfTeleportEntryDelayMin.real.has(profileId) then
            set AIProfTeleportEntryDelayMin.real[profileId] = 0.0
        endif
        if not AIProfTeleportEntryDelayMax.real.has(profileId) then
            set AIProfTeleportEntryDelayMax.real[profileId] = 0.0
        endif
        if not AIProfTeleportOffsetMin.real.has(profileId) then
            set AIProfTeleportOffsetMin.real[profileId] = 0.0
        endif
        if not AIProfTeleportOffsetMax.real.has(profileId) then
            set AIProfTeleportOffsetMax.real[profileId] = 0.0
        endif
        if not AIProfTeleportPreFxPath.string.has(profileId) then
            set AIProfTeleportPreFxPath.string[profileId] = ""
        endif
    endfunction

    function AISetProfileBehavior takes integer profileId, real chaseBias, integer defaultFlags returns nothing
        if profileId <= 0 then
            return
        endif
        if chaseBias <= 0.0 then
            set chaseBias = 1.00
        endif
        set AIProfChaseBias.real[profileId] = chaseBias
        set AIProfDefaultFlags[profileId] = defaultFlags
    endfunction

    function AISetProfileOrderInterval takes integer profileId, real orderInterval returns nothing
        if profileId <= 0 then
            return
        endif
        if orderInterval <= 0.0 then
            set orderInterval = 0.35
        endif
        set AIProfOrderInterval.real[profileId] = orderInterval
    endfunction

    function AISetProfileTeleport takes integer profileId, boolean enabled, boolean prioritizeFarthestTrackedHero, real cooldownMinSec, real cooldownMaxSec, real entryDelayMinSec, real entryDelayMaxSec, real offsetMin, real offsetMax, string preFxPath returns nothing
        local real tmp
        if profileId <= 0 then
            return
        endif
        if not AIProfRuleCount.has(profileId) then
            call AIRegisterProfile(profileId, 0.25, 0.50, 900.0, 1400.0, 180.0)
        endif
        if cooldownMinSec < 0.0 then
            set cooldownMinSec = 0.0
        endif
        if cooldownMaxSec < 0.0 then
            set cooldownMaxSec = 0.0
        endif
        if cooldownMaxSec < cooldownMinSec then
            set tmp = cooldownMinSec
            set cooldownMinSec = cooldownMaxSec
            set cooldownMaxSec = tmp
        endif
        if entryDelayMinSec < 0.0 then
            set entryDelayMinSec = 0.0
        endif
        if entryDelayMaxSec < 0.0 then
            set entryDelayMaxSec = 0.0
        endif
        if entryDelayMaxSec < entryDelayMinSec then
            set tmp = entryDelayMinSec
            set entryDelayMinSec = entryDelayMaxSec
            set entryDelayMaxSec = tmp
        endif
        if offsetMin < 0.0 then
            set offsetMin = 0.0
        endif
        if offsetMax < 0.0 then
            set offsetMax = 0.0
        endif
        if offsetMax < offsetMin then
            set tmp = offsetMin
            set offsetMin = offsetMax
            set offsetMax = tmp
        endif
        if preFxPath == "" then
            set preFxPath = ""
        endif
        if enabled then
            set AIProfTeleportEnabled[profileId] = 1
        else
            set AIProfTeleportEnabled[profileId] = 0
        endif
        if prioritizeFarthestTrackedHero then
            set AIProfTeleportPrioritizeFarthest[profileId] = 1
        else
            set AIProfTeleportPrioritizeFarthest[profileId] = 0
        endif
        set AIProfTeleportCooldownMin.real[profileId] = cooldownMinSec
        set AIProfTeleportCooldownMax.real[profileId] = cooldownMaxSec
        set AIProfTeleportEntryDelayMin.real[profileId] = entryDelayMinSec
        set AIProfTeleportEntryDelayMax.real[profileId] = entryDelayMaxSec
        set AIProfTeleportOffsetMin.real[profileId] = offsetMin
        set AIProfTeleportOffsetMax.real[profileId] = offsetMax
        set AIProfTeleportPreFxPath.string[profileId] = preFxPath
    endfunction

    function AIAddAbilityRule takes integer profileId, integer abilityId, string orderString, integer targetType, real minRange, real maxRange, real selfHpMaxPct, real enemyHpMaxPct, integer minEnemiesInRadius, real radius, integer priority, real localCooldown returns nothing
        local integer count
        local integer key

        if profileId <= 0 or abilityId == 0 then
            return
        endif
        if orderString == "" then
            return
        endif

        if not AIProfRuleCount.has(profileId) then
            call AIRegisterProfile(profileId, 0.25, 0.50, 900.0, 1400.0, 180.0)
        endif

        set count = AIProfRuleCount[profileId]
        if count >= AI_MAX_RULES_PER_PROFILE then
            return
        endif
        set count = count + 1
        set AIProfRuleCount[profileId] = count

        if targetType < AI_TARGET_NONE or targetType > AI_TARGET_POINT then
            set targetType = AI_TARGET_UNIT
        endif
        if minRange < 0.0 then
            set minRange = 0.0
        endif
        if maxRange < 0.0 then
            set maxRange = 0.0
        endif
        if selfHpMaxPct < 0.0 then
            set selfHpMaxPct = 0.0
        elseif selfHpMaxPct > 100.0 then
            set selfHpMaxPct = 100.0
        endif
        if enemyHpMaxPct < 0.0 then
            set enemyHpMaxPct = 0.0
        elseif enemyHpMaxPct > 100.0 then
            set enemyHpMaxPct = 100.0
        endif
        if minEnemiesInRadius < 0 then
            set minEnemiesInRadius = 0
        endif
        if radius < 0.0 then
            set radius = 0.0
        endif
        if localCooldown < 0.0 then
            set localCooldown = 0.0
        endif

        set key = AIRuleKey(profileId, count)

        set AIRuleAbilityId[key] = abilityId
        set AIRuleOrderString.string[key] = orderString
        set AIRuleTargetType[key] = targetType
        set AIRuleMinRange.real[key] = minRange
        set AIRuleMaxRange.real[key] = maxRange
        set AIRuleSelfHpMaxPct.real[key] = selfHpMaxPct
        set AIRuleEnemyHpMaxPct.real[key] = enemyHpMaxPct
        set AIRuleMinEnemiesInRadius[key] = minEnemiesInRadius
        set AIRuleRadius.real[key] = radius
        set AIRulePriority[key] = priority
        set AIRuleLocalCooldown.real[key] = localCooldown
        set AIRuleIsChanneling[key] = 0
        set AIRuleChannelLock.real[key] = 0.0
    endfunction

    // Marca una regla como channeling y define cuánto tiempo bloquear órdenes de movimiento/ataque.
    // channelLockSeconds recomendado: duración del canal + pequeño margen (ej. 2.20).
    function AISetAbilityRuleChanneling takes integer profileId, integer slot, boolean isChanneling, real channelLockSeconds returns nothing
        local integer key
        if profileId <= 0 or slot <= 0 then
            return
        endif
        set key = AIRuleKey(profileId, slot)
        if isChanneling then
            set AIRuleIsChanneling[key] = 1
            if channelLockSeconds < 0.0 then
                set channelLockSeconds = 0.0
            endif
            set AIRuleChannelLock.real[key] = channelLockSeconds
        else
            set AIRuleIsChanneling[key] = 0
            set AIRuleChannelLock.real[key] = 0.0
        endif
    endfunction
    
    function AIGetProfileRuleCount takes integer profileId returns integer
        if AIProfRuleCount.has(profileId) then
            return AIProfRuleCount[profileId]
        endif
        return 0
    endfunction

    // Variante extendida: permite definir channeling al crear la regla.
    function AIAddAbilityRuleEx takes integer profileId, integer abilityId, string orderString, integer targetType, real minRange, real maxRange, real selfHpMaxPct, real enemyHpMaxPct, integer minEnemiesInRadius, real radius, integer priority, real localCooldown, boolean isChanneling, real channelLockSeconds returns nothing
        local integer slot
        call AIAddAbilityRule(profileId, abilityId, orderString, targetType, minRange, maxRange, selfHpMaxPct, enemyHpMaxPct, minEnemiesInRadius, radius, priority, localCooldown)
        set slot = AIGetProfileRuleCount(profileId)
        if slot > 0 then
            call AISetAbilityRuleChanneling(profileId, slot, isChanneling, channelLockSeconds)
        endif
    endfunction

    function AISetDefaultProfileForUnitType takes integer unitTypeId, integer profileId returns nothing
        if unitTypeId == 0 then
            return
        endif
        if profileId <= 0 then
            call AIDefaultProfileByUnitType.remove(unitTypeId)
            return
        endif
        set AIDefaultProfileByUnitType[unitTypeId] = profileId
    endfunction

    function AIGetDefaultProfileForUnitType takes integer unitTypeId returns integer
        if AIDefaultProfileByUnitType.has(unitTypeId) then
            return AIDefaultProfileByUnitType[unitTypeId]
        endif
        return AI_DEFAULT_PROFILE_ID
    endfunction

    function AIGetProfileThinkInterval takes integer profileId returns real
        if AIProfThinkInterval.real.has(profileId) then
            return AIProfThinkInterval.real[profileId]
        endif
        return 0.25
    endfunction

    function AIGetProfileRetargetInterval takes integer profileId returns real
        if AIProfRetargetInterval.real.has(profileId) then
            return AIProfRetargetInterval.real[profileId]
        endif
        return 0.50
    endfunction

    function AIGetProfileOrderInterval takes integer profileId returns real
        if AIProfOrderInterval.real.has(profileId) then
            return AIProfOrderInterval.real[profileId]
        endif
        return 0.35
    endfunction

    function AIGetProfileAcquireRange takes integer profileId returns real
        if AIProfAcquireRange.real.has(profileId) then
            return AIProfAcquireRange.real[profileId]
        endif
        return 900.0
    endfunction

    function AIGetProfileLeashRange takes integer profileId returns real
        if AIProfLeashRange.real.has(profileId) then
            return AIProfLeashRange.real[profileId]
        endif
        return 1400.0
    endfunction

    function AIGetProfilePreferredRange takes integer profileId returns real
        if AIProfPreferredRange.real.has(profileId) then
            return AIProfPreferredRange.real[profileId]
        endif
        return 180.0
    endfunction

    function AIGetProfileChaseBias takes integer profileId returns real
        if AIProfChaseBias.real.has(profileId) then
            return AIProfChaseBias.real[profileId]
        endif
        return 1.00
    endfunction

    function AIGetProfileDefaultFlags takes integer profileId returns integer
        if AIProfDefaultFlags.has(profileId) then
            return AIProfDefaultFlags[profileId]
        endif
        return 0
    endfunction

    function AIGetProfileTeleportEnabled takes integer profileId returns boolean
        return AIProfTeleportEnabled.has(profileId) and AIProfTeleportEnabled[profileId] == 1
    endfunction

    function AIGetProfileTeleportPrioritizeFarthestTrackedHero takes integer profileId returns boolean
        return AIProfTeleportPrioritizeFarthest.has(profileId) and AIProfTeleportPrioritizeFarthest[profileId] == 1
    endfunction

    function AIGetProfileTeleportCooldownMin takes integer profileId returns real
        if AIProfTeleportCooldownMin.real.has(profileId) then
            return AIProfTeleportCooldownMin.real[profileId]
        endif
        return 0.0
    endfunction

    function AIGetProfileTeleportCooldownMax takes integer profileId returns real
        if AIProfTeleportCooldownMax.real.has(profileId) then
            return AIProfTeleportCooldownMax.real[profileId]
        endif
        return 0.0
    endfunction

    function AIGetProfileTeleportEntryDelayMin takes integer profileId returns real
        if AIProfTeleportEntryDelayMin.real.has(profileId) then
            return AIProfTeleportEntryDelayMin.real[profileId]
        endif
        return 0.0
    endfunction

    function AIGetProfileTeleportEntryDelayMax takes integer profileId returns real
        if AIProfTeleportEntryDelayMax.real.has(profileId) then
            return AIProfTeleportEntryDelayMax.real[profileId]
        endif
        return 0.0
    endfunction

    function AIGetProfileTeleportOffsetMin takes integer profileId returns real
        if AIProfTeleportOffsetMin.real.has(profileId) then
            return AIProfTeleportOffsetMin.real[profileId]
        endif
        return 0.0
    endfunction

    function AIGetProfileTeleportOffsetMax takes integer profileId returns real
        if AIProfTeleportOffsetMax.real.has(profileId) then
            return AIProfTeleportOffsetMax.real[profileId]
        endif
        return 0.0
    endfunction

    function AIGetProfileTeleportPreFxPath takes integer profileId returns string
        if AIProfTeleportPreFxPath.string.has(profileId) then
            return AIProfTeleportPreFxPath.string[profileId]
        endif
        return ""
    endfunction

    function AIGetProfileRuleAbilityId takes integer profileId, integer slot returns integer
        return AIRuleAbilityId[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleOrderString takes integer profileId, integer slot returns string
        return AIRuleOrderString.string[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleTargetType takes integer profileId, integer slot returns integer
        return AIRuleTargetType[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleMinRange takes integer profileId, integer slot returns real
        return AIRuleMinRange.real[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleMaxRange takes integer profileId, integer slot returns real
        return AIRuleMaxRange.real[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleSelfHpMaxPct takes integer profileId, integer slot returns real
        return AIRuleSelfHpMaxPct.real[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleEnemyHpMaxPct takes integer profileId, integer slot returns real
        return AIRuleEnemyHpMaxPct.real[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleMinEnemiesInRadius takes integer profileId, integer slot returns integer
        return AIRuleMinEnemiesInRadius[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleRadius takes integer profileId, integer slot returns real
        return AIRuleRadius.real[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRulePriority takes integer profileId, integer slot returns integer
        return AIRulePriority[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleLocalCooldown takes integer profileId, integer slot returns real
        return AIRuleLocalCooldown.real[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleIsChanneling takes integer profileId, integer slot returns integer
        return AIRuleIsChanneling[AIRuleKey(profileId, slot)]
    endfunction

    function AIGetProfileRuleChannelLock takes integer profileId, integer slot returns real
        return AIRuleChannelLock.real[AIRuleKey(profileId, slot)]
    endfunction

    private function Init takes nothing returns nothing
        set AIProfThinkInterval = Table.create()
        set AIProfRetargetInterval = Table.create()
        set AIProfOrderInterval = Table.create()
        set AIProfAcquireRange = Table.create()
        set AIProfLeashRange = Table.create()
        set AIProfPreferredRange = Table.create()
        set AIProfChaseBias = Table.create()
        set AIProfDefaultFlags = Table.create()
        set AIProfRuleCount = Table.create()
        set AIProfTeleportEnabled = Table.create()
        set AIProfTeleportPrioritizeFarthest = Table.create()
        set AIProfTeleportCooldownMin = Table.create()
        set AIProfTeleportCooldownMax = Table.create()
        set AIProfTeleportEntryDelayMin = Table.create()
        set AIProfTeleportEntryDelayMax = Table.create()
        set AIProfTeleportOffsetMin = Table.create()
        set AIProfTeleportOffsetMax = Table.create()
        set AIProfTeleportPreFxPath = Table.create()

        set AIRuleAbilityId = Table.create()
        set AIRuleOrderString = Table.create()
        set AIRuleTargetType = Table.create()
        set AIRuleMinRange = Table.create()
        set AIRuleMaxRange = Table.create()
        set AIRuleSelfHpMaxPct = Table.create()
        set AIRuleEnemyHpMaxPct = Table.create()
        set AIRuleMinEnemiesInRadius = Table.create()
        set AIRuleRadius = Table.create()
        set AIRulePriority = Table.create()
        set AIRuleLocalCooldown = Table.create()
        set AIRuleIsChanneling = Table.create()
        set AIRuleChannelLock = Table.create()

        set AIDefaultProfileByUnitType = Table.create()
    endfunction
endlibrary
