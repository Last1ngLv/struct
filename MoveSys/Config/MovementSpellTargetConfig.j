library MovementSpellTargetConfig requires MovementSystem

    function InitMovementSpellTargetConfig takes nothing returns nothing
        // call RegisterMovementSpell('A001', "curse")
        call RegisterMovementSpellTarget('A000', "thunderbolt")
        call RegisterMovementSpellTarget('AHdr', "drain")
    endfunction

endlibrary
