library LoadoutMoveCastConfi initializer Init requires MovementSystem, WeaponProfileConfig, LoadoutMissile, LoadoutControl, LoadoutLeapMissile, LoadoutRocketLauncher, LoadoutMetalSlugSpecial, LoadoutIronLizard, LoadoutThunderShot
//===========================================================================
// Loadout MoveCast integration config
// - Registers every Metal Slug weapon fire ability.
// - MoveCast uses a fixed directional session duration independent of
//   weapon profile cast durations.
//===========================================================================

    globals
        private constant boolean LOADOUT_MOVECAST_ENABLED = true
        private constant real LOADOUT_MOVECAST_FIXED_DURATION = 1.00
        private constant integer LOADOUT_MOVECAST_MAX_SMART_RECASTS = 3
    endglobals

    private function RegisterWeaponMoveCast takes integer abilityId, string orderName returns nothing
        call RegisterMovementSpell(abilityId, orderName)
        call ConfigureMovementSpellCastSession(abilityId, LOADOUT_MOVECAST_FIXED_DURATION, true, LOADOUT_MOVECAST_MAX_SMART_RECASTS)
    endfunction

    private function Init takes nothing returns nothing
        if LOADOUT_MOVECAST_ENABLED then
            call RegisterWeaponMoveCast('U0A1', "avatar")
            call RegisterWeaponMoveCast('U0A3', "banish")
            call RegisterWeaponMoveCast('U0A4', "barkskin")
            call RegisterWeaponMoveCast('U0A5', "cripple")
            call RegisterWeaponMoveCast('U0A6', "barkskinon")
            call RegisterWeaponMoveCast('U0A7', "battleroar")
            call RegisterWeaponMoveCast('U0A8', "channel")
            call RegisterWeaponMoveCast('U0A9', "chainlightning")
            call RegisterWeaponMoveCast('U0AA', "carrionswarm")
            call RegisterWeaponMoveCast('U0AB', "breathoffire")
            call RegisterWeaponMoveCast('U0AC', "blizzard")
            call RegisterWeaponMoveCast('U0AD', "clusterrockets")
            call RegisterWeaponMoveCast('U0AE', "thunderbolt")
            call RegisterWeaponMoveCast(WEAPON_INVENTORY_FIRE_ABILITY, "channel")
        endif
    endfunction

endlibrary
