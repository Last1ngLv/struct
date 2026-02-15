scope StartGame initializer Init

    globals
        Camera array PlayerCamera
        unit array PlayerHero
    endglobals

    private function StartGame takes nothing returns nothing
        local trigger trig
        local integer i = 0
        local User user
        local Equipment equipment
        local Inventory inv
        local integer array urace
        
        set urace[1] = 'Hpal'
        set urace[2] = 'Obla'
        set urace[3] = 'Ulic'
        set urace[4] = 'Edem'

        loop
            exitwhen i == User.AmountPlaying
            
            set user = User.fromPlaying(i)
            set PlayerCamera[user.id] = Camera.create()
            
            // create hero
            set equipment = equipment.create.evaluate(CreateUnitAtLoc(user.handle, urace[GetHandleId(GetPlayerRace(user.handle))], GetStartLocationLoc(GetPlayerStartLocation(user.handle)), 180))
            
            call UnitAddAbility(equipment.unit, 'A001')
            call UnitAddAbility(equipment.unit, 'A002')
            
            if (User.Local == user.handle) then
                call SelectUnit(equipment.unit, true)
                call PanCameraToTimed(GetUnitX(equipment.unit), GetUnitY(equipment.unit), 0)
            endif
            
            set inv = Inventory.create(equipment.unit)
            
            set PlayerHero[user.id] = equipment.unit
            
            call SetPlayerAllianceStateBJ(Player(bj_PLAYER_NEUTRAL_EXTRA), user.handle, bj_ALLIANCE_ALLIED_VISION)
            call SetPlayerAllianceStateBJ(user.handle, Player(bj_PLAYER_NEUTRAL_EXTRA), bj_ALLIANCE_ALLIED_VISION)
            
            set i = i + 1
        endloop
    endfunction
    
    private function Init takes nothing returns nothing
        call SetSkyModel("Environment\\Sky\\Sky\\SkyLight.mdl")
        call SetFloatGameState(GAME_STATE_TIME_OF_DAY, 22.00)
        call StartGame()
    endfunction

endscope