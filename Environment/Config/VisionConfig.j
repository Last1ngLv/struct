library VisionConfi initializer Init

    private function ApplyVisionConfig takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= 12
            call FogModifierStart(CreateFogModifierRadius(Player(i), FOG_OF_WAR_VISIBLE, -1536., 24064., 5000, false, true))
            call CreateFogModifierRectBJ(true, Player(i), FOG_OF_WAR_MASKED, GetPlayableMapRect()) 
            set i = i + 1
        endloop

        // Crear un FogModifierRectBJ para el primer jugador (ejemplo)
        call FogEnable(false)
        call FogMaskEnable(true)

        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_Center_000)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_000)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_001)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_002)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_003)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_000)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_001)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_002)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_003)

        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_Center_000)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_000)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_001)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_002)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_L_003)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_000)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_001)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_002)
        call CreateFogModifierRectBJ(true, Player(11), FOG_OF_WAR_VISIBLE, gg_rct_Escenary_R_003)

        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Intro_Zone_000)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Intro_Zone_001)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Intro_Zone_002)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Intro_Zone_003)
        call CreateFogModifierRectBJ(true, Player(0), FOG_OF_WAR_VISIBLE, gg_rct_Intro_Zone_004)

        call SetTimeOfDay(12)
        call UseTimeOfDayBJ(false)
        call VolumeGroupSetVolumeBJ(SOUND_VOLUMEGROUP_MUSIC, 0.00)


    endfunction

    // Compatibilidad con detonador clásico (si alguien todavía llama esta función).
    function Trig_Event_Actions takes nothing returns nothing
        call ApplyVisionConfig()
    endfunction

    // Compatibilidad con InitTrig_... sin depender de gg_trg_Event.
    function InitTrig_Event takes nothing returns nothing
        local trigger t = CreateTrigger()
        call TriggerRegisterTimerEventSingle(t, 0.00)
        call TriggerAddAction(t, function Trig_Event_Actions)
        set t = null
    endfunction

    private function Init takes nothing returns nothing
        call InitTrig_Event()
    endfunction

endlibrary

