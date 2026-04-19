library TextTagDebug

    globals
        constant integer TEXTTAG_DEBUG_NONE = 0
        constant integer TEXTTAG_DEBUG_UI = 1
        constant integer TEXTTAG_DEBUG_MOVECAST = 2
        constant integer TEXTTAG_DEBUG_AI = 3
        constant integer TEXTTAG_DEBUG_DAMAGE = 4
        constant integer TEXTTAG_DEBUG_HEALTHBAR = 5
        private constant integer TEXTTAG_DEBUG_MAX = 5

        private integer array TextTagCreated[8]
        private integer array TextTagLive[8]
        private integer array TextTagPeak[8]
        private integer TextTagCreatedTotal = 0
        private integer TextTagLiveTotal = 0
        private integer TextTagPeakTotal = 0
    endglobals

    private function TextTagDebugNormalize takes integer category returns integer
        if category < TEXTTAG_DEBUG_NONE or category > TEXTTAG_DEBUG_MAX then
            return TEXTTAG_DEBUG_NONE
        endif
        return category
    endfunction

    private function TextTagDebugInc takes integer category returns nothing
        set category = TextTagDebugNormalize(category)
        set TextTagCreatedTotal = TextTagCreatedTotal + 1
        set TextTagLiveTotal = TextTagLiveTotal + 1
        if TextTagLiveTotal > TextTagPeakTotal then
            set TextTagPeakTotal = TextTagLiveTotal
        endif
        if category > TEXTTAG_DEBUG_NONE then
            set TextTagCreated[category] = TextTagCreated[category] + 1
            set TextTagLive[category] = TextTagLive[category] + 1
            if TextTagLive[category] > TextTagPeak[category] then
                set TextTagPeak[category] = TextTagLive[category]
            endif
        endif
    endfunction

    private function TextTagDebugDec takes integer category returns nothing
        set category = TextTagDebugNormalize(category)
        if TextTagLiveTotal > 0 then
            set TextTagLiveTotal = TextTagLiveTotal - 1
        endif
        if category > TEXTTAG_DEBUG_NONE and TextTagLive[category] > 0 then
            set TextTagLive[category] = TextTagLive[category] - 1
        endif
    endfunction

    function CreateTrackedTextTag takes integer category returns texttag
        local texttag tag = CreateTextTag()
        call TextTagDebugInc(category)
        return tag
    endfunction

    function ReleaseTrackedTextTag takes integer category returns nothing
        call TextTagDebugDec(category)
    endfunction

    function DestroyTrackedTextTag takes texttag tag, integer category returns nothing
        call TextTagDebugDec(category)
        call DestroyTextTag(tag)
    endfunction

    function GetTextTagDebugCreated takes integer category returns integer
        set category = TextTagDebugNormalize(category)
        return TextTagCreated[category]
    endfunction

    function GetTextTagDebugLive takes integer category returns integer
        set category = TextTagDebugNormalize(category)
        return TextTagLive[category]
    endfunction

    function GetTextTagDebugPeak takes integer category returns integer
        set category = TextTagDebugNormalize(category)
        return TextTagPeak[category]
    endfunction

    function GetTextTagDebugCreatedTotal takes nothing returns integer
        return TextTagCreatedTotal
    endfunction

    function GetTextTagDebugLiveTotal takes nothing returns integer
        return TextTagLiveTotal
    endfunction

    function GetTextTagDebugPeakTotal takes nothing returns integer
        return TextTagPeakTotal
    endfunction

endlibrary
