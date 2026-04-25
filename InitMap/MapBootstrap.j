library MapBootstrap initializer Init requires SelectionSystem, TerrainReplaceConfi

    function Trig_gg_Actions takes nothing returns nothing
        call SelectionSystem.start()

        call TerrainReplaceSetDebug(false)
        call TerrainReplaceSetBatchTilesPerTick(64)
        call ApplyDefaultTerrainReplaceFromCenterAsync(-1536., 24064., 40, 40, 40, 40)
        // Ejemplo:
        // call BJDebugMsg("Tiles cambiados: " + I2S(ApplyDefaultTerrainReplaceRect(gg_rct_Intro_Zone_000)))
    endfunction

    // Compatibilidad con trigger clasico, pero sin gg_trg_gg.
    function InitTrig_gg takes nothing returns nothing
        local trigger t = CreateTrigger()
        call TriggerRegisterTimerEventSingle(t, 1.00)
        call TriggerAddAction(t, function Trig_gg_Actions)
        set t = null
    endfunction

    private function Init takes nothing returns nothing
        call InitTrig_gg()
    endfunction

endlibrary
