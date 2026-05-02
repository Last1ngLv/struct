library SelectionHeroVisualConfig requires PlayerMissileLoadout, WeaponProfileConfig, WeaponSelectionSystem

    function SelectionSetupHeroVisual takes integer heroId, player p returns nothing
        local string dummyFx1 = ""
        local string dummyFx2 = ""
        local real dummyScale = .1
        local real dummyOffset = 0.

        if heroId == 0 then
            set dummyScale = 1.25
        elseif heroId == 1 then
            set dummyScale = 1.25
        elseif heroId == 2 then
            set dummyScale = 1.25
        elseif heroId == 3 then
            set dummyScale = 1.25
        elseif heroId == 4 then
            set dummyScale = 1.25
        elseif heroId == 5 then
            set dummyScale = 1.25
        endif

        call SetPlayerLeapDummyFx(p, dummyFx1, dummyFx2)
        call SetPlayerLeapDummyScale(p, dummyScale)
        call SetPlayerLeapDummyFlightOffset(p, dummyOffset)
        call SetPlayerOrbLevel(p, 1)
        call SetPlayerMissileHealOnHit(p, 0.00)
        call SetPlayerPointsOfMana(p, 1)
        call SetPlayerMissileDamageValue(p, WeaponProfileGetDamage(WEAPON_PROFILE_HANDGUN))
        call SetPlayerMissileUseRapidFire(p, true)
        call EnsurePlayerDefaultWeaponProfile(p)
    endfunction

endlibrary
