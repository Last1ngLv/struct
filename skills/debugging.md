# Debugging

## Sistema
El debugging en vJASS es limitado pero existen técnicas:
- BJDebugMsg para mensajes
- SimError para errores visibles
- DisplayTextToPlayer para output
- Conditional debug con static if

## Reglas Importantes

### BJDebugMsg
- Solo visible para el host en modo debug
- Puede saturar la consola
- Funciona en modo single player

### SimError
- Mensaje formateado en dorado
- Visible para jugador específico
- Incluye sonido de error

### DisplayTextToPlayer
- Visible para todos los jugadores
- Puede usar timed messages
- Incluye coordenadas de pantalla

## Ejemplos del Proyecto

### Debug Simple (IsUnitChanneling.j - comentado)
```jass
// En el código original había comentarios de debug:
// call BJDebugMsg("Ignore!!1")
// call BJDebugMsg("Ignore!!2")
```

### Error al Usuario (SimError.j)
```jass
function SimError takes player ForPlayer, string msg returns nothing
    set msg="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n|cffffcc00"+msg+"|r"
    if (GetLocalPlayer() == ForPlayer) then
        call ClearTextMessages()
        call DisplayTimedTextToPlayer(ForPlayer, 0.52, 0.96, 2.00, msg)
        call StartSound(error)
    endif
endfunction
```

### Verificación de Unit ID
```jass
// En Loadout Control.j
if (GetUnitTypeId(source) == 0) or (GetUnitTypeId(target) == 0) then
    return false
endif
```

### Validación de Datos
```jass
// Verificar SpellIndex válido
if (dex.count <= 0) or (GetUnitTypeId(dex.target) == 0) or (not UnitAlive(dex.target)) then
    // cleanup y return
endif
```

## Técnicas de Debugging

### 1. Mensajes de Debug
```jass
call BJDebugMsg("Debug: x=" + R2S(x) + " y=" + R2S(y))
call BJDebugMsg("Debug: ability=" + GetObjectName(abilityId))
```

### 2. Verificar Handles
```jass
if GetHandleId(myUnit) == 0 then
    call BJDebugMsg("Handle inválido!")
endif
```

### 3. Conditional Debug
```jass
static if DEBUG_MODE then
    call BJDebugMsg("Debug info")
endif
```

### 4. Contador de Llamadas
```jass
globals
    private integer debugCounter = 0
endglobals

function MiFuncion takes nothing returns nothing
    set debugCounter = debugCounter + 1
    call BJDebugMsg("Llamada #" + I2S(debugCounter))
endfunction
```

### 5. Verificar Datos de Timer
```jass
local timer t = GetExpiredTimer()
local integer data = GetTimerData(t)
call BJDebugMsg("Timer data: " + I2S(data))
```

## Errores Comunes

1. **BJDebugMsg solo local**: No funciona en multiplayer para todos
2. **Exceso de debug**: Saturar consola hace difícil encontrar errores reales
3. **Olvidar Remove**: Debug code queda en producción
4. **No verificar null**: Asumir que handles son válidos

## Cómo Debugear Efectivamente

1. **Verificar compilación**: Asegurar que no hay errores de sintaxis
2. **Verificar registro**: Confirmar que eventos están registrados
3. **Verificar flujo**: Añadir prints en puntos clave
4. **Verificar datos**: Mostrar valores de variables
5. **Verificar nulls**: Always check for null handles
6. **Simplificar**: Reducir a caso mínimo
7. **Test incremental**: Probar cada cambio
