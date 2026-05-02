library LoadoutLeapMissile requires WeaponProfileConfig

// Legacy plasma leap missile disabled by Metal Slug weapon rework.
// U0A4 is now Rocket Launcher and is handled by LoadoutMetalSlugSpecial.

function GetLoadoutLeapMissileMoveCastDuration takes nothing returns real
    return WeaponProfileGetCastDuration(WEAPON_PROFILE_ROCKET_LAUNCHER)
endfunction

endlibrary
