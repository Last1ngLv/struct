
library stage1 initializer InitStage1 requires PlayerUtils, WaveTest, HeroLives, AIProfiles, AIConfig, IAManager, TenderSystem, PreConfi, WavePointGroupsConfig, PlayerHeroState, WaveMultiboard

function Trig_w1_Actions takes nothing returns nothing
    local Wave w
    local integer i = 0
    local integer stage1MainPathExpected = 0
    local integer stage1MainPathPoints = 0
    local User u
    local integer currentGold
    
    if GetTenderUnit() != null then
        call SetUnitAnimation(GetTenderUnit(), "Spell")
    endif
    if TargetWave > 1 then
        if SwlsSound != null then
            call StopSound(SwlsSound, true, false)
            set SwlsSound = null
        endif
    endif
    if TargetWave == 1 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 1.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 80
    call SetSoundVolume(SwlsSound,80)
    set Message = "Ahora siendo cannon por aqui jeje, asi que un saludo mio y mi creador Leforyer por cierto tienes un apartado especial para que este pendiende de lo que viene en la sig Wave"
    elseif TargetWave == 2 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 2.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 60
    call SetSoundVolume(SwlsSound,60)
    set Message = "Se que no es mucho pero ante los fuertes ataque que sufri es lo minimo que puedo dar, pero animos ire mejorando implementaciones a futuro, defiende The Pueblo!!! "
    elseif TargetWave == 3 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 3.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 60
    call SetSoundVolume(SwlsSound,60)
    set Message = "Estas waves se vuelven mas fuertes cada vez, ahora incluso aprendieron habilidades especiales debido a la DevCorruption, Animos adquiere unas mejoras y eliminalos de aqui"
    elseif TargetWave == 4 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 4.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 60
    call SetSoundVolume(SwlsSound,60)
    set Message = "Lamentablemente en este tiempo los heroes encargados de defender el pueblo no lograron, me causa mucha tristeza.. pero ustedes se que lo lograran, animos!!"
    elseif TargetWave == 5 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 5.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 80
    call SetSoundVolume(SwlsSound,80)
    set Message = "Aquella mutacion de las unidades a mas grandes llamado bosses es un monton, hasta potencia mucho su habilidad normal, esto la verda aterra mucho a la vez"
    elseif TargetWave == 6 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 6.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 80
    call SetSoundVolume(SwlsSound,80)
    set Message = "Segun lo que me conto roucky aquella corrupcion que ocurrio en tu mundo se propago por aqui, pero a cambio tambien puedo beneficiarte pronto con mejoras exclusivas de este mundo!!"
    elseif TargetWave == 7 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 7.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 80
    call SetSoundVolume(SwlsSound,80)
    set Message = "Queda poco no te rindas, espero poder anhelar la recuperacion del pueblo, extrano sus lindos momentos cuando todo era armonia aqui"
    elseif TargetWave == 8 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 8.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 90
    call SetSoundVolume(SwlsSound,90)
    set Message = "Segun lo que conton roucky esta corruption conecta varios mundo... no me imagino un ataque aqui con criaturas de diferentes mundo.."
    elseif TargetWave == 9 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 9.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 80
    call SetSoundVolume(SwlsSound,80)
    set Message = "Estamos a un paso de librar esta corrupcion, pondre a disposicion toda la enegia que pueda para mantener equilibrio por aqui"
    elseif TargetWave == 10 then
    set SwlsSound = CreateSound("war3mapImported\\Wave 11.wav", true, false, false, 12700,12700,"")
    call SetSoundPitch(SwlsSound,1.0)
    set SwlsSoundWaveVolume = 80
    call SetSoundVolume(SwlsSound,80)
    set Message = "Llegamos a la final!! derrotando esta wave tendre la energia suficiente para llevarle al enemigo final o poner fin a este desastre (FinalBossAunPorTerminar)"
    else
    endif
    if SwlsSound != null then
        call StartSound(SwlsSound)
    endif
    set isWavez = true
    //call KillSoundWhenDone(SwlsSound)
    set w = Wave.create(30, 15, 0.25, SwlsMultiboard, "BMT1", TargetWave, 10, "Trig_w1_Actions")
    // Escalado por jugador adicional:
    // 100.0 = +100% de la base por jugador extra (equivalente al comportamiento anterior 2*jugadores)
    // 50.0  = +50% de la base por jugador extra
    call w.setAdditionalPerPlayerPercent(100.0)
    // Si el grupo fue cargado desde markers, este bloque reemplaza el manual.
    set stage1MainPathExpected = WavePointGroupCount("Stage1_ThePueblo")
    if stage1MainPathExpected == 0 then
        call BJDebugMsg("Error No Points")
    endif
    set stage1MainPathPoints = WavePointGroupApplyToWave(w, "Stage1_ThePueblo")
    if stage1MainPathPoints < stage1MainPathExpected then
        call BJDebugMsg("Error No Partial Points") 
    endif
    
    
    set i = 0
    loop
        exitwhen i == User.AmountPlaying //static jeje por eso sin variable
        set u = User.fromPlaying(i)
        call AISetTrackedHero(PlayerHero[u.id])
        call w.addNearUnit(PlayerHero[u.id])
        set i = i + 1
    endloop
    // Con heroes registrados, evitamos fallback por group para mapa amplio.
    call AISetUseGroupFallbackNoHeroes(false)
    

    //call w.addSlot('n00B', 10, 2, 2, 4,  50, true, Player(10))
    //call w.addSlot('n00B', 10, 2, 2, 5,  50, true, Player(11)) AI_PROFILE_WAVE1_SPELL
    
    if TargetWave >= 1 then
        call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HPEA, 'hpea', 1, false, 2, 1, 1, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
        //call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HKNI, 'hkni', 2, true, 2, 1, 5, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
        //call w.addSlotExByPlayer('zA04', 1,true, 2, 1, 1, 15, true,Player(11), AI_PROFILE_BOSS, 0, 0, 1.00)
        //call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMPR, 'hmpr', 1, true, 2, 1, 7, -1, false, AI_PROFILE_WAVE7_SPELL, 0, 0, 1.10)
        // Ejemplo spell-profile (requiere que la unidad tenga la habilidad configurada en AIConfig):
        // call w.addSlotExByPlayers('hfoo', 2, true, 2, 1, 1, -1, false, AI_PROFILE_WAVE1_SPELL, 0, 0, 1.00)
        // Boss unico REAL (owner puntual, sin escalar por jugadores activos):
        // call w.addSlotExByPlayer('Ubos', 1, false, 1, 9, 10, -1, true, Player(10), AI_PROFILE_CASTER, 0, 0, 2.00)
        // Miniboss escalable por jugadores activos:
        // call w.addSlotExByPlayers('Umbs', 1, true, 1, 8, 11, -1, true, AI_PROFILE_MELEE, 0, 0, 1.40)

        //call w.addSlotExByPlayer('hpea', 1,false, 2, 1, 1, -1, false,Player(11), AI_PROFILE_MELEE, 0, 0, 1.00)
        //call w.addSlotExByPlayer('hmpr', 2,false, 2, 1, 1, -1, false,Player(11), AI_PROFILE_WAVE7_SPELL, 0, 0, 1.00)
        endif
        if TargetWave >= 2 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMIL, 'hmil', 2, false, 2, 1, 2, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
            if TargetWave == 2 then
                call w.addSlotExByPlayer('zA01', 2,false, 2, 1, 1, 5, true,Player(11), AI_PROFILE_BOSS, 0, 0, 1.00)
            endif
        endif
        if TargetWave >= 3 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HFOO, 'hfoo', 2, false, 2, 1, 3, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
            if TargetWave == 3 then
            call w.addSlotExByPlayer('zA02', 2,false, 2, 1, 1, 10, true,Player(11), AI_PROFILE_BOSS, 0, 0, 1.00)
        endif
            endif
        if TargetWave >= 4 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HRIF, 'hrif', 2, false, 2, 1, 4, -1, false, AI_PROFILE_WAVE4_SPELL, 0, 0, 1.00)
            if TargetWave == 4 then
            call w.addSlotExByPlayer('zA03', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_BOSS, 0, 0, 1.00)
        endif
            endif
        if TargetWave >= 5 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HKNI, 'hkni', 2, true, 2, 1, 5, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
            if TargetWave == 5 then
            call w.addSlotExByPlayer('zA04', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_BOSS, 0, 0, 1.00)
            endif
        endif
        if TargetWave >= 6 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMTM, 'hmtm', 2, true, 2, 1, 6, -1, false, AI_PROFILE_WAVE6_SPELL, 0, 0, 1.00)
            if TargetWave == 6 then
            call w.addSlotExByPlayer('zA05', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_WAVE6_BOSS, 0, 0, 1.00)
            endif
        endif
        if TargetWave >= 7 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMPR, 'hmpr', 2, true, 2, 1, 7, -1, false, AI_PROFILE_WAVE7_SPELL, 0, 0, 1.10)
            if TargetWave == 7 then
            call w.addSlotExByPlayer('zA07', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_WAVE7_BOSS, 0, 0, 1.00)
            endif
        endif
        if TargetWave >= 8 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HSOR, 'hsor', 2, true, 2, 1, 8, -1, false, AI_PROFILE_WAVE8_SPELL, 0, 0, 1.20)
            if TargetWave == 8 then
            call w.addSlotExByPlayer('zA06', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_WAVE8_BOSS, 0, 0, 1.00)
            endif
        endif
        if TargetWave >= 9 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMTT, 'hmtt', 2, true, 2, 1, 9, -1, false, AI_PROFILE_WAVE9_SPELL, 0, 0, 1.00)
            if TargetWave == 9 then
            call w.addSlotExByPlayer('zA08', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_WAVE9_BOSS, 0, 0, 1.00)
            endif
        endif
        if TargetWave >= 10 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HWT3, 'hwt3', 2, true, 2, 1, 10, -1, false, AI_PROFILE_WAVE10_SPELL, 0, 0, 1.00)
            if TargetWave == 10 then
            call w.addSlotExByPlayer('zA09', 2,false, 2, 1, 1, 15, true,Player(11), AI_PROFILE_WAVE10_BOSS, 0, 0, 1.00)
            endif
        endif

    
    call w.start()
    set i = 0
    loop
        exitwhen i == User.AmountPlaying
        set u = User.fromPlaying(i)
        if User.Local == u.handle and PlayerHero[u.id] != null and GetUnitTypeId(PlayerHero[u.id]) != 0 then
            call SelectUnit(PlayerHero[u.id], true)
        endif
        set i = i + 1
    endloop

endfunction

private function InitStage1 takes nothing returns nothing
    if SwlsWaveStartTrigger == null then
        set SwlsWaveStartTrigger = CreateTrigger()
    endif
    call TriggerAddAction(SwlsWaveStartTrigger, function Trig_w1_Actions)
endfunction

//===========================================================================
endlibrary




