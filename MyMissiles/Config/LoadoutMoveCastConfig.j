library LoadoutMoveCastConfi initializer Init requires MovementSystem, LoadoutMissile, LoadoutControl, LoadoutLeapMissile, LoadoutRocketLauncher
//===========================================================================
// Loadout MoveCast integration config
// - Keeps loadout spell registration out of PreConfi to avoid dependency cycles.
// - Uses public duration getters from the owning loadout spell libraries.
//===========================================================================

    private function Init takes nothing returns nothing
        call RegisterMovementSpell('U0A1', "avatar")
        call RegisterMovementSpell('U0A3', "banish")
        call RegisterMovementSpell('U0A4', "barkskin")
        call RegisterMovementSpell('U0A5', "cripple")

        call ConfigureMovementSpellCastSession('U0A1', GetLoadoutMissileMoveCastDuration(), true, 3)
        call ConfigureMovementSpellCastSession('U0A3', GetLoadoutControlMoveCastDuration(), true, 3)
        call ConfigureMovementSpellCastSession('U0A4', GetLoadoutLeapMissileMoveCastDuration(), true, 3)
        call ConfigureMovementSpellCastSession('U0A5', GetLoadoutRocketLauncherMoveCastDuration(), true, 3)
    endfunction

endlibrary
