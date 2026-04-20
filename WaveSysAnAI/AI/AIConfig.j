library AIConfig initializer Init requires AIProfiles

    globals
        constant integer AI_PROFILE_WAVE1_SPELL = 101
        constant integer AI_PROFILE_WAVE2_SPELL = 102
        constant integer AI_PROFILE_WAVE3_SPELL = 103
        constant integer AI_PROFILE_WAVE4_SPELL = 104
        constant integer AI_PROFILE_BOSS = 105
        constant integer AI_PROFILE_WAVE6_SPELL = 106
        constant integer AI_PROFILE_WAVE7_SPELL = 107
        constant integer AI_PROFILE_WAVE8_SPELL = 108
        constant integer AI_PROFILE_WAVE9_SPELL = 109
        constant integer AI_PROFILE_WAVE10_SPELL = 110
        constant integer AI_PROFILE_WAVE6_BOSS = 111
        constant integer AI_PROFILE_WAVE7_BOSS = 112
        constant integer AI_PROFILE_WAVE8_BOSS = 113
        constant integer AI_PROFILE_WAVE9_BOSS = 114
        constant integer AI_PROFILE_WAVE10_BOSS = 115
        constant integer AI_STAGE1_SLOT_GROUP_HPEA = 2001
        constant integer AI_STAGE1_SLOT_GROUP_HMIL = 2002
        constant integer AI_STAGE1_SLOT_GROUP_HFOO = 2003
        constant integer AI_STAGE1_SLOT_GROUP_HRIF = 2004
        constant integer AI_STAGE1_SLOT_GROUP_HKNI = 2005
        constant integer AI_STAGE1_SLOT_GROUP_HMTM = 2006
        constant integer AI_STAGE1_SLOT_GROUP_HMPR = 2007
        constant integer AI_STAGE1_SLOT_GROUP_HSOR = 2008
        constant integer AI_STAGE1_SLOT_GROUP_HMTT = 2009
        constant integer AI_STAGE1_SLOT_GROUP_HWT3 = 2010
    endglobals

    private function AIApplyBossTeleportDefaults takes integer profileId returns nothing
        call AISetProfileTeleport(profileId, true, false, 10.0, 16.0, 5.0, 9.0, 120.0, 360.0, "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")
    endfunction

    private function Init takes nothing returns nothing
        call AIRegisterProfile(AI_DEFAULT_PROFILE_ID, 0.25, 0.50, 10500.0, 6000.0, 10.0)
        call AISetProfileBehavior(AI_DEFAULT_PROFILE_ID, 1.00, 0)

        call AIRegisterProfile(AI_PROFILE_MELEE, 0.25, 0.50, 10500.0, 6000.0, 10.0)
        call AISetProfileBehavior(AI_PROFILE_MELEE, 1.15, 0)
        call AISetProfileOrderInterval(AI_PROFILE_MELEE, 0.30)

        call AIRegisterProfile(AI_PROFILE_RANGED, 0.25, 0.50, 10500.0, 6000.0, 200.0)
        call AISetProfileBehavior(AI_PROFILE_RANGED, 1.05, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_RANGED, 0.40)

        call AIRegisterProfile(AI_PROFILE_CASTER, 0.25, 0.50, 10500.0, 6000.0, 500.0)
        call AISetProfileBehavior(AI_PROFILE_CASTER, 1.00, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_CASTER, 0.45)
        call AISetProfileTeleport(AI_PROFILE_CASTER, true, false, 5.0, 8.0, 1.5, 3.0, 1680.0, 1825.0, "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")

        call AIRegisterProfile(AI_PROFILE_WAVE1_SPELL, 0.25, 0.50, 10500.0, 6000.0, 1800.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE1_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE1_SPELL, 0.35)
        call AIAddAbilityRuleEx(AI_PROFILE_WAVE1_SPELL, 'AU01', "ambush", AI_TARGET_POINT, 0.0, 5000.0, 0.0, 0.0, 0, 0.0, 100, 6.0, true, 2.00)
        call AISetProfileTeleport(AI_PROFILE_WAVE1_SPELL, false, false, 8.0, 12.0, 2.0, 4.0, 150.0, 240.0, "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")

        call AIRegisterProfile(AI_PROFILE_WAVE2_SPELL, 0.25, 0.50, 10500.0, 6000.0, 1800.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE2_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE2_SPELL, 0.35)
        call AIAddAbilityRuleEx(AI_PROFILE_WAVE2_SPELL, 'AU01', "ambush", AI_TARGET_POINT, 0.0, 5000.0, 0.0, 0.0, 0, 0.0, 100, 6.0, true, 2.00)
        call AISetProfileTeleport(AI_PROFILE_WAVE2_SPELL, true, false, 7.0, 11.0, 2.0, 4.0, 1660.0, 1860.0, "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")

        call AIRegisterProfile(AI_PROFILE_WAVE4_SPELL, 0.25, 0.50, 10500.0, 6000.0, 1200.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE4_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE4_SPELL, 0.35)
        call AIAddAbilityRuleEx(AI_PROFILE_WAVE4_SPELL, 'AU01', "ambush", AI_TARGET_POINT, 0.0, 1550.0, 0.0, 0.0, 0, 0.0, 100, 6.0, true, 2.00)
        call AISetProfileTeleport(AI_PROFILE_WAVE4_SPELL, false, true, 6.0, 10.0, 3.0, 5.0, 1600.0, 1820.0, "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")

        call AIRegisterProfile(AI_PROFILE_BOSS, 0.20, 0.45, 6000.0, 10000.0, 10.0)
        call AISetProfileBehavior(AI_PROFILE_BOSS, 1.10, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_BOSS, 0.40)
        call AIApplyBossTeleportDefaults(AI_PROFILE_BOSS)

        call AIRegisterProfile(AI_PROFILE_WAVE6_SPELL, 0.25, 0.50, 10500.0, 6000.0, 2000.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE6_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE6_SPELL, 0.35)

        call AIRegisterProfile(AI_PROFILE_WAVE7_SPELL, 0.25, 0.50, 10500.0, 6000.0, 1500.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE7_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE7_SPELL, 0.35)

        call AIRegisterProfile(AI_PROFILE_WAVE8_SPELL, 0.25, 0.50, 10500.0, 6000.0, 2000.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE8_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE8_SPELL, 0.35)

        call AIRegisterProfile(AI_PROFILE_WAVE9_SPELL, 0.25, 0.50, 10500.0, 6000.0, 300.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE9_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE9_SPELL, 0.35)

        call AIRegisterProfile(AI_PROFILE_WAVE10_SPELL, 0.25, 0.50, 10500.0, 6000.0, 850.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE10_SPELL, 1.00, AI_BEHAVIOR_KEEP_DISTANCE)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE10_SPELL, 0.35)

        call AIRegisterProfile(AI_PROFILE_WAVE6_BOSS, 0.20, 0.45, 6000.0, 10000.0, 2000.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE6_BOSS, 1.05, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE6_BOSS, 0.40)
        call AIApplyBossTeleportDefaults(AI_PROFILE_WAVE6_BOSS)

        call AIRegisterProfile(AI_PROFILE_WAVE7_BOSS, 0.20, 0.45, 6000.0, 10000.0, 1500.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE7_BOSS, 1.05, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE7_BOSS, 0.40)
        call AIApplyBossTeleportDefaults(AI_PROFILE_WAVE7_BOSS)

        call AIRegisterProfile(AI_PROFILE_WAVE8_BOSS, 0.20, 0.45, 6000.0, 10000.0, 2000.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE8_BOSS, 1.05, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE8_BOSS, 0.40)
        call AIApplyBossTeleportDefaults(AI_PROFILE_WAVE8_BOSS)

        call AIRegisterProfile(AI_PROFILE_WAVE9_BOSS, 0.20, 0.45, 6000.0, 10000.0, 300.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE9_BOSS, 1.05, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE9_BOSS, 0.40)
        call AIApplyBossTeleportDefaults(AI_PROFILE_WAVE9_BOSS)

        call AIRegisterProfile(AI_PROFILE_WAVE10_BOSS, 0.20, 0.45, 6000.0, 10000.0, 900.0)
        call AISetProfileBehavior(AI_PROFILE_WAVE10_BOSS, 1.05, AI_BEHAVIOR_KEEP_DISTANCE + AI_BEHAVIOR_LOW_HP_BIAS)
        call AISetProfileOrderInterval(AI_PROFILE_WAVE10_BOSS, 0.40)
        call AIApplyBossTeleportDefaults(AI_PROFILE_WAVE10_BOSS)

        call AISetDefaultProfileForUnitType('hrif', AI_PROFILE_WAVE4_SPELL)
        call AISetDefaultProfileForUnitType('hmil', AI_PROFILE_MELEE)
        call AISetDefaultProfileForUnitType('hpea', AI_PROFILE_MELEE)
        call AISetDefaultProfileForUnitType('hfoo', AI_PROFILE_MELEE)
        call AISetDefaultProfileForUnitType('hkni', AI_PROFILE_MELEE)
        call AISetDefaultProfileForUnitType('hmtm', AI_PROFILE_WAVE6_SPELL)
        call AISetDefaultProfileForUnitType('hmpr', AI_PROFILE_WAVE7_SPELL)
        call AISetDefaultProfileForUnitType('hsor', AI_PROFILE_WAVE8_SPELL)
        call AISetDefaultProfileForUnitType('hmtt', AI_PROFILE_WAVE9_SPELL)
        call AISetDefaultProfileForUnitType('hwt3', AI_PROFILE_WAVE10_SPELL)
        call AISetDefaultProfileForUnitType('zA05', AI_PROFILE_WAVE6_BOSS)
        call AISetDefaultProfileForUnitType('zA06', AI_PROFILE_WAVE8_BOSS)
        call AISetDefaultProfileForUnitType('zA07', AI_PROFILE_WAVE7_BOSS)
        call AISetDefaultProfileForUnitType('zA08', AI_PROFILE_WAVE9_BOSS)
        call AISetDefaultProfileForUnitType('zA09', AI_PROFILE_WAVE10_BOSS)
    endfunction
endlibrary
