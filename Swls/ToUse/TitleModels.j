function BMT1 takes nothing returns nothing

    //endlibrary
    // Prefijos / degradados
    local string colWave1 = "|cFFE6E6E6"   // Light Silver
    local string colWave2 = "|cFFC0C0C0"   // Silver
    local string colWave3 = "|cFF8C8C8C"   // Dark Silver
    local string colWave4 = "|cFF707070"   // Darker Silver

    local string colToSpawn1 = "|cFFFFD700" // Gold
    local string colToSpawn2 = "|cFFFFC300"
    local string colToSpawn3 = "|cFFFFA500"
    local string colToSpawn4 = "|cFFFF8C00"

    local string colUnits1 = "|cFFFF6666"   // Red
    local string colUnits2 = "|cFFFF4C4C"
    local string colUnits3 = "|cFFFF3333"
    local string colUnits4 = "|cFFFF1A1A"
    local string colUnits5 = "|cFFCC0000"
    local string colUnits6 = "|cFFB00000"

    local string colBoss1 = "|cFF00FFFF"    // Azure
    local string colBoss2 = "|cFF00E5FF"
    local string colBoss3 = "|cFF00CCFF"
    local string colBoss4 = "|cFF00B2FF"
    local string colBoss5 = "|cFF0099FF"
    local string colBoss6 = "|cFF0080FF"

    local string colToKill1 = "|cFFCC66FF"  // Purple
    local string colToKill2 = "|cFFB24CFF"
    local string colToKill3 = "|cFF9933FF"
    local string colToKill4 = "|cFF7F1AFF"

    local string colOnMap1 = "|cFF66FF99"   // Green
    local string colOnMap2 = "|cFF4DFF88"
    local string colOnMap3 = "|cFF33FF77"
    local string colOnMap4 = "|cFF1AFF66"
    local string colOnMap5 = "|cFF00CC55"

    // Números con color fuerte
    local string colWaveNum = "|cFFE6E6E6"      // blanco para número
    local string colToSpawnNum = "|cFFFFD700"   // dorado fuerte
    local string colUnitsNum = "|cFFFF6666"     // rojo fuerte
    local string colBossNum = "|cFF00CCFF"      // azure fuerte
    local string colToKillNum = "|cFFCC66FF"    // púrpura fuerte
    local string colOnMapNum = "|cFF00FF00"     // verde fuerte

    local string colWaveNum2 = "|cFFC0C0C0"      // blanco para número
    local string colToSpawnNum2 = "|cFFFFD700"   // dorado fuerte
    local string colUnitsNum2 = "|cffff0000"     // rojo fuerte
    local string colBossNum2 = "|cFF0080FF"      // azure fuerte
    local string colToKillNum2 = "|cFF7F1AFF"    // púrpura fuerte
    local string colOnMapNum2 = "|cFF00FF00"     // verde fuerte

    // Separador y colon blanco
    local string sep = " |cFFFFFFFF| |r"
    local string colon = "|cFFFFFFFF: |r"

    // Palabras completas
    local string txtWave = "Wave"
    local string txtToSpawn = "ToSpawn"
    local string txtUnits = "Units"
    local string txtBoss = "Boss"
    local string txtToKill = "ToKill"
    local string txtOnMap = "OnMap"

    // --- Bloques de la línea ---
    local string partWave
    local string partToSpawn
    local string partUnits
    local string partBoss
    local string partToKill
    local string partOnMap

    local Wave w

    

    // --- Variables enteras según la línea final ---

    // Wave
    local integer waveCurrent
    local integer waveTotal

    // ToSpawn (unidades por spawnear / total spawn)
    local integer toSpawnUnit
    local integer totalToSpawn
    local integer toSpawnBoss

    // Units (unidades activas / totales en la wave)
    local integer unitskilled
    local integer units
    local integer totalUnits

    // Boss (boss activos / total bosses)
    local integer bosskilled
    local integer bossActive
    local integer bossTotal

    // ToKill (objetivos restantes / totales)
    local integer toKill
    local integer totalToKill

    // OnMap (unidades visibles actualmente en el mapa)
    local integer onMap


    //local string waveIdd = "8"
    // Ejemplo de línea combinando todo
    local string line

    if CurrentBoardContext == null then
        return
    endif

    set w = WaveByBoard[GetHandleId(CurrentBoardContext)]
        if w == 0 then
            return
        endif

    // Wave
    set waveCurrent = w.waveIndex
    set waveTotal   = w.waveTotal

    // ToSpawn
    set toSpawnUnit     = w.remainingUnits
    set totalToSpawn =  w.remainingUnits + w.remainingBosses
    set toSpawnBoss     = w.remainingBosses 

    // Units
    set unitskilled = w.totalKilledUnits
    set units       = w.activeUnits
    set totalUnits  = w.totalUnits

    // Boss
    set bosskilled  = w.totalKilledBoss
    set bossActive  = w.activeBosses
    set bossTotal   = w.totalBosses

    // ToKill
    set toKill      = w.totalKilled
    set totalToKill = w.totalToSpawn

    // OnMap
    set onMap       = w.activeOnMap

        call MultiboardDisplay(w.board, true)

        // --- Wave ---
        set partWave = colWave1 + "W" + colWave2 + "a" + colWave3 + "v" + colWave4 + "e" + colon + colWaveNum + I2S(waveCurrent) + "|r" + colWave3 + "/" + "|r" + colWave4 + I2S(waveTotal) + "|r"

        // --- ToSpawn ---
        set partToSpawn = colToSpawn1 + "T" + colToSpawn2 + "o" + colToSpawn3 + "S" + colToSpawn4 + "pawn" + colon + colUnitsNum2 + I2S(toSpawnUnit) + "|r"+ colToSpawn1 + "/"  + I2S(totalToSpawn) + "/" + "|r"+ colBossNum2 + I2S(toSpawnBoss) + "|r" 

        // --- Units ---
        set partUnits = colUnits1 + "U" + colUnits2 + "n" + colUnits3 + "i" + colUnits4 + "t" + colUnits5 + "s" + colon + colToKillNum + I2S(unitskilled) + "|r" +colToKill4 +"/" +"|r" +colOnMapNum2 + I2S(units) + "|r" + colUnits2 + "/"+ "|r" + colUnitsNum2 + I2S(totalUnits) + "|r"

        // --- Boss ---
        set partBoss = colBoss1 + "B" + colBoss2 + "o" + colBoss3 + "s" + colBoss4 + "s" + colon + colToKillNum + I2S(bosskilled) + "|r" +colToKill4 +"/" +"|r" +colOnMapNum2 + I2S(bossActive) + "|r" + colBoss4 +"/" +"|r" + colBossNum2 + I2S(bossTotal) + "|r"

        // --- ToKill ---
        set partToKill = colToKill1 + "T" + colToKill2 + "o" + colToKill3 + "K" + colToKill4 + "ill" + colon + colToKillNum + I2S(toKill) + "|r" + colToKill4 +"/" +"|r" + colToKillNum2 + I2S(totalToKill) + "|r"

        // --- OnMap ---
        set partOnMap = colOnMap1 + "O" + colOnMap2 + "n" + colOnMap3 + "M" + colOnMap4 + "a" + colOnMap5 + "p" + colon + colOnMapNum2 + I2S(onMap) + "|r"

        // --- Ensamblar línea final ---
        set line = partWave + sep + partToSpawn + sep + partUnits + sep + partBoss + sep + partToKill + sep + partOnMap

        call MultiboardSetTitleText(w.board,line) 

    endfunction