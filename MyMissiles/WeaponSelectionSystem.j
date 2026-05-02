library WeaponSelectionSystem requires WeaponInventoryCore

// Compatibility layer for older systems that still call the previous
// weapon-selection API. The actual Metal Slug inventory lives in
// WeaponInventoryCore/WeaponInventorySystem.

function PlayerHasWeaponProfile takes player p, integer profileId returns boolean
    return profileId == WEAPON_PROFILE_HANDGUN or WeaponInventoryGetSlotProfile(p, WEAPON_INVENTORY_SLOT_1) == profileId or WeaponInventoryGetSlotProfile(p, WEAPON_INVENTORY_SLOT_2) == profileId
endfunction

function GetPlayerActiveWeaponProfile takes player p returns integer
    return WeaponInventoryGetActiveProfile(p)
endfunction

function SetPlayerActiveWeaponProfile takes player p, integer profileId returns boolean
    if not WeaponProfileIsWeapon(profileId) then
        return false
    endif
    if profileId != WEAPON_PROFILE_HANDGUN and not PlayerHasWeaponProfile(p, profileId) then
        call WeaponInventoryGiveWeapon(p, profileId, WeaponProfileGetDefaultAmmo(profileId))
    endif
    if WeaponInventoryGetSlotProfile(p, WEAPON_INVENTORY_SLOT_1) == profileId then
        return WeaponInventorySetActiveSlot(p, WEAPON_INVENTORY_SLOT_1)
    endif
    if WeaponInventoryGetSlotProfile(p, WEAPON_INVENTORY_SLOT_2) == profileId then
        return WeaponInventorySetActiveSlot(p, WEAPON_INVENTORY_SLOT_2)
    endif
    call WeaponInventoryResetSlotToHandgun(p, WeaponInventoryGetActiveSlot(p))
    return WeaponInventorySetActiveSlot(p, WeaponInventoryGetActiveSlot(p))
endfunction

function UnlockPlayerWeaponProfile takes player p, integer profileId returns boolean
    if profileId == WEAPON_PROFILE_HANDGUN then
        call WeaponInventoryEnsurePlayer(p)
        return true
    endif
    return WeaponInventoryGiveWeapon(p, profileId, WeaponProfileGetDefaultAmmo(profileId))
endfunction

function RefreshPlayerWeaponSelectors takes player p returns nothing
    call WeaponInventoryEnsurePlayer(p)
endfunction

function EnsurePlayerDefaultWeaponProfile takes player p returns nothing
    call WeaponInventoryEnsurePlayer(p)
endfunction

endlibrary
