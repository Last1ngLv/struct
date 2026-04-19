library WavePointGroups initializer Init requires Table, WaveTest
//------------------------------------------------------------------------------
// WavePointGroups
//------------------------------------------------------------------------------
// Carga puntos desde rects + unidades marcador en el init del mapa.
//
// Flujo:
//   1) Registrar grupos por nombre/rect/rawcode.
//   2) Build una sola vez.
//   3) Aplicar el grupo a una instancia Wave con un solo call.
//
// Orden determinista:
//   - Y descendente
//   - X ascendente
//
// Dedupe:
//   - Dos puntos se consideran iguales si difieren <= 0.1 en X e Y.
//
// Notas:
//   - Las unidades marcador se eliminan del mapa luego de capturar su punto.
//   - Si no existen markers en el rect, el grupo queda vacío.
//------------------------------------------------------------------------------
    globals
        private constant integer WPG_MAX_GROUPS = 32
        private constant integer WPG_MAX_POINTS_PER_GROUP = 128
        private constant real WPG_POINT_EPSILON = 0.10
        private constant integer WPG_SORT_Y_DESC_X_ASC = 0

        private Table WPGGroupByHash
        private integer WPGGroupCount = 0
        private boolean WPGDebugEnabled = false

        private string array WPGGroupName
        private rect array WPGGroupRect
        private integer array WPGGroupMarkerRawcode
        private integer array WPGGroupSortMode
        private boolean array WPGGroupRegistered
        private boolean array WPGGroupBuilt
        private integer array WPGGroupPointCount
        private real array WPGGroupPointX
        private real array WPGGroupPointY

        private group WPGTempGroup
    endglobals

    private function WPG_GroupKey takes integer groupId, integer pointIndex returns integer
        return groupId * WPG_MAX_POINTS_PER_GROUP + pointIndex
    endfunction

    private function WPG_SafeHash takes string name returns integer
        local integer h = StringHash(name)
        if h < 0 then
            set h = -h
        endif
        return h
    endfunction

    private function WPG_AbsReal takes real value returns real
        if value < 0. then
            return -value
        endif
        return value
    endfunction

    private function WPG_GetGroupId takes string groupName returns integer
        local integer hash
        if (groupName == null) or (groupName == "") then
            return 0
        endif
        if WPGGroupByHash == 0 then
            return 0
        endif
        set hash = WPG_SafeHash(groupName)
        if WPGGroupByHash.has(hash) then
            return WPGGroupByHash[hash]
        endif
        return 0
    endfunction

    private function WPG_IsSamePoint takes integer groupId, integer pointIndex, real x, real y returns boolean
        local integer key = WPG_GroupKey(groupId, pointIndex)
        return WPG_AbsReal(WPGGroupPointX[key] - x) <= WPG_POINT_EPSILON and WPG_AbsReal(WPGGroupPointY[key] - y) <= WPG_POINT_EPSILON
    endfunction

    private function WPG_BoolToInt takes boolean b returns integer
        if b then
            return 1
        endif
        return 0
    endfunction

    private function WPG_AddPointToGroup takes integer groupId, real x, real y returns boolean
        local integer count = WPGGroupPointCount[groupId]
        local integer i = 0
        local integer key

        if groupId <= 0 or groupId > WPG_MAX_GROUPS then
            return false
        endif

        loop
            exitwhen i >= count
            if WPG_IsSamePoint(groupId, i, x, y) then
                return false
            endif
            set i = i + 1
        endloop

        if count >= WPG_MAX_POINTS_PER_GROUP then
            if WPGDebugEnabled then
                call BJDebugMsg("[WavePointGroups] group '" + WPGGroupName[groupId] + "' full (" + I2S(WPG_MAX_POINTS_PER_GROUP) + ")")
            endif
            return false
        endif

        set key = WPG_GroupKey(groupId, count)
        set WPGGroupPointX[key] = x
        set WPGGroupPointY[key] = y
        set WPGGroupPointCount[groupId] = count + 1
        return true
    endfunction

    private function WPG_SortGroup takes integer groupId returns nothing
        local integer count = WPGGroupPointCount[groupId]
        local integer i = 1
        local integer j
        local integer keyI
        local integer keyJ
        local real x
        local real y

        loop
            exitwhen i >= count
            set keyI = WPG_GroupKey(groupId, i)
            set x = WPGGroupPointX[keyI]
            set y = WPGGroupPointY[keyI]
            set j = i - 1
            loop
                exitwhen j < 0
                set keyJ = WPG_GroupKey(groupId, j)
                if (WPGGroupPointY[keyJ] > y) or ((WPGGroupPointY[keyJ] == y) and (WPGGroupPointX[keyJ] <= x)) then
                    exitwhen true
                endif
                set WPGGroupPointX[WPG_GroupKey(groupId, j + 1)] = WPGGroupPointX[keyJ]
                set WPGGroupPointY[WPG_GroupKey(groupId, j + 1)] = WPGGroupPointY[keyJ]
                set j = j - 1
            endloop
            set WPGGroupPointX[WPG_GroupKey(groupId, j + 1)] = x
            set WPGGroupPointY[WPG_GroupKey(groupId, j + 1)] = y
            set i = i + 1
        endloop
    endfunction

    private function WPG_ClearGroupPoints takes integer groupId returns nothing
        set WPGGroupPointCount[groupId] = 0
        set WPGGroupBuilt[groupId] = false
    endfunction

    private function WPG_BuildOneGroup takes integer groupId returns nothing
        local unit u
        local integer markerRawcode = WPGGroupMarkerRawcode[groupId]
        local rect area = WPGGroupRect[groupId]
        local integer beforeCount

        call WPG_ClearGroupPoints(groupId)

        if (area == null) or (markerRawcode == 0) then
            if WPGDebugEnabled then
                call BJDebugMsg("[WavePointGroups] skip '" + WPGGroupName[groupId] + "' reason=no_rect_or_marker")
            endif
            return
        endif

        call GroupClear(WPGTempGroup)
        call GroupEnumUnitsInRect(WPGTempGroup, area, null)
        loop
            set u = FirstOfGroup(WPGTempGroup)
            exitwhen u == null
            call GroupRemoveUnit(WPGTempGroup, u)
            if GetUnitTypeId(u) == markerRawcode then
                call WPG_AddPointToGroup(groupId, GetUnitX(u), GetUnitY(u))
                call RemoveUnit(u)
            endif
        endloop
        call WPG_SortGroup(groupId)
        set WPGGroupBuilt[groupId] = true

        if WPGDebugEnabled then
            set beforeCount = WPGGroupPointCount[groupId]
            call BJDebugMsg("[WavePointGroups] built '" + WPGGroupName[groupId] + "' points=" + I2S(beforeCount))
        endif

        set u = null
        set area = null
    endfunction

    function WavePointGroupsSetDebug takes boolean enabled returns nothing
        set WPGDebugEnabled = enabled
    endfunction

    function WavePointGroupsClear takes nothing returns nothing
        local integer i = 1
        local integer hash
        if WPGGroupByHash != 0 then
            call WPGGroupByHash.flush()
        endif
        set WPGGroupCount = 0
        loop
            exitwhen i > WPG_MAX_GROUPS
            set WPGGroupName[i] = ""
            set WPGGroupRect[i] = null
            set WPGGroupMarkerRawcode[i] = 0
            set WPGGroupSortMode[i] = WPG_SORT_Y_DESC_X_ASC
            set WPGGroupRegistered[i] = false
            set WPGGroupBuilt[i] = false
            set WPGGroupPointCount[i] = 0
            set i = i + 1
        endloop
    endfunction

    function WavePointGroupRegister takes string groupName, rect area, integer markerRawcode returns integer
        local integer hash
        local integer groupId
        if (groupName == null) or (groupName == "") or (area == null) or (markerRawcode == 0) then
            return 0
        endif
        set hash = WPG_SafeHash(groupName)
        if WPGGroupByHash.has(hash) then
            set groupId = WPGGroupByHash[hash]
        else
            set groupId = WPGGroupCount + 1
            if groupId > WPG_MAX_GROUPS then
                if WPGDebugEnabled then
                    call BJDebugMsg("[WavePointGroups] cannot register '" + groupName + "' reason=max_groups")
                endif
                return 0
            endif
            set WPGGroupCount = groupId
            set WPGGroupByHash[hash] = groupId
        endif

        set WPGGroupName[groupId] = groupName
        set WPGGroupRect[groupId] = area
        set WPGGroupMarkerRawcode[groupId] = markerRawcode
        set WPGGroupSortMode[groupId] = WPG_SORT_Y_DESC_X_ASC
        set WPGGroupRegistered[groupId] = true
        set WPGGroupBuilt[groupId] = false
        set WPGGroupPointCount[groupId] = 0
        return groupId
    endfunction

    function WavePointGroupCount takes string groupName returns integer
        local integer groupId = WPG_GetGroupId(groupName)
        if groupId <= 0 then
            return 0
        endif
        return WPGGroupPointCount[groupId]
    endfunction

    function WavePointGroupGetPointX takes string groupName, integer pointIndex returns real
        local integer groupId = WPG_GetGroupId(groupName)
        if groupId <= 0 then
            return 0.0
        endif
        if pointIndex < 0 or pointIndex >= WPGGroupPointCount[groupId] then
            return 0.0
        endif
        return WPGGroupPointX[WPG_GroupKey(groupId, pointIndex)]
    endfunction

    function WavePointGroupGetPointY takes string groupName, integer pointIndex returns real
        local integer groupId = WPG_GetGroupId(groupName)
        if groupId <= 0 then
            return 0.0
        endif
        if pointIndex < 0 or pointIndex >= WPGGroupPointCount[groupId] then
            return 0.0
        endif
        return WPGGroupPointY[WPG_GroupKey(groupId, pointIndex)]
    endfunction

    function WavePointGroupsBuild takes nothing returns nothing
        local integer i = 1
        if WPGGroupByHash == 0 then
            return
        endif
        loop
            exitwhen i > WPGGroupCount
            if WPGGroupRegistered[i] then
                call WPG_BuildOneGroup(i)
            endif
            set i = i + 1
        endloop
    endfunction

    function WavePointGroupApplyToWave takes Wave w, string groupName returns integer
        local integer groupId = WPG_GetGroupId(groupName)
        local integer i = 0
        local integer count
        if (w == 0) or (groupId <= 0) then
            return 0
        endif
        set count = WPGGroupPointCount[groupId]
        loop
            exitwhen i >= count
            call w.addPoint(WPGGroupPointX[WPG_GroupKey(groupId, i)], WPGGroupPointY[WPG_GroupKey(groupId, i)])
            set i = i + 1
        endloop
        return count
    endfunction

    function WavePointGroupsDebugDump takes nothing returns nothing
        local integer i = 1
        local integer j
        local integer count
        if not WPGDebugEnabled then
            return
        endif
        loop
            exitwhen i > WPGGroupCount
            if WPGGroupRegistered[i] then
                set count = WPGGroupPointCount[i]
                call BJDebugMsg("[WavePointGroups] '" + WPGGroupName[i] + "' count=" + I2S(count) + " built=" + I2S(WPG_BoolToInt(WPGGroupBuilt[i])))
                set j = 0
                loop
                    exitwhen j >= count
                    call BJDebugMsg("[WavePointGroups]   #" + I2S(j) + " x=" + R2S(WPGGroupPointX[WPG_GroupKey(i, j)]) + " y=" + R2S(WPGGroupPointY[WPG_GroupKey(i, j)]))
                    set j = j + 1
                endloop
            endif
            set i = i + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        set WPGGroupByHash = Table.create()
        set WPGTempGroup = CreateGroup()
        call WavePointGroupsClear()
    endfunction
endlibrary
