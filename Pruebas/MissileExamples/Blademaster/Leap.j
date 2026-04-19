//TESH.scrollpos=0
//TESH.alwaysfold=0
library Leap initializer Init uses SpellIndex, IsTerrainWalkable, CameraEQNoise/*v1.0
*************************************************************************************
*
*   Leap into the air, dealing  damage to all close enemies of your destination
*   and slowing their movement speed by 20% for 3 seconds. 
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    //*  The slow duration is hardcoded in the leap buff. Change it there.
    globals
        private constant integer LEAP_ABILITY = 'A003'
        //*  Damage type options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_NORMAL 
        //*  Effect options
        private constant string ON_LANDING_FX    = "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl"
        private constant string WHILE_LEAPING_FX = "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl"
        private constant string FX_ATTACH_POINT  = "weapon"
        //*  Buff variables.
        private constant integer    BUFF_CAST_ID = 'A00B'//*  Raw code of the Leap Apply buff ability  - Object Editor (F6)
        private constant integer    ORDER_ID     = 852075//*  Order of the Leap Apply buff ability     - Trigger Editor (OrderIds) --> slow
    endglobals
    
    //*  Set the impact damage.
    private constant function GetImpactDamage takes integer level returns real
        return 0. + 70*level
    endfunction
    //*  Set the arc of the unit. Play a bit with the values to find a good setup.
    private function GetArc takes real distance returns real
        return 45.*bj_DEGTORAD + RMinBJ(20., distance*.1)*bj_DEGTORAD
    endfunction
    //*  Set the damage collision radius on leap finish.
    private function GetDamageRadius takes integer level returns real
        return 190. + 0.*level
    endfunction
    //*  Set the total air time. Returning 0. is invalid! 
    //* The current setup is -->  minimum + (distance/2)/movement speed.
    private function GetAirTime takes real distance, integer level returns real
        return .3 + (distance*.5)/500.
    endfunction
    //*  Set the offset for the damage effects. It's an empirical value. 
    private constant function GetUnitWeaponOffset takes unit source returns real
        return 75.
    endfunction
    //*  Read the animation time out from the object editor field for your unit.
    //* The current setup is --> slam animation time blademaster 1.133
    private constant function GetUnitAnimationTime takes unit source returns real
        return 1.133
    endfunction
    //*  Filter valid targets.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_FLYING)
    endfunction
    //*  Code which should run on finish leap.
    private function OnFinishLeap takes unit source returns nothing
        if UnitAlive(source) then
            call CameraSetEQNoise(GetOwningPlayer(source), 3., .33)
        endif
    endfunction
    
//========================================================================
//*  Leap code. Make changes carefully.
//========================================================================

    //*  Quite useful, you may outsource it and make it a public function.
    private function IsPointJumpable takes real x, real y returns boolean
        if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            return IsTerrainWalkable(x, y)
        endif
        return false
    endfunction
    
    globals
        private sound error
    endglobals
    
    //*  Uses Missile's API. For a destructable enum, add .onDestructable and .onDestructableFilter.
    private struct Leap extends array
        
        //*  Runs on finish.
        static method onFinish takes Missile missile returns boolean
            local unit source = missile.dummy
            local real unitX = GetUnitX(source)
            local real unitY = GetUnitY(source)
            local real posX = unitX + GetUnitWeaponOffset(source)*Cos(missile.angle)
            local real posY = unitY + GetUnitWeaponOffset(source)*Sin(missile.angle)   
            local unit u
            //*  Restore pathing.
            call SetUnitPathing(source, true)
            if UnitAlive(source) then
                //*  Run effects.
                call DestroyEffect(AddSpecialEffect(ON_LANDING_FX, posX, posY))
                call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, posX, posY, missile.collision, null)
                loop
                    set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                    exitwhen u == null
                    call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
                    if (FilterUnits(u, missile.owner)) then
                        //*  Make pathing space for the leaping unit.
                        call SetUnitPosition(u, GetUnitX(u), GetUnitY(u))
                        //*  Deal damage and apply the buff.
                        if (UnitDamageTarget(source, u, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)) then
                            call DummyCaster[BUFF_CAST_ID].castTarget(missile.owner, 1, ORDER_ID, u)
                        endif
                    endif
                endloop
            endif
            call SetUnitPosition(source, unitX, unitY)
            call OnFinishLeap(source)
            call SetUnitTimeScale(source, 1.)
            call SpellIndex(missile.data).destroy()
            set source = null
            return true
        endmethod
        
        implement MissileStruct
    endstruct
    
    private function OnEffect takes nothing returns nothing
        local string prefix = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n|cffffcc00"
        local unit source = GetTriggerUnit()
        local integer level =  GetUnitAbilityLevel(source, LEAP_ABILITY)
        local real time 
        local real distance
        local Missile missile
        //*  Check for terrain pathability.
        if IsPointJumpable(GetSpellTargetX(), GetSpellTargetY()) then
            //*  Make sure the caster can fly.
            if UnitAddAbility(source, 'Amrf') and UnitRemoveAbility(source, 'Amrf') then
            endif
            //*  Transform the source unit into a Missile instance.
            set missile = Missile.createEx(source, GetSpellTargetX(), GetSpellTargetY(), GetUnitDefaultFlyHeight(source))
            set distance = missile.origin.distance
            set time = GetAirTime(distance, level)
            set missile.arc = GetArc(distance)
            set missile.speed = distance/time*Missile_TIMER_TIMEOUT
            set missile.owner = GetTriggerPlayer()
            set missile.damage = GetImpactDamage(level)
            set missile.collision = GetDamageRadius(level)
            call Leap.launch(missile)
            //*  Add effect.
            set missile.data = SpellIndex.create()
            set SpellIndex(missile.data).fx = AddSpecialEffectTarget(WHILE_LEAPING_FX, source, FX_ATTACH_POINT)
            //*
            call SetUnitTimeScale(source, GetUnitAnimationTime(source)*.5/time)
            call SetUnitPathing(source, false)
        else
            //*  Invalid jump location!
            call PauseUnit(source, true)
            call IssueImmediateOrderById(source, 851972)
            call PauseUnit(source, false)
            //*  Simulate Warcraft III error message.
            if GetLocalPlayer() == GetTriggerPlayer() then
                call StartSound(error)
                call ClearTextMessages()
            endif
            call DisplayTimedTextToPlayer(GetTriggerPlayer(), .52, .96, 2., prefix + GetUnitName(source) + " can't jump there!|r")
        endif
        set source = null
    endfunction
    
    private function Init takes nothing returns nothing
        set error = CreateSoundFromLabel("InterfaceError", false, false, false, 10, 10)
        call RegisterSpellEffectEvent(LEAP_ABILITY, function OnEffect)
    endfunction
    
endlibrary