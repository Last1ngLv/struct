library WavePointApi requires WaveTest

    function WaveGetPointCount takes Wave w returns integer
        if w == 0 then
            return 0
        endif
        return w.pointCount
    endfunction

    function WaveGetPointX takes Wave w, integer pointIndex returns real
        if w == 0 then
            return 0.0
        endif
        if pointIndex < 0 or pointIndex >= w.pointCount then
            return 0.0
        endif
        return w.pointX[pointIndex]
    endfunction

    function WaveGetPointY takes Wave w, integer pointIndex returns real
        if w == 0 then
            return 0.0
        endif
        if pointIndex < 0 or pointIndex >= w.pointCount then
            return 0.0
        endif
        return w.pointY[pointIndex]
    endfunction

endlibrary
