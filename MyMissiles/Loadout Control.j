library LoadoutControl requires WeaponProfileConfig

// Legacy shotgun/pellet loadout disabled by Metal Slug weapon rework.
// U0A3 is now handled by LoadoutMetalSlugSpecial as a piercing AoE Shotgun blast.

function GetLoadoutControlMoveCastDuration takes nothing returns real
    return WeaponProfileGetCastDuration(WEAPON_PROFILE_SHOTGUN)
endfunction

endlibrary
