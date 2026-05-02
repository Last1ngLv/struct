library PreConfi initializer Init requires GameState, InitialWaveMultiboard, AudioPreloadConfig, WaveOwnerConfig, AllianceConfig, InitialGoldConfig, MovementSpellTargetConfig, TenderSpawnConfig, MenuClientInitConfig

    function InitTrig_Vars takes nothing returns nothing
        call GameStateInitDefaults()
        call InitInitialWaveMultiboard()
        call InitTenderSpawnConfig()
        call PreloadMapResources()
        call InitDefaultWaveOwnerResearches()
        call InitHostileNeutralAlliances()
        call InitInitialPlayerGold()
        call InitMovementSpellTargetConfig()
        call EnablePreSelect(true, false)
        call InitPlayerBountyStates()
        call InitMenuClientDefaults()
    endfunction

    private function Init takes nothing returns nothing
        call InitTrig_Vars()
    endfunction

endlibrary
