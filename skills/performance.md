# Performance

## Sistema
El rendimiento en Warcraft III es crítico:
- Límite de operaciones por segundo
- Handle creation es costoso
- Timers consumen recursos
- Enumeración de unidades es lenta

## Reglas Importantes

### Timer Utils
- Siempre reutilizar timers con NewTimer()/ReleaseTimer()
- No crear timers en loops
- Attach datos, no crear estructuras

### Enumeración
- Usar GLOBAL_GROUP de SpellIndex
- No crear groups en loops
- Usar boolexpr pre-creados cuando sea posible

### Handles
- Destroy efectos después de usar
- Nullificar referencias
- Reutilizar dummies con recycling

### Missile
- Configurar USE_COLLISION_Z_FILTER apropiadamente
- Usar WRITE_DELAYED_MISSILE_RECYCLING
- Velocidad apropiada para帧 rate

## Ejemplos del Proyecto

### Reutilización de Timer (Correcto)
```jass
// Loadout Control.j
private function OnPoisonTick takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local SpellIndex dex = GetTimerData(t)
    //... lógica ...
    call ReleaseTimer(t)  // Siempre liberar
    set t = null
endfunction
```

### Grupo Global (Correcto)
```jass
// Fireball.j
call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, radius, null)
loop
    set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
    exitwhen u == null
    call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
    // lógica
endloop
```

### Filter Pre-creado (Correcto)
```jass
// Guided Arrow.j
private struct GuidedArrow extends array
    static boolexpr filter 
    
    private static method onInit takes nothing returns nothing
        set thistype.filter = Condition(function ConsiderUnitsFiltered)
    endmethod
    //...
endstruct
```

### Reciclaje de Missile (Configuración)
```jass
// Missile.j globals
public constant boolean WRITE_DELAYED_MISSILE_RECYCLING = true
private constant real DELAYED_MISSILE_DEATH_ANIMATION_TIME = 2.
```

### Verificación de Validez (Evitar operaciones innecesarias)
```jass
// Loadout Control.j
if amount <= 0. or GetUnitTypeId(source) == 0 then
    return
endif
```

### Constants para Valores Fijos
```jass
// Correcto - compilado como valor constante
private constant function GetFlyDistance takes integer level returns real
    return 800. + (200*level)
endfunction

// Incorrecto - calculado en runtime
private function GetFlyDistanceRuntime takes integer level returns real
    return 800. + (200*level) // No es constant
endfunction
```

## Optimizaciones Específicas

### 1. Table vs Hashtable Nativa
- Table es más rápida y tiene mejor API
- TableArray para múltiples tablas

### 2. Boolean con UnitIndexer
- IsUnitChanneling usa UnitIndexer si está disponible
- Mucho más rápido que hashtable

### 3. Timer con Datos Adjuntos
- NewTimerEx(data) para inicializar con datos
- Evita SetTimerData adicional

### 4. Collision Type
- CIRCLE para velocidad < collision
- RECTANGLE para velocidad >= collision

### 5. Velocidad de Missile
- Valor por frame, no por segundo
- TIMER_TIMEOUT = 1./32. → velocidad * 32 = unidades/segundo

## Errores Comunes

1. **Crear timer en cada spell**: Causa lag
2. **No liberar timer**: Memory leak + lag
3. **Crear group en loop**: Lag severo
4. **No usar recycling de missile**: Too many units
5. **Boolean lookup con hashtable**: Lento para muchas unidades

## Cómo Optimizar

1. **Pre-crear recursos**:
   - Boolexpr en onInit
   - Groups reutilizados
   - Timers del pool

2. **Minimizar handle creation**:
   - Reutilizar efectos
   - Recycling de missile
   - Cachear valores

3. **Optimizar loops**:
   - Usar FirstOfGroup correctamente
   - Evitar operaciones en cada iteración
   - Early exit cuando sea posible

4. **Elegir estructuras correctas**:
   - Table > Hashtable nativa
   - UnitIndexer > Handle lookup
   - Arrays > Table para valores simples

5. **Configurar Missile apropiadamente**:
   - MAXIMUM_COLLISION_SIZE preciso
   - COLLISION_ACCURACY_FACTOR apropiado
   - USE_COLLISION_Z_FILTER solo si necesario
