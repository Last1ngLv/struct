library TenderSpawnConfig requires TenderSystem

    function InitTenderSpawnConfig takes nothing returns nothing
        call RefreshTenderUnitByType(TenderUnitTypeId, TenderX, TenderY, TenderFacing)
    endfunction

endlibrary
