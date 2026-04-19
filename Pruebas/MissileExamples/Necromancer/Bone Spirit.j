//TESH.scrollpos=3
//TESH.alwaysfold=0
library BoneSpirit initializer Init uses SpellIndex, Missile /*v2.0
*************************************************************************************
*
*   The Spirit tracks down a target, or finds one of its own.
*   On impact the spirit stuns the target.
*   © Blizzard Entertainment, Diablo II
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer BONE_SPIRIT_ABILITY = 'A008'
        //*  Damage options.
        private constant attacktype ATTACK_TYPE     = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE     = DAMAGE_TYPE_MAGIC
        private constant boolean    HIT_TARGET_ONLY = false//*  If false the spirit may also collide with any enemy unit in this path.
        //*  Missile options.                                   For true it only hit the unit it's chasing after.
        private constant real   SPIRIT_FLY_HEIGHT  = 65.
        private constant real   UNIT_DETECTION_AOE = 400.//*  Searches nerby enemies within this range.
        private constant real   COLLISION_SIZE     = 32.
        private constant real   DETECTION_DELAY    = 0.3//*  Short delay after losing a target, before new target is considered.
        private constant real   SPIRIT_SCALE       = 0.9
        private constant string SPIRIT_MODEL       = "Abilities\\Spells\\Undead\\Possession\\PossessionMissile.mdl"
        //*  Buff variables.
        private constant integer    BUFF_CAST_ID = 'A009'//*  Raw code of the Bone Spirit apply buff ability  - Object Editor (F6)
        private constant integer    ORDER_ID     = 852095//*  Order of the Bone Spirit apply buff ability     - Trigger Editor (OrderIds) --> thunderbolt
    endglobals
    
    //*  Filter out which units should be damaged.
    private function FilterUnits takes unit target, player p returns boolean
        return (UnitAlive(target)) and (IsUnitEnemy(target, p)) and (not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE))
    endfunction
    //*  Set the maximum fly distance.
    private constant function GetFlyDistance takes integer level returns real
        return  800. + (250*level)
    endfunction
    //*  Set the movement speed for the spirit.
    private constant function GetMovementSpeed takes integer level returns real
        return 440. + (0*level)
    endfunction
    //*  Set the impact damage.
    private constant function GetImpactDamage takes integer level returns real
        return 0. + (90.*level)
    endfunction
    
//========================================================================
//*  Bone spirit code. Make changes carefully.
//========================================================================
    
    globals
        //*  "tempOwner" is always set to the owner of the spirit before "ConsiderUnitFiltered" is called.
        private player tempOwner = null
    endglobals
    
    //*  Filters valid targets for the spirit.
    private function ConsiderUnitsFiltered takes nothing returns boolean
        return FilterUnits(GetFilterUnit(), tempOwner)
    endfunction
    
    //*  Uses Missile's API. Add or remove whatever you need.
    private struct BoneSpirit extends array
        static boolexpr filter 
        static real array delay
                
        //*  Removes the effect delayed.
        private static method onRemove takes Missile missle returns boolean
            return true
        endmethod
        
        //*  Runs on missile collide with any unit.
        private static method onCollide takes Missile missile, unit hit returns boolean
            if (FilterUnits(hit, missile.owner)) then
                static if HIT_TARGET_ONLY then
                    if (hit != missile.target) then
                        return false
                    endif
                endif
                call DummyCaster[BUFF_CAST_ID].castTarget(missile.owner, 1, ORDER_ID, hit)
                call UnitDamageTarget(missile.source, hit, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                return true
            endif
            return false
        endmethod
        
        //*  Checks for new valid targets.
        private static method onPeriod takes Missile missile returns boolean
            set delay[missile] = delay[missile] - Missile_TIMER_TIMEOUT
            if not UnitAlive(missile.target) and (delay[missile] <= 0.) then
                set delay[missile] = DETECTION_DELAY
                set tempOwner = missile.owner
                call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, UNIT_DETECTION_AOE , thistype.filter)
                if (FirstOfGroup(SpellIndex.GLOBAL_GROUP) != null) then
                    set bj_groupRandomConsidered = 0
                    set bj_groupRandomCurrentPick = null
                    call ForGroup(SpellIndex.GLOBAL_GROUP, function GroupPickRandomUnitEnum)
                    call GroupClear(SpellIndex.GLOBAL_GROUP)//*  Not really required. GroupEnum functions always clear groups.
                    set missile.target = bj_groupRandomCurrentPick
                    set bj_groupRandomCurrentPick = null
                endif
            endif
            return false
        endmethod
        
        implement MissileStruct
    endstruct
        
    function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer level = GetUnitAbilityLevel(source, BONE_SPIRIT_ABILITY)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        //*  Create a new missile and assign members.
        local Missile missile = Missile.create(x, y, SPIRIT_FLY_HEIGHT, angle, GetFlyDistance(level), SPIRIT_FLY_HEIGHT)
        set missile.damage = GetImpactDamage(level)
        set missile.collision = COLLISION_SIZE
        set missile.source = source
        set missile.target = GetSpellTargetUnit()
        set missile.owner = GetTriggerPlayer()
        set missile.speed = GetMovementSpeed(level)*Missile_TIMER_TIMEOUT
        set missile.model = SPIRIT_MODEL
        set missile.scale = SPIRIT_SCALE
        call BoneSpirit.launch(missile)
        //*
        set BoneSpirit.delay[missile] = DETECTION_DELAY
        set source = null
    endfunction
    
    private function Init takes nothing returns nothing
        set BoneSpirit.filter = Filter(function ConsiderUnitsFiltered)
        call RegisterSpellEffectEvent(BONE_SPIRIT_ABILITY, function OnEffect)
    endfunction

endlibrary