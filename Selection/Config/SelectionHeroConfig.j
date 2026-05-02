library SelectionHeroConfig

    function SelectionGetHeroUnitId takes integer index returns integer
        if index == 0 then
            return 'H01A'
        elseif index == 1 then
            return 'H001'
        elseif index == 2 then
            return 'H005'
        elseif index == 3 then
            return 'H006'
        elseif index == 4 then
            return 'H009'
        endif
        return 'H007'
    endfunction

    function SelectionGetHeroProjectileElementId takes integer index returns integer
        // Tier inicial: todos los heroes empiezan con misil Blue.
        // SelectionElementConfig usa elementId 0 para Blue.
        // Los futuros tiers de arma deberian cambiar este perfil visual.
        return 0
    endfunction

endlibrary
