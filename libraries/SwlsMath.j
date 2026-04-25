library SwlsMath

    // Distancia al cuadrado (sin SquareRoot, ideal para comparaciones).
    function SwlsDistanceSq takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        return dx*dx + dy*dy
    endfunction

    // Distancia real (usa SquareRoot).
    function SwlsDistance takes real x1, real y1, real x2, real y2 returns real
        return SquareRoot(SwlsDistanceSq(x1, y1, x2, y2))
    endfunction

    // Compatibilidad legacy: varios sistemas antiguos usan este nombre.
    function DistanceBetweenCoords takes real x1, real y1, real x2, real y2 returns real
        return SwlsDistance(x1, y1, x2, y2)
    endfunction

endlibrary
