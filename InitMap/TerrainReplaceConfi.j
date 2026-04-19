library TerrainReplaceConfi requires TerrainReplace

    private function SetupDefaultTerrainReplaceRules takes nothing returns nothing
        call TerrainReplaceClearRules()

        // Base -> Nuevo
        call TerrainReplaceAddRule('Zbkl', 'Xdrt')
        call TerrainReplaceAddRule('Alvd', 'Lgrd')
        call TerrainReplaceAddRule('Agrd', 'Xrtl')
        call TerrainReplaceAddRule('Xbtl', 'Vgrs')
        call TerrainReplaceAddRule('Adrd', 'Xrtl')
        call TerrainReplaceAddRule('cAc2', 'Xblm')

        // Sin cambio / ignorados:
        // Zdrt, Adrd, Avin, Adrg, Yhdg
    endfunction

    function ApplyDefaultTerrainReplaceRect takes rect r returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceApplyRect(r)
    endfunction

    function ApplyDefaultTerrainReplaceRectAsync takes rect r returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceStartRect(r)
    endfunction

    function ApplyDefaultTerrainReplaceDebugRect takes rect r returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceDebugApplyRect(r)
    endfunction

    function ApplyDefaultTerrainReplaceDebugRectAsync takes rect r returns integer
        call SetupDefaultTerrainReplaceRules()
        call TerrainReplaceSetDebug(true)
        return TerrainReplaceStartRect(r)
    endfunction

    function ApplyDefaultTerrainReplaceBounds takes real minX, real minY, real maxX, real maxY returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceApplyBounds(minX, minY, maxX, maxY)
    endfunction

    function ApplyDefaultTerrainReplaceBoundsAsync takes real minX, real minY, real maxX, real maxY returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceStartBounds(minX, minY, maxX, maxY)
    endfunction

    function ApplyDefaultTerrainReplaceDebugBounds takes real minX, real minY, real maxX, real maxY returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceDebugApplyBounds(minX, minY, maxX, maxY)
    endfunction

    function ApplyDefaultTerrainReplaceDebugBoundsAsync takes real minX, real minY, real maxX, real maxY returns integer
        call SetupDefaultTerrainReplaceRules()
        call TerrainReplaceSetDebug(true)
        return TerrainReplaceStartBounds(minX, minY, maxX, maxY)
    endfunction

    function ApplyDefaultTerrainReplaceFromCenter takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceApplyFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
    endfunction

    function ApplyDefaultTerrainReplaceFromCenterAsync takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceStartFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
    endfunction

    function ApplyDefaultTerrainReplaceDebugFromCenter takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        call SetupDefaultTerrainReplaceRules()
        return TerrainReplaceDebugApplyFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
    endfunction

    function ApplyDefaultTerrainReplaceDebugFromCenterAsync takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        call SetupDefaultTerrainReplaceRules()
        call TerrainReplaceSetDebug(true)
        return TerrainReplaceStartFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
    endfunction

endlibrary

/*
1516399468 -> 'Zbkl'

1516532340 -> 'Zdrt'

1665229618 -> 'cAc2'

1097101924 -> 'Adrd'

1098279278 -> 'Avin'

1097627236 -> 'Alvd'

1097298532 -> 'Agrd'

1097101927 -> 'Adrg'

1482847340 -> 'Xbtl'

1500013671 -> 'Yhdg'


1482845293 -> 'Xblm'

1281847908 -> 'Lgrd'

1449620083 -> 'Vgrs'

1482977908 -> 'Xdrt'

1483895916 -> 'Xrtl'

*/ 
