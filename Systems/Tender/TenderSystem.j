library TenderSystem requires SwlsMath

    globals
        unit TenderUnit = null
        integer TenderOwnerId = bj_PLAYER_NEUTRAL_EXTRA
        integer TenderUnitTypeId = 'h004'
        real TenderX = -1536.0
        real TenderY = 24064.0
        real TenderFacing = 270.0
    endglobals

    // Crea/recrea el tender por tipo y posición.
    // Si ya existe uno en TenderUnit, lo remueve primero.
    function RefreshTenderUnitByType takes integer unitTypeId, real x, real y, real facing returns unit
        if unitTypeId != 0 then
            set TenderUnitTypeId = unitTypeId
        endif
        set TenderX = x
        set TenderY = y
        set TenderFacing = facing

        if TenderUnit != null and GetUnitTypeId(TenderUnit) != 0 then
            call RemoveUnit(TenderUnit)
        endif
        set TenderUnit = CreateUnit(Player(TenderOwnerId), TenderUnitTypeId, TenderX, TenderY, TenderFacing)
        return TenderUnit
    endfunction

    // Alias semántico para stage/config dinámica.
    function RefreshTenderUnit takes integer unitTypeId, real x, real y, real facing returns unit
        return RefreshTenderUnitByType(unitTypeId, x, y, facing)
    endfunction

    function GetTenderUnit takes nothing returns unit
        if TenderUnit == null then
            return RefreshTenderUnitByType(TenderUnitTypeId, TenderX, TenderY, TenderFacing)
        endif
        if GetUnitTypeId(TenderUnit) == 0 then
            return RefreshTenderUnitByType(TenderUnitTypeId, TenderX, TenderY, TenderFacing)
        endif
        return TenderUnit
    endfunction

    function IsUnitNearTender takes unit u, real radius returns boolean
        local unit t = GetTenderUnit()
        local boolean result
        local real radiusSq
        if u == null or t == null then
            set t = null
            return false
        endif
        if radius <= 0.0 then
            set radius = 500.0
        endif
        set radiusSq = radius*radius
        set result = SwlsDistanceSq(GetUnitX(u), GetUnitY(u), GetUnitX(t), GetUnitY(t)) < radiusSq
        set t = null
        return result
    endfunction

endlibrary
