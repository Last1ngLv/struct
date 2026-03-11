//============================================================================
// SpellFinishEvent
// - Variante de SpellEffectEvent usando SPELL_FINISH
//
// API
// ---
//     RegisterSpellFinishEvent(integer abil, code onFinish)
//============================================================================
library SpellFinishEvent requires RegisterPlayerUnitEvent, optional Table

private module M

    static if LIBRARY_Table then
        static Table tb
    else
        static hashtable ht = InitHashtable()
    endif

    static method onFinish takes nothing returns nothing
        static if LIBRARY_Table then
            call TriggerEvaluate(.tb.trigger[GetSpellAbilityId()])
        else
            call TriggerEvaluate(LoadTriggerHandle(.ht, 0, GetSpellAbilityId()))
        endif
    endmethod

    private static method onInit takes nothing returns nothing
        static if LIBRARY_Table then
            set .tb = Table.create()
        endif
        // Aquí usamos SPELL_FINISH en vez de SPELL_EFFECT
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_FINISH, function thistype.onFinish)
    endmethod
endmodule

private struct S extends array
    implement M
endstruct

function RegisterSpellFinishEvent takes integer abil, code onFinish returns nothing
    static if LIBRARY_Table then
        if not S.tb.handle.has(abil) then
            set S.tb.trigger[abil] = CreateTrigger()
        endif
        call TriggerAddCondition(S.tb.trigger[abil], Filter(onFinish))
    else
        if not HaveSavedHandle(S.ht, 0, abil) then
            call SaveTriggerHandle(S.ht, 0, abil, CreateTrigger())
        endif
        call TriggerAddCondition(LoadTriggerHandle(S.ht, 0, abil), Filter(onFinish))
    endif
endfunction

endlibrary