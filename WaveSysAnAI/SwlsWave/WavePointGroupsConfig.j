library WavePointGroupsConfig initializer Init requires WavePointGroups
//------------------------------------------------------------------------------
// Config inicial de point groups para SwlsWave.
//
// Nota:
//   - El rawcode del marker es configurable. Acá queda un placeholder estable
//     para que el sistema compile y el usuario lo cambie por su marker real.
//   - Si no hay markers en el rect, el grupo queda vacío y StageExample usa
//     fallback manual.
//------------------------------------------------------------------------------
    globals
        private constant integer WPG_MARKER_RAWCODE = 'l00A' // reemplazar por el marker real del mapa
    endglobals

    private function Init takes nothing returns nothing
        call WavePointGroupsSetDebug(false)

        // Grupo representativo para reemplazar bloques de w.addPoint manuales.
        call WavePointGroupRegister("Stage1_ThePueblo", gg_rct_ZoneThePueblo, WPG_MARKER_RAWCODE)
        //call WavePointGroupRegister("Stage1_SidePath", gg_rct_Intro_Zone_001, WPG_MARKER_RAWCODE)
        //call WavePointGroupRegister("Stage1_BossZone", gg_rct_Intro_Zone_002, WPG_MARKER_RAWCODE)

        call WavePointGroupsBuild()
    endfunction
endlibrary
