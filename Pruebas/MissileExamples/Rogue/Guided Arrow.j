//TESH.scrollpos=75
//TESH.alwaysfold=0
library GuidedArrow initializer Init uses SpellIndex, Missile /* v2.0
*************************************************************************************
*
*   The caster fires an arrow which tracks down it's target.
*   On impact the arrow eventually pierces and hits the target again.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer GUIDED_ARROW_ABILITY = 'A00E'
        // Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        // Effect options.
        private constant string ON_TARGET_FX    = "Abilities\\Spells\\NightElf\\Barkskin\\BarkSkinTarget.mdl"
        private constant string FX_ATTACH_POINT = "overhead"
        // Constant missile options.
        private constant real ARROW_ACTION_DELAY         = 0.3 // Timeout before the arrow starts to turn.
        private constant real UNIT_DETECTION_AOE         = 400.// Area in which the arrow searches for targets. 
        private constant real ARROW_FLY_RUN_OUT_DISTANCE = 350.// Distance traveled if the target dies.
        private constant real ARROW_FLY_HEIGHT           = 65.
        private constant real ARROW_TURN_RATE            = 8.*bj_DEGTORAD
        private constant real ALLOW_HIT_AFTER            = 1.  // Minimum amount of seconds until the missile can damage again.
    endglobals
    
    // Filter valid target units.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner)
    endfunction
    // Set the maximum travel distance. Does no longer count, when a traget is found.
    private constant function GetFlyDistance takes integer level returns real
        return  800. + (200*level)
    endfunction
    // Set the number of pierce events. 
    private function GetPiercingCount takes integer level returns integer
        return GetRandomInt(0, 3) + 1*level 
    endfunction
    //*  Customize all missile members to your needs.
    private function CustomizeMissile takes Missile missile, integer level returns nothing
        set missile.speed  = 20. + 0.*level
        set missile.damage = 0. + 30.*level
        set missile.collision = 32.
        set missile.model = "Abilities\\Spells\\Other\\BlackArrow\\BlackArrowMissile.mdl"
        set missile.scale = 1.
    endfunction
    
//========================================================================
// Guided arrow code. Make changes carefully.
//========================================================================

    globals
        // "tempOwner" is always set to the owner of the arrow before "ConsiderUnitFiltered" is called.
        private player tempOwner = null
    endglobals
    
    // Filters valid targets for the arrow.
    private function ConsiderUnitsFiltered takes nothing returns boolean
        return FilterUnits(GetFilterUnit(), tempOwner)
    endfunction

    private struct GuidedArrow extends array
        static boolexpr filter 
        
        // Runs when the missile is deallocated.
        private static method onRemove takes Missile missile returns boolean
            call SpellIndex(missile.data).destroy()
            return true
        endmethod
        
        // Runs when the maximum range is reached.
        private static method onFinish takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            return (dex.phase == 0) or (GetUnitTypeId(dex.target) == 0)
        endmethod
        
        // Runs when a missile collides with a unit.
        private static method onCollide takes Missile missile, unit hit returns boolean
            local SpellIndex dex = missile.data
            // Only the target is valid.
            if (hit == missile.target) then
                // Allows the missile to hit the target again after 1 second.
                call missile.enableHitAfter(hit, ALLOW_HIT_AFTER)
                call UnitDamageTarget(missile.source, hit, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                set missile.target = null
                set missile.turn = 0
                // Reduce the total amount of pierces.
                set dex.count = dex.count - 1
            endif
            return (dex.count < 0)
        endmethod
        
        private static method searchTarget takes Missile missile returns nothing
            local SpellIndex dex = missile.data
            //
            set tempOwner = missile.owner
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, UNIT_DETECTION_AOE , thistype.filter)
            if (FirstOfGroup(SpellIndex.GLOBAL_GROUP) != null) then
                set bj_groupRandomConsidered = 0
                set bj_groupRandomCurrentPick = null
                call ForGroup(SpellIndex.GLOBAL_GROUP, function GroupPickRandomUnitEnum)
                call GroupClear(SpellIndex.GLOBAL_GROUP)
                // 
                set missile.target = bj_groupRandomCurrentPick
                set dex.target = bj_groupRandomCurrentPick
                set dex.time = ARROW_ACTION_DELAY
                set missile.turn = ARROW_TURN_RATE
                // Just in case this unit was already hit, while missile.target was null.
                // Remember: onCollide runs before onPeriod.
                call missile.removeHitWidget(bj_groupRandomCurrentPick)
                //
                set bj_groupRandomCurrentPick = null
                if (dex.fx != null) then
                    call DestroyEffect(dex.fx)
                    set dex.fx = null
                endif
                set dex.fx = AddSpecialEffectTarget(ON_TARGET_FX, dex.target, FX_ATTACH_POINT) 
            endif
        endmethod
        
        // Runs every timer interval. Let's break the mechanics down.
        private static method onPeriod takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            
            // In this phase no target was found yet. And no pierce event did take place.
            if (dex.target == null) and (dex.count >= 0) then              
                // Check the action delay.
                if (dex.time > 0.) then
                    set dex.time = dex.time - Missile_TIMER_TIMEOUT
                    return false
                endif
                call searchTarget(missile)
            //
            // In this phase we have a target stored on dex.target, but the missile doesn't know that.
            elseif (missile.target == null) and (UnitAlive(dex.target)) then
                // Check the action delay.
                if (dex.time > 0.) then
                    set dex.time = dex.time - Missile_TIMER_TIMEOUT
                    return false
                endif
                set dex.time = ARROW_ACTION_DELAY
                set missile.turn = ARROW_TURN_RATE
                set missile.target = dex.target
            //
            // In this phase the target died. Let the missile run out.
            elseif not UnitAlive(dex.target) then
                set dex.count = -1
                set dex.target = null
                set missile.turn = 0.
                set missile.target = null
                set missile.collision = 0.
                if (dex.phase == 1) then
                    set dex.phase = 0
                    call missile.origin.move(missile.x, missile.y, missile.z)
                    call missile.impact.move(missile.x + Cos(missile.angle)*ARROW_FLY_RUN_OUT_DISTANCE, missile.y + Sin(missile.angle)*ARROW_FLY_RUN_OUT_DISTANCE, missile.z)
                endif
            endif
            return false
        endmethod

        implement MissileStruct
    endstruct 

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer level = GetUnitAbilityLevel(source, GUIDED_ARROW_ABILITY)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        local SpellIndex dex = SpellIndex.create()
        // Create a new missile and assign its members.
        local Missile missile = Missile.create(x, y, ARROW_FLY_HEIGHT, angle, GetFlyDistance(level), ARROW_FLY_HEIGHT)
        // Allows configuration.
        call CustomizeMissile(missile, level)
        // Override user settings. These missile members are reserved.
        set missile.source = source
        set missile.owner = GetTriggerPlayer()
        set missile.data = dex
        set missile.target = null
        call GuidedArrow.launch(missile)
        // Assign data to the spell index.
        set dex.count = GetPiercingCount(level)
        set dex.time = ARROW_ACTION_DELAY
        set dex.target = GetSpellTargetUnit()
        if not FilterUnits(dex.target, missile.owner) then
            set dex.target = null
        endif
        set dex.phase = 1
        // Run effects.
        if (dex.target != null) then
            set dex.fx = AddSpecialEffectTarget(ON_TARGET_FX, dex.target, FX_ATTACH_POINT) 
        endif
        set source = null
    endfunction

    private function Init takes nothing returns nothing
        set GuidedArrow.filter = Filter(function ConsiderUnitsFiltered)
        call RegisterSpellEffectEvent(GUIDED_ARROW_ABILITY, function OnEffect)
    endfunction

endlibrary