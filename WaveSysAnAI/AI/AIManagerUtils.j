library AIManagerUtils

    function AIBoolToInt takes boolean b returns integer
        if b then
            return 1
        endif
        return 0
    endfunction

    function AIIntervalToMs takes real sec, integer fallback returns integer
        local integer ms
        if sec <= 0.0 then
            return fallback
        endif
        set ms = R2I(sec*1000.0 + 0.5)
        if ms < 50 then
            set ms = 50
        endif
        return ms
    endfunction

    function AIClampInt takes integer v, integer minV, integer maxV returns integer
        if v < minV then
            return minV
        endif
        if v > maxV then
            return maxV
        endif
        return v
    endfunction

    function AIClampReal takes real v, real minV, real maxV returns real
        if v < minV then
            return minV
        endif
        if v > maxV then
            return maxV
        endif
        return v
    endfunction

    function AIGetRandomRealRange takes real minV, real maxV returns real
        local real tmp
        if maxV < minV then
            set tmp = minV
            set minV = maxV
            set maxV = tmp
        endif
        if maxV <= minV then
            return minV
        endif
        return GetRandomReal(minV, maxV)
    endfunction

    function AIGetRandomMsRange takes real minSec, real maxSec, integer fallbackMs, integer minMs returns integer
        local integer value
        local real tmp
        if maxSec < minSec then
            set tmp = minSec
            set minSec = maxSec
            set maxSec = tmp
        endif
        if minSec <= 0.0 and maxSec <= 0.0 then
            set value = fallbackMs
        else
            set value = AIIntervalToMs(AIGetRandomRealRange(minSec, maxSec), fallbackMs)
        endif
        if value < minMs then
            set value = minMs
        endif
        return value
    endfunction

endlibrary
