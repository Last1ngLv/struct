library TerrainReplace requires TimerUtils /*
    TerrainReplace
    --------------
    Reemplaza tiles de terreno dentro de un area recorriendo tile por tile.

    Notas:
    - 1 tile = 128x128 unidades.
    - Usa hasta 10 reglas base->destino.
    - Recorre el area por centros de tile.
    - La primera regla activa que coincida gana.

    API rapida:
    - call TerrainReplaceClearRules()
    - call TerrainReplaceAddRule('Ldrt', 'Ldro')
    - call TerrainReplaceSetRuleVariation(1, -1)
    - call TerrainReplaceSetDebug(true) // muestra debug automatico al aplicar
    - call TerrainReplaceApplyBounds(minX, minY, maxX, maxY)
    - call TerrainReplaceApplyFromCenter(cx, cy, left, right, up, down)
    - call TerrainReplaceApplyRect(r)
    - call TerrainReplaceStartBounds(minX, minY, maxX, maxY) // batch con timer
    - call TerrainReplaceStartFromCenter(cx, cy, left, right, up, down)
    - call TerrainReplaceSetBatchTilesPerTick(128)

    Center mode:
    - centerX/centerY se alinean al tile que contiene ese punto.
    - left/right/up/down son cantidades de tiles desde ese tile central.
    - ejemplo: left=2 right=1 up=3 down=3 => 4 tiles de ancho x 7 de alto.
*/
    globals
        constant integer TERRAIN_REPLACE_MAX_RULES = 10
        constant real TERRAIN_REPLACE_TILE_SIZE = 128.0

        private integer TerrainReplaceRuleCount = 0
        private integer array TerrainReplaceBaseTile
        private integer array TerrainReplaceNewTile
        private integer array TerrainReplaceVariation
        private boolean array TerrainReplaceEnabled

        private boolean TerrainReplaceDebugEnabled = false
        private integer TerrainReplaceDebugVisitedTiles = 0
        private integer TerrainReplaceDebugChangedTiles = 0
        private integer array TerrainReplaceDebugRuleHits

        private integer TerrainReplaceBatchTilesPerTick = 128
        private real TerrainReplaceBatchTickSec = 0.03125
        private timer TerrainReplaceBatchTimer = null
        private boolean TerrainReplaceBatchRunning = false
        private integer TerrainReplaceBatchExpectedTiles = 0
        private integer TerrainReplaceBatchMinTileX = 0
        private integer TerrainReplaceBatchMaxTileX = 0
        private integer TerrainReplaceBatchMinTileY = 0
        private integer TerrainReplaceBatchMaxTileY = 0
        private integer TerrainReplaceBatchCurrentTileX = 0
        private integer TerrainReplaceBatchCurrentTileY = 0
        private string TerrainReplaceBatchLabel = "TerrainReplace"
    endglobals

    function TerrainReplaceGetTileSize takes nothing returns real
        return TERRAIN_REPLACE_TILE_SIZE
    endfunction

    function TerrainReplaceGetMaxRules takes nothing returns integer
        return TERRAIN_REPLACE_MAX_RULES
    endfunction

    private function TerrainReplaceFloorTileIndex takes real coord returns integer
        local real q = coord / TERRAIN_REPLACE_TILE_SIZE
        local integer i = R2I(q)
        if q < I2R(i) then
            set i = i - 1
        endif
        return i
    endfunction

    private function TerrainReplaceNormalizeMinIndex takes real minCoord, real maxCoord returns integer
        if minCoord <= maxCoord then
            return TerrainReplaceFloorTileIndex(minCoord)
        endif
        return TerrainReplaceFloorTileIndex(maxCoord)
    endfunction

    private function TerrainReplaceNormalizeMaxIndex takes real minCoord, real maxCoord returns integer
        local real hi
        local real lo
        if minCoord <= maxCoord then
            set lo = minCoord
            set hi = maxCoord
        else
            set lo = maxCoord
            set hi = minCoord
        endif
        if hi <= lo then
            return TerrainReplaceFloorTileIndex(lo)
        endif
        return TerrainReplaceFloorTileIndex(hi - 0.01)
    endfunction

    private function TerrainReplaceTileCenter takes integer tileIndex returns real
        return I2R(tileIndex) * TERRAIN_REPLACE_TILE_SIZE + TERRAIN_REPLACE_TILE_SIZE * 0.5
    endfunction

    private function TerrainReplaceGetWorldMinTileX takes nothing returns integer
        return TerrainReplaceFloorTileIndex(GetRectMinX(GetWorldBounds()))
    endfunction

    private function TerrainReplaceGetWorldMaxTileX takes nothing returns integer
        return TerrainReplaceFloorTileIndex(GetRectMaxX(GetWorldBounds()) - 0.01)
    endfunction

    private function TerrainReplaceGetWorldMinTileY takes nothing returns integer
        return TerrainReplaceFloorTileIndex(GetRectMinY(GetWorldBounds()))
    endfunction

    private function TerrainReplaceGetWorldMaxTileY takes nothing returns integer
        return TerrainReplaceFloorTileIndex(GetRectMaxY(GetWorldBounds()) - 0.01)
    endfunction

    private function TerrainReplaceClampTileRangeToWorld takes integer minTileX, integer maxTileX, integer minTileY, integer maxTileY returns nothing
        local integer worldMinTileX = TerrainReplaceGetWorldMinTileX()
        local integer worldMaxTileX = TerrainReplaceGetWorldMaxTileX()
        local integer worldMinTileY = TerrainReplaceGetWorldMinTileY()
        local integer worldMaxTileY = TerrainReplaceGetWorldMaxTileY()

        if minTileX < worldMinTileX then
            set minTileX = worldMinTileX
        endif
        if maxTileX > worldMaxTileX then
            set maxTileX = worldMaxTileX
        endif
        if minTileY < worldMinTileY then
            set minTileY = worldMinTileY
        endif
        if maxTileY > worldMaxTileY then
            set maxTileY = worldMaxTileY
        endif
    endfunction

    private function TerrainReplaceClampNonNegative takes integer v returns integer
        if v < 0 then
            return 0
        endif
        return v
    endfunction

    function TerrainReplaceSetBatchTilesPerTick takes integer value returns nothing
        if value < 1 then
            set value = 1
        endif
        set TerrainReplaceBatchTilesPerTick = value
    endfunction

    function TerrainReplaceGetBatchTilesPerTick takes nothing returns integer
        return TerrainReplaceBatchTilesPerTick
    endfunction

    function TerrainReplaceSetBatchTickSec takes real value returns nothing
        if value <= 0. then
            set value = 0.03125
        endif
        set TerrainReplaceBatchTickSec = value
    endfunction

    function TerrainReplaceGetBatchTickSec takes nothing returns real
        return TerrainReplaceBatchTickSec
    endfunction

    function TerrainReplaceIsBatchRunning takes nothing returns boolean
        return TerrainReplaceBatchRunning
    endfunction

    function TerrainReplaceStopBatch takes nothing returns nothing
        local timer t = TerrainReplaceBatchTimer
        if not TerrainReplaceBatchRunning and t == null then
            return
        endif
        set TerrainReplaceBatchRunning = false
        set TerrainReplaceBatchExpectedTiles = 0
        set TerrainReplaceBatchMinTileX = 0
        set TerrainReplaceBatchMaxTileX = 0
        set TerrainReplaceBatchMinTileY = 0
        set TerrainReplaceBatchMaxTileY = 0
        set TerrainReplaceBatchCurrentTileX = 0
        set TerrainReplaceBatchCurrentTileY = 0
        set TerrainReplaceBatchLabel = "TerrainReplace"
        set TerrainReplaceBatchTimer = null
        if t != null then
            call ReleaseTimer(t)
        endif
        set t = null
    endfunction

    private function TerrainReplaceIsValidSlot takes integer slot returns boolean
        return slot >= 1 and slot <= TERRAIN_REPLACE_MAX_RULES
    endfunction

    function TerrainReplaceClearRules takes nothing returns nothing
        local integer i = 1
        set TerrainReplaceRuleCount = 0
        loop
            exitwhen i > TERRAIN_REPLACE_MAX_RULES
            set TerrainReplaceBaseTile[i] = 0
            set TerrainReplaceNewTile[i] = 0
            set TerrainReplaceVariation[i] = -1
            set TerrainReplaceEnabled[i] = false
            set i = i + 1
        endloop
    endfunction

    function TerrainReplaceDisableRule takes integer slot returns nothing
        if not TerrainReplaceIsValidSlot(slot) then
            return
        endif
        set TerrainReplaceEnabled[slot] = false
    endfunction

    function TerrainReplaceSetRuleEx takes integer slot, integer baseTile, integer newTile, integer variation returns nothing
        if not TerrainReplaceIsValidSlot(slot) then
            return
        endif
        if baseTile == 0 or newTile == 0 then
            set TerrainReplaceEnabled[slot] = false
            return
        endif
        set TerrainReplaceBaseTile[slot] = baseTile
        set TerrainReplaceNewTile[slot] = newTile
        set TerrainReplaceVariation[slot] = variation
        set TerrainReplaceEnabled[slot] = true
        if slot > TerrainReplaceRuleCount then
            set TerrainReplaceRuleCount = slot
        endif
    endfunction

    function TerrainReplaceSetRule takes integer slot, integer baseTile, integer newTile returns nothing
        call TerrainReplaceSetRuleEx(slot, baseTile, newTile, -1)
    endfunction

    function TerrainReplaceSetRuleVariation takes integer slot, integer variation returns nothing
        if not TerrainReplaceIsValidSlot(slot) then
            return
        endif
        set TerrainReplaceVariation[slot] = variation
    endfunction

    function TerrainReplaceAddRuleEx takes integer baseTile, integer newTile, integer variation returns integer
        local integer slot = 1
        loop
            exitwhen slot > TERRAIN_REPLACE_MAX_RULES
            if not TerrainReplaceEnabled[slot] then
                call TerrainReplaceSetRuleEx(slot, baseTile, newTile, variation)
                return slot
            endif
            set slot = slot + 1
        endloop
        return 0
    endfunction

    function TerrainReplaceAddRule takes integer baseTile, integer newTile returns integer
        return TerrainReplaceAddRuleEx(baseTile, newTile, -1)
    endfunction

    function TerrainReplaceGetRuleCount takes nothing returns integer
        return TerrainReplaceRuleCount
    endfunction

    function TerrainReplaceSetDebug takes boolean enabled returns nothing
        set TerrainReplaceDebugEnabled = enabled
    endfunction

    function TerrainReplaceClearDebugStats takes nothing returns nothing
        local integer i = 1
        set TerrainReplaceDebugVisitedTiles = 0
        set TerrainReplaceDebugChangedTiles = 0
        loop
            exitwhen i > TERRAIN_REPLACE_MAX_RULES
            set TerrainReplaceDebugRuleHits[i] = 0
            set i = i + 1
        endloop
    endfunction

    function TerrainReplaceGetDebugVisitedTiles takes nothing returns integer
        return TerrainReplaceDebugVisitedTiles
    endfunction

    function TerrainReplaceGetDebugChangedTiles takes nothing returns integer
        return TerrainReplaceDebugChangedTiles
    endfunction

    function TerrainReplaceGetDebugRuleHits takes integer slot returns integer
        if not TerrainReplaceIsValidSlot(slot) then
            return 0
        endif
        return TerrainReplaceDebugRuleHits[slot]
    endfunction

    function TerrainReplaceDebugDump takes string label returns nothing
        local integer i = 1
        if label == null or label == "" then
            set label = "TerrainReplace"
        endif
        call BJDebugMsg("[" + label + "] visited=" + I2S(TerrainReplaceDebugVisitedTiles) + " changed=" + I2S(TerrainReplaceDebugChangedTiles) + " rules=" + I2S(TerrainReplaceRuleCount))
        loop
            exitwhen i > TerrainReplaceRuleCount
            if TerrainReplaceEnabled[i] then
                call BJDebugMsg("[" + label + "] rule#" + I2S(i) + " base=" + I2S(TerrainReplaceBaseTile[i]) + " new=" + I2S(TerrainReplaceNewTile[i]) + " hits=" + I2S(TerrainReplaceDebugRuleHits[i]))
            endif
            set i = i + 1
        endloop
    endfunction

    function TerrainReplaceCountTilesBounds takes real minX, real minY, real maxX, real maxY returns integer
        local integer minTileX = TerrainReplaceNormalizeMinIndex(minX, maxX)
        local integer maxTileX = TerrainReplaceNormalizeMaxIndex(minX, maxX)
        local integer minTileY = TerrainReplaceNormalizeMinIndex(minY, maxY)
        local integer maxTileY = TerrainReplaceNormalizeMaxIndex(minY, maxY)
        local integer worldMinTileX = TerrainReplaceGetWorldMinTileX()
        local integer worldMaxTileX = TerrainReplaceGetWorldMaxTileX()
        local integer worldMinTileY = TerrainReplaceGetWorldMinTileY()
        local integer worldMaxTileY = TerrainReplaceGetWorldMaxTileY()
        local integer width = maxTileX - minTileX + 1
        local integer height = maxTileY - minTileY + 1

        if minTileX < worldMinTileX then
            set minTileX = worldMinTileX
        endif
        if maxTileX > worldMaxTileX then
            set maxTileX = worldMaxTileX
        endif
        if minTileY < worldMinTileY then
            set minTileY = worldMinTileY
        endif
        if maxTileY > worldMaxTileY then
            set maxTileY = worldMaxTileY
        endif

        set width = maxTileX - minTileX + 1
        set height = maxTileY - minTileY + 1
        if width < 0 then
            set width = 0
        endif
        if height < 0 then
            set height = 0
        endif
        return width * height
    endfunction

    function TerrainReplaceCountTilesFromCenter takes integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        local integer width
        local integer height
        set leftTiles = TerrainReplaceClampNonNegative(leftTiles)
        set rightTiles = TerrainReplaceClampNonNegative(rightTiles)
        set upTiles = TerrainReplaceClampNonNegative(upTiles)
        set downTiles = TerrainReplaceClampNonNegative(downTiles)
        set width = leftTiles + rightTiles + 1
        set height = upTiles + downTiles + 1
        if width < 1 then
            set width = 1
        endif
        if height < 1 then
            set height = 1
        endif
        return width * height
    endfunction

    private function TerrainReplaceApplyAtTile takes real x, real y returns boolean
        local integer currentTile
        local integer slot = 1
        if TerrainReplaceRuleCount <= 0 then
            return false
        endif
        if TerrainReplaceDebugEnabled then
            set TerrainReplaceDebugVisitedTiles = TerrainReplaceDebugVisitedTiles + 1
        endif
        set currentTile = GetTerrainType(x, y)
        loop
            exitwhen slot > TerrainReplaceRuleCount
            if TerrainReplaceEnabled[slot] and currentTile == TerrainReplaceBaseTile[slot] then
                call SetTerrainType(x, y, TerrainReplaceNewTile[slot], TerrainReplaceVariation[slot], 1, 0)
                if TerrainReplaceDebugEnabled then
                    set TerrainReplaceDebugChangedTiles = TerrainReplaceDebugChangedTiles + 1
                    set TerrainReplaceDebugRuleHits[slot] = TerrainReplaceDebugRuleHits[slot] + 1
                endif
                return true
            endif
            set slot = slot + 1
        endloop
        return false
    endfunction

    private function TerrainReplaceApplyTileRange takes integer minTileX, integer maxTileX, integer minTileY, integer maxTileY returns integer
        local integer tileX = minTileX
        local integer tileY
        local integer changed = 0
        local real x
        local real y

        if TerrainReplaceRuleCount <= 0 then
            return 0
        endif

        loop
            exitwhen tileX > maxTileX
            set x = TerrainReplaceTileCenter(tileX)
            set tileY = minTileY
            loop
                exitwhen tileY > maxTileY
                set y = TerrainReplaceTileCenter(tileY)
                if TerrainReplaceApplyAtTile(x, y) then
                    set changed = changed + 1
                endif
                set tileY = tileY + 1
            endloop
            set tileX = tileX + 1
        endloop

        return changed
    endfunction

    function TerrainReplaceApplyBounds takes real minX, real minY, real maxX, real maxY returns integer
        local integer minTileX = TerrainReplaceNormalizeMinIndex(minX, maxX)
        local integer maxTileX = TerrainReplaceNormalizeMaxIndex(minX, maxX)
        local integer minTileY = TerrainReplaceNormalizeMinIndex(minY, maxY)
        local integer maxTileY = TerrainReplaceNormalizeMaxIndex(minY, maxY)
        local integer origMinTileX = minTileX
        local integer origMaxTileX = maxTileX
        local integer origMinTileY = minTileY
        local integer origMaxTileY = maxTileY
        local integer worldMinTileX = TerrainReplaceGetWorldMinTileX()
        local integer worldMaxTileX = TerrainReplaceGetWorldMaxTileX()
        local integer worldMinTileY = TerrainReplaceGetWorldMinTileY()
        local integer worldMaxTileY = TerrainReplaceGetWorldMaxTileY()
        local integer changed
        local integer expectedTiles

        if minTileX < worldMinTileX then
            set minTileX = worldMinTileX
        endif
        if maxTileX > worldMaxTileX then
            set maxTileX = worldMaxTileX
        endif
        if minTileY < worldMinTileY then
            set minTileY = worldMinTileY
        endif
        if maxTileY > worldMaxTileY then
            set maxTileY = worldMaxTileY
        endif

        if TerrainReplaceDebugEnabled and (origMinTileX != minTileX or origMaxTileX != maxTileX or origMinTileY != minTileY or origMaxTileY != maxTileY) then
            call BJDebugMsg("[TerrainReplace] bounds clamped to world: x[" + I2S(minTileX) + "," + I2S(maxTileX) + "] y[" + I2S(minTileY) + "," + I2S(maxTileY) + "]")
        endif

        if TerrainReplaceDebugEnabled then
            call TerrainReplaceClearDebugStats()
            call BJDebugMsg("[TerrainReplace] begin bounds x[" + R2S(minX) + "," + R2S(maxX) + "] y[" + R2S(minY) + "," + R2S(maxY) + "] tiles=" + I2S((maxTileX - minTileX + 1) * (maxTileY - minTileY + 1)))
        endif
        set changed = TerrainReplaceApplyTileRange(minTileX, maxTileX, minTileY, maxTileY)
        if TerrainReplaceDebugEnabled then
            set expectedTiles = TerrainReplaceCountTilesBounds(minX, minY, maxX, maxY)
            call BJDebugMsg("[TerrainReplace] expectedTiles=" + I2S(expectedTiles) + " visited=" + I2S(TerrainReplaceDebugVisitedTiles) + " changed=" + I2S(TerrainReplaceDebugChangedTiles) + " return=" + I2S(changed))
            call TerrainReplaceDebugDump("TerrainReplace")
        endif
        return changed
    endfunction

    function TerrainReplaceApplyFromCenter takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        local integer centerTileX = TerrainReplaceFloorTileIndex(centerX)
        local integer centerTileY = TerrainReplaceFloorTileIndex(centerY)
        local integer minTileX
        local integer maxTileX
        local integer minTileY
        local integer maxTileY
        local integer origMinTileX
        local integer origMaxTileX
        local integer origMinTileY
        local integer origMaxTileY
        local integer worldMinTileX = TerrainReplaceGetWorldMinTileX()
        local integer worldMaxTileX = TerrainReplaceGetWorldMaxTileX()
        local integer worldMinTileY = TerrainReplaceGetWorldMinTileY()
        local integer worldMaxTileY = TerrainReplaceGetWorldMaxTileY()
        local integer changed

        set leftTiles = TerrainReplaceClampNonNegative(leftTiles)
        set rightTiles = TerrainReplaceClampNonNegative(rightTiles)
        set upTiles = TerrainReplaceClampNonNegative(upTiles)
        set downTiles = TerrainReplaceClampNonNegative(downTiles)

        set minTileX = centerTileX - leftTiles
        set maxTileX = centerTileX + rightTiles
        set minTileY = centerTileY - downTiles
        set maxTileY = centerTileY + upTiles
        set origMinTileX = minTileX
        set origMaxTileX = maxTileX
        set origMinTileY = minTileY
        set origMaxTileY = maxTileY

        if minTileX < worldMinTileX then
            set minTileX = worldMinTileX
        endif
        if maxTileX > worldMaxTileX then
            set maxTileX = worldMaxTileX
        endif
        if minTileY < worldMinTileY then
            set minTileY = worldMinTileY
        endif
        if maxTileY > worldMaxTileY then
            set maxTileY = worldMaxTileY
        endif

        if TerrainReplaceDebugEnabled and (origMinTileX != minTileX or origMaxTileX != maxTileX or origMinTileY != minTileY or origMaxTileY != maxTileY) then
            call BJDebugMsg("[TerrainReplace] center clamped to world: x[" + I2S(minTileX) + "," + I2S(maxTileX) + "] y[" + I2S(minTileY) + "," + I2S(maxTileY) + "]")
        endif

        if TerrainReplaceDebugEnabled then
            call TerrainReplaceClearDebugStats()
            call BJDebugMsg("[TerrainReplace] begin center=(" + R2S(centerX) + "," + R2S(centerY) + ") tiles=" + I2S((maxTileX - minTileX + 1) * (maxTileY - minTileY + 1)) + " left=" + I2S(leftTiles) + " right=" + I2S(rightTiles) + " up=" + I2S(upTiles) + " down=" + I2S(downTiles))
        endif
        set changed = TerrainReplaceApplyTileRange(minTileX, maxTileX, minTileY, maxTileY)
        if TerrainReplaceDebugEnabled then
            call BJDebugMsg("[TerrainReplace] center=(" + R2S(centerX) + "," + R2S(centerY) + ") expectedTiles=" + I2S(TerrainReplaceCountTilesFromCenter(leftTiles, rightTiles, upTiles, downTiles)) + " visited=" + I2S(TerrainReplaceDebugVisitedTiles) + " changed=" + I2S(TerrainReplaceDebugChangedTiles) + " return=" + I2S(changed))
            call TerrainReplaceDebugDump("TerrainReplaceCenter")
        endif
        return changed
    endfunction

    private function TerrainReplaceBatchFinish takes nothing returns nothing
        local timer t = TerrainReplaceBatchTimer
        local integer expectedTiles = TerrainReplaceBatchExpectedTiles
        set TerrainReplaceBatchTimer = null
        set TerrainReplaceBatchRunning = false
        set TerrainReplaceBatchExpectedTiles = 0
        set TerrainReplaceBatchMinTileX = 0
        set TerrainReplaceBatchMaxTileX = 0
        set TerrainReplaceBatchMinTileY = 0
        set TerrainReplaceBatchMaxTileY = 0
        set TerrainReplaceBatchCurrentTileX = 0
        set TerrainReplaceBatchCurrentTileY = 0
        if t != null then
            call ReleaseTimer(t)
        endif
        set t = null
        if TerrainReplaceDebugEnabled then
            call BJDebugMsg("[TerrainReplace] async finished label=" + TerrainReplaceBatchLabel + " expectedTiles=" + I2S(expectedTiles) + " visited=" + I2S(TerrainReplaceDebugVisitedTiles) + " changed=" + I2S(TerrainReplaceDebugChangedTiles) + " return=" + I2S(TerrainReplaceDebugChangedTiles))
            call TerrainReplaceDebugDump(TerrainReplaceBatchLabel)
        endif
        set TerrainReplaceBatchLabel = "TerrainReplace"
    endfunction

    private function TerrainReplaceBatchTick takes nothing returns nothing
        local integer processed = 0
        local integer tilesPerTick = TerrainReplaceBatchTilesPerTick
        local real x
        local real y

        if not TerrainReplaceBatchRunning then
            return
        endif
        if tilesPerTick < 1 then
            set tilesPerTick = 1
        endif

        loop
            exitwhen processed >= tilesPerTick or TerrainReplaceBatchCurrentTileY > TerrainReplaceBatchMaxTileY
            set x = TerrainReplaceTileCenter(TerrainReplaceBatchCurrentTileX)
            set y = TerrainReplaceTileCenter(TerrainReplaceBatchCurrentTileY)
            call TerrainReplaceApplyAtTile(x, y)
            set processed = processed + 1
            if TerrainReplaceBatchCurrentTileX >= TerrainReplaceBatchMaxTileX then
                set TerrainReplaceBatchCurrentTileX = TerrainReplaceBatchMinTileX
                set TerrainReplaceBatchCurrentTileY = TerrainReplaceBatchCurrentTileY + 1
            else
                set TerrainReplaceBatchCurrentTileX = TerrainReplaceBatchCurrentTileX + 1
            endif
        endloop

        if TerrainReplaceBatchCurrentTileY > TerrainReplaceBatchMaxTileY then
            call TerrainReplaceBatchFinish()
        endif
        set x = 0.
        set y = 0.
    endfunction

    private function TerrainReplaceStartTileRange takes integer minTileX, integer maxTileX, integer minTileY, integer maxTileY, string label returns integer
        local integer origMinTileX = minTileX
        local integer origMaxTileX = maxTileX
        local integer origMinTileY = minTileY
        local integer origMaxTileY = maxTileY
        local integer worldMinTileX = TerrainReplaceGetWorldMinTileX()
        local integer worldMaxTileX = TerrainReplaceGetWorldMaxTileX()
        local integer worldMinTileY = TerrainReplaceGetWorldMinTileY()
        local integer worldMaxTileY = TerrainReplaceGetWorldMaxTileY()
        local integer expectedTiles

        if label == null or label == "" then
            set label = "TerrainReplace"
        endif

        if TerrainReplaceRuleCount <= 0 then
            if TerrainReplaceDebugEnabled then
                call BJDebugMsg("[TerrainReplace] async skipped label=" + label + " reason=no_rules")
            endif
            return 0
        endif

        if TerrainReplaceBatchRunning then
            if TerrainReplaceDebugEnabled then
                call BJDebugMsg("[TerrainReplace] async restart label=" + label + " previous=" + TerrainReplaceBatchLabel)
            endif
            call TerrainReplaceStopBatch()
        endif

        if minTileX < worldMinTileX then
            set minTileX = worldMinTileX
        endif
        if maxTileX > worldMaxTileX then
            set maxTileX = worldMaxTileX
        endif
        if minTileY < worldMinTileY then
            set minTileY = worldMinTileY
        endif
        if maxTileY > worldMaxTileY then
            set maxTileY = worldMaxTileY
        endif

        if TerrainReplaceDebugEnabled and (origMinTileX != minTileX or origMaxTileX != maxTileX or origMinTileY != minTileY or origMaxTileY != maxTileY) then
            call BJDebugMsg("[TerrainReplace] async bounds clamped to world: x[" + I2S(minTileX) + "," + I2S(maxTileX) + "] y[" + I2S(minTileY) + "," + I2S(maxTileY) + "]")
        endif

        if maxTileX < minTileX or maxTileY < minTileY then
            if TerrainReplaceDebugEnabled then
                call BJDebugMsg("[TerrainReplace] async skipped label=" + label + " reason=empty_area")
            endif
            return 0
        endif

        set expectedTiles = (maxTileX - minTileX + 1) * (maxTileY - minTileY + 1)
        if expectedTiles < 1 then
            if TerrainReplaceDebugEnabled then
                call BJDebugMsg("[TerrainReplace] async skipped label=" + label + " reason=empty_area")
            endif
            return 0
        endif

        call TerrainReplaceClearDebugStats()
        set TerrainReplaceBatchRunning = true
        set TerrainReplaceBatchExpectedTiles = expectedTiles
        set TerrainReplaceBatchMinTileX = minTileX
        set TerrainReplaceBatchMaxTileX = maxTileX
        set TerrainReplaceBatchMinTileY = minTileY
        set TerrainReplaceBatchMaxTileY = maxTileY
        set TerrainReplaceBatchCurrentTileX = minTileX
        set TerrainReplaceBatchCurrentTileY = minTileY
        set TerrainReplaceBatchLabel = label

        if TerrainReplaceBatchTickSec <= 0. then
            set TerrainReplaceBatchTickSec = 0.03125
        endif
        if TerrainReplaceBatchTilesPerTick < 1 then
            set TerrainReplaceBatchTilesPerTick = 1
        endif

        if TerrainReplaceDebugEnabled then
            call BJDebugMsg("[TerrainReplace] begin async label=" + label + " tiles=" + I2S(expectedTiles) + " batch=" + I2S(TerrainReplaceBatchTilesPerTick) + " tick=" + R2S(TerrainReplaceBatchTickSec))
        endif

        set TerrainReplaceBatchTimer = NewTimer()
        call SetTimerDebugTag(TerrainReplaceBatchTimer, TIMER_DEBUG_TAG_OTHER)
        if TerrainReplaceBatchTimer == null then
            set TerrainReplaceBatchRunning = false
            if TerrainReplaceDebugEnabled then
                call BJDebugMsg("[TerrainReplace] async failed label=" + label + " reason=no_timer")
            endif
            return 0
        endif
        call TimerStart(TerrainReplaceBatchTimer, TerrainReplaceBatchTickSec, true, function TerrainReplaceBatchTick)
        call TerrainReplaceBatchTick()
        return expectedTiles
    endfunction

    function TerrainReplaceDebugApplyBounds takes real minX, real minY, real maxX, real maxY returns integer
        local boolean prevDebug
        set prevDebug = TerrainReplaceDebugEnabled
        call TerrainReplaceSetDebug(true)
        call TerrainReplaceApplyBounds(minX, minY, maxX, maxY)
        call TerrainReplaceSetDebug(prevDebug)
        return TerrainReplaceGetDebugChangedTiles()
    endfunction

    function TerrainReplaceDebugApplyFromCenter takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        local boolean prevDebug
        set prevDebug = TerrainReplaceDebugEnabled
        call TerrainReplaceSetDebug(true)
        call TerrainReplaceApplyFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
        call TerrainReplaceSetDebug(prevDebug)
        return TerrainReplaceGetDebugChangedTiles()
    endfunction

    function TerrainReplaceDebugApplyRect takes rect r returns integer
        if r == null then
            return 0
        endif
        return TerrainReplaceDebugApplyBounds(GetRectMinX(r), GetRectMinY(r), GetRectMaxX(r), GetRectMaxY(r))
    endfunction

    function TerrainReplaceApplyFromCenterRect takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        return TerrainReplaceApplyFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
    endfunction

    function TerrainReplaceDebugApplyFromCenterRect takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        return TerrainReplaceDebugApplyFromCenter(centerX, centerY, leftTiles, rightTiles, upTiles, downTiles)
    endfunction

    function TerrainReplaceApplyRect takes rect r returns integer
        if r == null then
            return 0
        endif
        return TerrainReplaceApplyBounds(GetRectMinX(r), GetRectMinY(r), GetRectMaxX(r), GetRectMaxY(r))
    endfunction

    function TerrainReplaceStartBounds takes real minX, real minY, real maxX, real maxY returns integer
        local integer minTileX = TerrainReplaceNormalizeMinIndex(minX, maxX)
        local integer maxTileX = TerrainReplaceNormalizeMaxIndex(minX, maxX)
        local integer minTileY = TerrainReplaceNormalizeMinIndex(minY, maxY)
        local integer maxTileY = TerrainReplaceNormalizeMaxIndex(minY, maxY)
        return TerrainReplaceStartTileRange(minTileX, maxTileX, minTileY, maxTileY, "Bounds")
    endfunction

    function TerrainReplaceStartFromCenter takes real centerX, real centerY, integer leftTiles, integer rightTiles, integer upTiles, integer downTiles returns integer
        local integer centerTileX = TerrainReplaceFloorTileIndex(centerX)
        local integer centerTileY = TerrainReplaceFloorTileIndex(centerY)
        local integer minTileX
        local integer maxTileX
        local integer minTileY
        local integer maxTileY

        set leftTiles = TerrainReplaceClampNonNegative(leftTiles)
        set rightTiles = TerrainReplaceClampNonNegative(rightTiles)
        set upTiles = TerrainReplaceClampNonNegative(upTiles)
        set downTiles = TerrainReplaceClampNonNegative(downTiles)

        set minTileX = centerTileX - leftTiles
        set maxTileX = centerTileX + rightTiles
        set minTileY = centerTileY - downTiles
        set maxTileY = centerTileY + upTiles
        return TerrainReplaceStartTileRange(minTileX, maxTileX, minTileY, maxTileY, "Center")
    endfunction

    function TerrainReplaceStartRect takes rect r returns integer
        if r == null then
            return 0
        endif
        return TerrainReplaceStartBounds(GetRectMinX(r), GetRectMinY(r), GetRectMaxX(r), GetRectMaxY(r))
    endfunction

    private function Init takes nothing returns nothing
        call TerrainReplaceClearRules()
        call TerrainReplaceClearDebugStats()
        call TerrainReplaceStopBatch()
    endfunction
endlibrary
