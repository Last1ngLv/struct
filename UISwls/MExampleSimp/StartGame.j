library StartGame initializer Init requires UserInterface

    globals
        Camera array PlayerCamera
        unit array PlayerHero
    endglobals
    
    private function Init takes nothing returns nothing
        local integer i = 0
        local integer array urace
        local User user
        
        set urace[1] = 'Hpal'
        set urace[2] = 'Obla'
        set urace[3] = 'Ulic'
        set urace[4] = 'Edem'

        call FogEnable(false)
        call FogMaskEnable(false)
        
        loop
            exitwhen i == User.AmountPlaying
            
            set user = User.fromPlaying(i)
            set PlayerCamera[user.id] = Camera.create()
            
            // create hero
            set PlayerHero[user.id] = CreateUnitAtLoc(user.handle, urace[GetHandleId(GetPlayerRace(user.handle))], GetStartLocationLoc(GetPlayerStartLocation(user.handle)), 180)
            
            //call ShowUnit(PlayerHero[user.id], false)

            // get vision from dummy player
            call SetPlayerAllianceStateBJ(CAMERA_DUMMY_PLAYER, user.handle, bj_ALLIANCE_ALLIED_VISION)
            call SetPlayerAllianceStateBJ(user.handle, CAMERA_DUMMY_PLAYER, bj_ALLIANCE_ALLIED_VISION)
        
            if (User.Local == user.handle) then
                call ClearSelection()
                call SelectUnit(PlayerHero[user.id], true)
            endif
            
            set i = i + 1
        endloop
    endfunction

endlibrary