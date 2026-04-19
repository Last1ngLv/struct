//TESH.scrollpos=0
//TESH.alwaysfold=0
library TinyBuildingToss initializer Init uses SpellIndex, Missile, Table, TimerUtils, RegisterPlayerUnitEvent, SimError, DummyCaster
/*
*************************************************************************************
*
*   Tiny-like point spell:
*   - Picks the nearest OWNED structure around the caster.
*   - Launches that structure to the target point as a missile.
*   - If no structure is found: shows SimError + refunds configurable mana.
*   - On impact: repositions structure + AoE damage + configurable stun.
*
*   NOTE:
*   - Rawcodes / values below are placeholders for project-level tuning.
*   - This file lives under Pruebas for isolated testing.
*
*************************************************************************************/

    globals
        //==========================================================================
        // Core ability config (PLACEHOLDERS)
        //==========================================================================
        private constant integer TINY_TOSS_ABILITY = 'A002'

        // If true, only these unit types can be picked.
        private constant boolean USE_STRUCTURE_WHITELIST = false
        private constant integer WHITELIST_TYPE_1 = 0 
        private constant integer WHITELIST_TYPE_2 = 0
        private constant integer WHITELIST_TYPE_3 = 0
        private constant integer WHITELIST_TYPE_4 = 0

        private constant string NO_BUILDING_MESSAGE = "No hay edificio propio para lanzar."

        // Damage / payload options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        private constant boolean IMPACT_CAN_HIT_STRUCTURES = false

        // Script stun options.
        private constant boolean USE_SCRIPT_STUN = true
        private constant boolean USE_DUMMY_STUN = true // Para Buff
        private constant integer STUN_DUMMY_ABILITY = 'A001'
        private constant integer STUN_ORDER_ID = 852095 // thunderbolt

        // Facing al aterrizar:
        // true  -> fuerza facing fijo (por defecto edificios = 270)
        // false -> mantiene el facing de lanzamiento
        private constant boolean USE_DEFAULT_BUILDING_FACING_ON_LAND = true
        private constant real DEFAULT_BUILDING_FACING_ON_LAND = 270.

        // Optional FX / SFX.
        private constant string IMPACT_FX = "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl"
        private constant string IMPACT_SOUND = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode1.wav"

        //==========================================================================
        // Balance por nivel (configurable desde constantes)
        //==========================================================================
        private constant real PICKUP_RADIUS_L1 = 350.
        private constant real PICKUP_RADIUS_L2 = 425.
        private constant real PICKUP_RADIUS_L3 = 500.
        private constant real PICKUP_RADIUS_L4 = 575.

        private constant real PROJECTILE_SPEED_L1 = 900.
        private constant real PROJECTILE_SPEED_L2 = 1050.
        private constant real PROJECTILE_SPEED_L3 = 1200.
        private constant real PROJECTILE_SPEED_L4 = 1350.

        private constant real PROJECTILE_ARC_DEG_L1 = 220.
        private constant real PROJECTILE_ARC_DEG_L2 = 28.
        private constant real PROJECTILE_ARC_DEG_L3 = 34.
        private constant real PROJECTILE_ARC_DEG_L4 = 40.

        private constant real PROJECTILE_START_Z_OFFSET_L1 = 0.
        private constant real PROJECTILE_START_Z_OFFSET_L2 = 20.
        private constant real PROJECTILE_START_Z_OFFSET_L3 = 40.
        private constant real PROJECTILE_START_Z_OFFSET_L4 = 60.

        private constant real PROJECTILE_IMPACT_Z_OFFSET_L1 = 0.
        private constant real PROJECTILE_IMPACT_Z_OFFSET_L2 = 0.
        private constant real PROJECTILE_IMPACT_Z_OFFSET_L3 = 0.
        private constant real PROJECTILE_IMPACT_Z_OFFSET_L4 = 0.

        private constant real PROJECTILE_COLLISION_L1 = 0.
        private constant real PROJECTILE_COLLISION_L2 = 0.
        private constant real PROJECTILE_COLLISION_L3 = 0.
        private constant real PROJECTILE_COLLISION_L4 = 0.

        private constant real PROJECTILE_ACCELERATION_L1 = 0.
        private constant real PROJECTILE_ACCELERATION_L2 = 0.
        private constant real PROJECTILE_ACCELERATION_L3 = 0.
        private constant real PROJECTILE_ACCELERATION_L4 = 0.

        private constant real MANA_REFUND_L1 = 40.
        private constant real MANA_REFUND_L2 = 60.
        private constant real MANA_REFUND_L3 = 80.
        private constant real MANA_REFUND_L4 = 100.

        private constant real IMPACT_AOE_L1 = 200.
        private constant real IMPACT_AOE_L2 = 225.
        private constant real IMPACT_AOE_L3 = 250.
        private constant real IMPACT_AOE_L4 = 275.

        private constant real IMPACT_DAMAGE_L1 = 80.
        private constant real IMPACT_DAMAGE_L2 = 130.
        private constant real IMPACT_DAMAGE_L3 = 180.
        private constant real IMPACT_DAMAGE_L4 = 230.

        private constant real STUN_DURATION_L1 = 1.00
        private constant real STUN_DURATION_L2 = 1.40
        private constant real STUN_DURATION_L3 = 1.80
        private constant real STUN_DURATION_L4 = 2.20
    endglobals

    //==========================================================================
    // Tunables by ability level (PLACEHOLDERS)
    //==========================================================================
    private constant function GetPickupRadius takes integer level returns real
        if level == 1 then
            return PICKUP_RADIUS_L1
        elseif level == 2 then
            return PICKUP_RADIUS_L2
        elseif level == 3 then
            return PICKUP_RADIUS_L3
        endif
        return PICKUP_RADIUS_L4
    endfunction

    private constant function GetProjectileSpeed takes integer level returns real
        if level == 1 then
            return PROJECTILE_SPEED_L1
        elseif level == 2 then
            return PROJECTILE_SPEED_L2
        elseif level == 3 then
            return PROJECTILE_SPEED_L3
        endif
        return PROJECTILE_SPEED_L4
    endfunction

    private constant function GetProjectileArc takes integer level returns real
        if level == 1 then
            return PROJECTILE_ARC_DEG_L1*bj_DEGTORAD
        elseif level == 2 then
            return PROJECTILE_ARC_DEG_L2*bj_DEGTORAD
        elseif level == 3 then
            return PROJECTILE_ARC_DEG_L3*bj_DEGTORAD
        endif
        return PROJECTILE_ARC_DEG_L4*bj_DEGTORAD
    endfunction

    // Altura inicial adicional sobre la altura actual del edificio.
    private constant function GetProjectileStartHeightOffset takes integer level returns real
        if level == 1 then
            return PROJECTILE_START_Z_OFFSET_L1
        elseif level == 2 then
            return PROJECTILE_START_Z_OFFSET_L2
        elseif level == 3 then
            return PROJECTILE_START_Z_OFFSET_L3
        endif
        return PROJECTILE_START_Z_OFFSET_L4
    endfunction

    // Altura final adicional al llegar al punto objetivo.
    private constant function GetProjectileImpactHeightOffset takes integer level returns real
        if level == 1 then
            return PROJECTILE_IMPACT_Z_OFFSET_L1
        elseif level == 2 then
            return PROJECTILE_IMPACT_Z_OFFSET_L2
        elseif level == 3 then
            return PROJECTILE_IMPACT_Z_OFFSET_L3
        endif
        return PROJECTILE_IMPACT_Z_OFFSET_L4
    endfunction

    // Colisión del misil durante vuelo (0 = no colisión en vuelo).
    private constant function GetProjectileCollision takes integer level returns real
        if level == 1 then
            return PROJECTILE_COLLISION_L1
        elseif level == 2 then
            return PROJECTILE_COLLISION_L2
        elseif level == 3 then
            return PROJECTILE_COLLISION_L3
        endif
        return PROJECTILE_COLLISION_L4
    endfunction

    // Aceleración por tick del sistema Missile (normalmente 0 para vuelo estable).
    private constant function GetProjectileAcceleration takes integer level returns real
        if level == 1 then
            return PROJECTILE_ACCELERATION_L1
        elseif level == 2 then
            return PROJECTILE_ACCELERATION_L2
        elseif level == 3 then
            return PROJECTILE_ACCELERATION_L3
        endif
        return PROJECTILE_ACCELERATION_L4
    endfunction

    private constant function GetManaRefund takes integer level returns real
        if level == 1 then
            return MANA_REFUND_L1
        elseif level == 2 then
            return MANA_REFUND_L2
        elseif level == 3 then
            return MANA_REFUND_L3
        endif
        return MANA_REFUND_L4
    endfunction

    private constant function GetImpactAoe takes integer level returns real
        if level == 1 then
            return IMPACT_AOE_L1
        elseif level == 2 then
            return IMPACT_AOE_L2
        elseif level == 3 then
            return IMPACT_AOE_L3
        endif
        return IMPACT_AOE_L4
    endfunction

    private constant function GetImpactDamage takes integer level returns real
        if level == 1 then
            return IMPACT_DAMAGE_L1
        elseif level == 2 then
            return IMPACT_DAMAGE_L2
        elseif level == 3 then
            return IMPACT_DAMAGE_L3
        endif
        return IMPACT_DAMAGE_L4
    endfunction

    private constant function GetStunDuration takes integer level returns real
        if level == 1 then
            return STUN_DURATION_L1
        elseif level == 2 then
            return STUN_DURATION_L2
        elseif level == 3 then
            return STUN_DURATION_L3
        endif
        return STUN_DURATION_L4
    endfunction

    //==========================================================================
    // Runtime state
    //==========================================================================
    globals
        private Table inFlightByHandle
        private Table scriptStunStacks

        private boolean array cleaned
        private real array originX
        private real array originY
        private real array originFlyZ
        private real array targetX
        private real array targetY
        private real array launchFacing

    endglobals

    private function PlaceBuilding takes unit u, real x, real y returns nothing
        call SetUnitX(u, x)
        call SetUnitY(u, y)
        call SetUnitPosition(u, x, y)
    endfunction

    private function GetLandingFacing takes integer dex, unit structureUnit returns real
        if USE_DEFAULT_BUILDING_FACING_ON_LAND then
            return DEFAULT_BUILDING_FACING_ON_LAND
        endif
        return launchFacing[dex]
    endfunction

    private function IsWhitelistedStructureType takes integer unitTypeId returns boolean
        if not USE_STRUCTURE_WHITELIST then
            return true
        endif
        return unitTypeId == WHITELIST_TYPE_1 or unitTypeId == WHITELIST_TYPE_2 or unitTypeId == WHITELIST_TYPE_3 or unitTypeId == WHITELIST_TYPE_4
    endfunction

    private function IsValidPickup takes unit u, player owner returns boolean
        local integer unitTypeId
        if u == null then
            return false
        endif
        if not UnitAlive(u) then
            return false
        endif
        if GetOwningPlayer(u) != owner then
            return false
        endif
        if not IsUnitType(u, UNIT_TYPE_STRUCTURE) then
            return false
        endif
        set unitTypeId = GetUnitTypeId(u)
        if unitTypeId == 0 then
            return false
        endif
        if inFlightByHandle.boolean[GetHandleId(u)] then
            return false
        endif
        return IsWhitelistedStructureType(unitTypeId)
    endfunction

    private function IsValidImpactTarget takes unit u, player owner returns boolean
        if u == null then
            return false
        endif
        if not UnitAlive(u) then
            return false
        endif
        if not IsUnitEnemy(u, owner) then
            return false
        endif
        if (not IMPACT_CAN_HIT_STRUCTURES) and IsUnitType(u, UNIT_TYPE_STRUCTURE) then
            return false
        endif
        return true
    endfunction

    private function PlaySoundAt takes string file, real x, real y returns nothing
        local sound s
        if file == "" then
            return
        endif
        set s = CreateSound(file, false, false, false, 10, 10, "")
        call SetSoundPosition(s, x, y, 0.)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function RefundMana takes unit caster, integer level returns nothing
        local real refund = GetManaRefund(level)
        local real mana
        local real maxMana
        if caster == null or refund <= 0. then
            return
        endif
        if GetUnitTypeId(caster) == 0 then
            return
        endif
        set mana = GetUnitState(caster, UNIT_STATE_MANA) + refund
        set maxMana = GetUnitState(caster, UNIT_STATE_MAX_MANA)
        if mana > maxMana then
            set mana = maxMana
        endif
        call SetUnitState(caster, UNIT_STATE_MANA, mana)
    endfunction

    private function FindNearestOwnedStructure takes unit caster, player owner, real radius returns unit
        local real cx = GetUnitX(caster)
        local real cy = GetUnitY(caster)
        local unit u
        local unit best = null
        local real dx
        local real dy
        local real distSq
        local real bestSq = 999999999.
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, cx, cy, radius, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if IsValidPickup(u, owner) then
                set dx = GetUnitX(u) - cx
                set dy = GetUnitY(u) - cy
                set distSq = dx*dx + dy*dy
                if distSq < bestSq then
                    set bestSq = distSq
                    set best = u
                endif
            endif
        endloop
        set u = null
        return best
    endfunction

    private function OnScriptStunExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit target = dex.target
        local integer hid = dex.count
        local integer stacks = scriptStunStacks[hid] - 1

        if stacks <= 0 then
            call scriptStunStacks.remove(hid)
            if target != null and GetUnitTypeId(target) != 0 then
                call PauseUnit(target, false)
            endif
        else
            set scriptStunStacks[hid] = stacks
        endif

        call dex.destroy()
        call ReleaseTimer(t)
        set target = null
        set t = null
    endfunction

    private function ApplyScriptStun takes unit target, real duration returns nothing
        local integer hid
        local integer stacks
        local SpellIndex dex
        if duration <= 0. then
            return
        endif
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        set stacks = scriptStunStacks[hid] + 1
        set scriptStunStacks[hid] = stacks
        if stacks == 1 then
            call PauseUnit(target, true)
        endif
        set dex = SpellIndex.create()
        set dex.target = target
        set dex.count = hid
        call TimerStart(NewTimerEx(dex), duration, false, function OnScriptStunExpire)
    endfunction

    private function ApplyImpactStun takes unit target, player owner, integer level returns nothing
        if USE_SCRIPT_STUN then
            call ApplyScriptStun(target, GetStunDuration(level))
        endif
        if USE_DUMMY_STUN then
            call DummyCaster[STUN_DUMMY_ABILITY].castTarget(owner, level, STUN_ORDER_ID, target)
        endif
    endfunction

    private function MarkBuildingInFlight takes unit u, boolean flag returns nothing
        local integer hid
        if u == null then
            return
        endif
        set hid = GetHandleId(u)
        if flag then
            set inFlightByHandle.boolean[hid] = true
        else
            call inFlightByHandle.boolean.remove(hid)
        endif
    endfunction

    private function CleanupCast takes SpellIndex dex returns nothing
        local unit structureUnit = dex.target
        if cleaned[dex] then
            set structureUnit = null
            return
        endif
        set cleaned[dex] = true
        if structureUnit != null and GetUnitTypeId(structureUnit) != 0 then
            call PauseUnit(structureUnit, false)
            call SetUnitInvulnerable(structureUnit, false)
            call SetUnitPathing(structureUnit, true)
            call SetUnitFlyHeight(structureUnit, originFlyZ[dex], 0.)
            call MarkBuildingInFlight(structureUnit, false)
        endif
        set originX[dex] = 0.
        set originY[dex] = 0.
        set originFlyZ[dex] = 0.
        set targetX[dex] = 0.
        set targetY[dex] = 0.
        set launchFacing[dex] = 0.
        call dex.destroy()
        set structureUnit = null
    endfunction

    private function DealImpact takes SpellIndex dex, unit structureUnit, real x, real y returns nothing
        local unit u
        local player owner = dex.user
        local unit damageSource = dex.source
        local real aoe = GetImpactAoe(dex.level)
        local real damage = GetImpactDamage(dex.level)

        if IMPACT_FX != "" then
            call DestroyEffect(AddSpecialEffect(IMPACT_FX, x, y))
        endif
        call PlaySoundAt(IMPACT_SOUND, x, y)

        if damageSource == null or GetUnitTypeId(damageSource) == 0 then
            set damageSource = structureUnit
        endif

        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, aoe, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if IsValidImpactTarget(u, owner) then
                if damageSource != null and GetUnitTypeId(damageSource) != 0 then
                    call UnitDamageTarget(damageSource, u, damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
                call ApplyImpactStun(u, owner, dex.level)
            endif
        endloop

        set u = null
        set owner = null
        set damageSource = null
    endfunction

    private struct TinyBuildingTossCore extends array
        private static method onFinish takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            local unit structureUnit = missile.dummy

            if cleaned[dex] then
                set structureUnit = null
                return true
            endif

            if structureUnit != null and GetUnitTypeId(structureUnit) != 0 then
                call SetUnitPathing(structureUnit, true)
                call PauseUnit(structureUnit, false)
                call SetUnitInvulnerable(structureUnit, false)
                call PlaceBuilding(structureUnit, targetX[dex], targetY[dex])
                call SetUnitFacing(structureUnit, GetLandingFacing(dex, structureUnit))
                call SetUnitFlyHeight(structureUnit, originFlyZ[dex], 0.)
                call DealImpact(dex, structureUnit, GetUnitX(structureUnit), GetUnitY(structureUnit))
            endif

            call CleanupCast(dex)
            set structureUnit = null
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            local unit structureUnit = missile.dummy

            if not cleaned[dex] then
                if structureUnit != null and GetUnitTypeId(structureUnit) != 0 then
                    call SetUnitPathing(structureUnit, true)
                    call PauseUnit(structureUnit, false)
                    call SetUnitInvulnerable(structureUnit, false)
                    call SetUnitFlyHeight(structureUnit, originFlyZ[dex], 0.)
                    call PlaceBuilding(structureUnit, originX[dex], originY[dex])
                endif
                call CleanupCast(dex)
            endif

            set structureUnit = null
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function OnEffect takes nothing returns nothing
        local unit caster = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        local integer level = GetUnitAbilityLevel(caster, TINY_TOSS_ABILITY)
        local unit picked
        local real cx
        local real cy
        local real baseFlyZ
        local real launchStartZ
        local real launchImpactZ
        local SpellIndex dex
        local Missile missile

        if caster == null or GetUnitTypeId(caster) == 0 then
            set caster = null
            set owner = null
            return
        endif

        set picked = FindNearestOwnedStructure(caster, owner, GetPickupRadius(level))
        if picked == null then
            call SimError(owner, NO_BUILDING_MESSAGE)
            call RefundMana(caster, level)
            set caster = null
            set owner = null
            return
        endif

        set cx = GetUnitX(picked)
        set cy = GetUnitY(picked)
        set baseFlyZ = GetUnitFlyHeight(picked)
        set launchStartZ = baseFlyZ + GetProjectileStartHeightOffset(level)
        set launchImpactZ = baseFlyZ + GetProjectileImpactHeightOffset(level)

        call UnitAddAbility(picked, 'Amrf')
        call UnitRemoveAbility(picked, 'Amrf')
        call SetUnitPathing(picked, false)
        call PauseUnit(picked, true)
        call SetUnitInvulnerable(picked, true)
        call MarkBuildingInFlight(picked, true)

        set dex = SpellIndex.create()
        set dex.source = caster
        set dex.user = owner
        set dex.target = picked
        set dex.level = level

        set originX[dex] = cx
        set originY[dex] = cy
        set originFlyZ[dex] = baseFlyZ
        set targetX[dex] = GetSpellTargetX()
        set targetY[dex] = GetSpellTargetY()
        set launchFacing[dex] = Atan2(targetY[dex] - cy, targetX[dex] - cx)*bj_RADTODEG
        set cleaned[dex] = false

        call SetUnitFlyHeight(picked, launchStartZ, 0.)
        call SetUnitFacing(picked, launchFacing[dex])
        set missile = Missile.createEx(picked, targetX[dex], targetY[dex], launchImpactZ)
        set missile.source = caster
        set missile.owner = owner
        set missile.data = dex
        set missile.collision = GetProjectileCollision(level)
        set missile.arc = GetProjectileArc(level)
        set missile.acceleration = GetProjectileAcceleration(level)
        call missile.setMovementSpeed(GetProjectileSpeed(level))
        call TinyBuildingTossCore.launch(missile)

        set caster = null
        set owner = null
        set picked = null
    endfunction

    private function Init takes nothing returns nothing
        set inFlightByHandle = Table.create()
        set scriptStunStacks = Table.create()
        call RegisterSpellEffectEvent(TINY_TOSS_ABILITY, function OnEffect)
    endfunction

endlibrary

