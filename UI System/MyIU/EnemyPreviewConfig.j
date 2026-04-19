library EnemyPreviewConfig initializer Init
    
globals
    private constant integer ENEMY_PREVIEW_MAX_WAVES = 10
    private string array EnemyPreviewModelPath
    private real array EnemyPreviewModelScale
    private string array EnemyPreviewText
endglobals

    private function ClampEnemyPreviewWave takes integer waveId returns integer
        if waveId < 1 then
            return 1
        endif
        if waveId > ENEMY_PREVIEW_MAX_WAVES then
            return ENEMY_PREVIEW_MAX_WAVES
        endif
        return waveId
    endfunction

    function EnemyPreviewSetModelPath takes integer waveId, string path returns nothing
        set waveId = ClampEnemyPreviewWave(waveId)
        if path == null then
            set path = ""
        endif
        set EnemyPreviewModelPath[waveId] = path
    endfunction

    function EnemyPreviewGetModelPath takes integer waveId returns string
        set waveId = ClampEnemyPreviewWave(waveId)
        if EnemyPreviewModelPath[waveId] == null then
            return ""
        endif
        return EnemyPreviewModelPath[waveId]
    endfunction

    function EnemyPreviewSetModelScale takes integer waveId, real scale returns nothing
        set waveId = ClampEnemyPreviewWave(waveId)
        if scale <= 0.0 then
            set scale = 1.00
        endif
        set EnemyPreviewModelScale[waveId] = scale
    endfunction

    function EnemyPreviewGetModelScale takes integer waveId returns real
        set waveId = ClampEnemyPreviewWave(waveId)
        if EnemyPreviewModelScale[waveId] <= 0.0 then
            return 1.00
        endif
        return EnemyPreviewModelScale[waveId]
    endfunction

    function EnemyPreviewSetModel takes integer waveId, string path, real scale returns nothing
        call EnemyPreviewSetModelPath(waveId, path)
        call EnemyPreviewSetModelScale(waveId, scale)
    endfunction

    function EnemyPreviewSetText takes integer waveId, string text returns nothing
        set waveId = ClampEnemyPreviewWave(waveId)
        if text == null then
            set text = ""
        endif
        set EnemyPreviewText[waveId] = text
    endfunction

    function EnemyPreviewGetText takes integer waveId returns string
        set waveId = ClampEnemyPreviewWave(waveId)
        if EnemyPreviewText[waveId] == null or EnemyPreviewText[waveId] == "" then
            return "Enemy info\nNo preview yet"
        endif
        return EnemyPreviewText[waveId]
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 1

        loop
            exitwhen i > ENEMY_PREVIEW_MAX_WAVES
            set EnemyPreviewModelPath[i] = ""
            set EnemyPreviewModelScale[i] = 0.12
            set i = i + 1
        endloop

        set EnemyPreviewModelPath[1] = "units\\human\\Peasant\\Peasant.mdl"
        set EnemyPreviewModelPath[2] = "units\\human\\Militia\\Militia.mdl"
        set EnemyPreviewModelPath[3] = "units\\human\\Footman\\Footman.mdl"
        set EnemyPreviewModelPath[4] = "units\\human\\Rifleman\\Rifleman.mdl"
        set EnemyPreviewModelPath[5] = "units\\human\\Knight\\Knight.mdl"
        set EnemyPreviewModelPath[6] = "units\\human\\MortarTeam\\MortarTeam.mdl"
        set EnemyPreviewModelPath[7] = "units\\human\\Priest\\Priest.mdl"
        set EnemyPreviewModelPath[8] = "units\\human\\Sorceress\\Sorceress.mdl"
        set EnemyPreviewModelPath[9] = "units\\human\\SteamTank\\SteamTank.mdl"
        set EnemyPreviewModelPath[10] = "units\\human\\WaterElemental\\WaterElemental.mdl"

        set EnemyPreviewText[1] = "Wave 1\nPeones cuerpo a cuerpo\nPresion basica para abrir la partida\nSin mecanica especial"

        set EnemyPreviewText[2] = "Wave 2\nMilicia cuerpo a cuerpo sin skill activa\nEmpuja por cantidad y presion frontal\nBoss tambien pelea sin especial"

        set EnemyPreviewText[3] = "Wave 3\nSoldado levanta barrera en area\nBloquea proyectiles y altera interacciones\nBoss cubre una zona mucho mayor"

        set EnemyPreviewText[4] = "Wave 4\nFusilero marca el punto y dispara exacto\nMantiene mucha distancia del jugador\nBoss entra en rafaga de misiles"

        set EnemyPreviewText[5] = "Wave 5\nCaballero da aura de fase en area\nAliados atraviesan mejor el combate\nBoss amplifica radio y duracion"

        set EnemyPreviewText[6] = "Wave 6\nMortero bombardea desde muy lejos\nEl indicador queda hasta el impacto\nBoss dispara rafagas a cada jugador"

        set EnemyPreviewText[7] = "Wave 7\nSacerdote bendice aliados cercanos\nDa vida extra y aumenta la escala\nBoss aplica una bendicion mas fuerte"

        set EnemyPreviewText[8] = "Wave 8\nHechicera prepara una trampa de escudo\nSi te toca o entras en el area te aturde\nBoss deja una zona enorme y duradera"

        set EnemyPreviewText[9] = "Wave 9\nMaquina de asedio crea zona nuclear\nPermanece 10s y da dano por tick\nBoss cubre un radio gigantesco"

        set EnemyPreviewText[10] = "Wave 10\nElemental se lanza como una ola viva\nDaña durante el recorrido y al impactar\nBoss golpea con un radio mayor"
    endfunction

endlibrary
