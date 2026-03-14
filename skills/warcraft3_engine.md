# Warcraft 3 Engine

## Sistema
Warcraft III tiene un motor de juego con características específicas:
- Sistema de coordenadas X/Y (plano) y Z (altura)
- Sistema de unidades con tipos, habilidades, items
- Sistema de terreno con pathabilidad
- Sistema de efectos (models, particles, ubersplats)
- Sistema de timers y eventos

## Reglas Importantes

### Coordenadas
- X positivo = Este, Y positivo = Norte
- Z = altura sobre el terreno
- `GetUnitX(u)`, `GetUnitY(u)` devuelven posición de unidad
- `GetTerrainZ(x, y)` devuelve altura del terreno

### Unidades
- Toda unidad tiene un `handle id` único
- Units pueden ser aliadas, enemigas o neutrales
- Tipos: UNIT_TYPE_ANY, UNIT_TYPE_GROUND, UNIT_TYPE_AIR, UNIT_TYPE_STRUCTURE
- Estados: alive, dead, visible, hidden

### Habilidades (Abilities)
- Rawcode de 4 caracteres (ej: 'AHfs' = Frost Armor)
- Niveles con `GetUnitAbilityLevel`
- Efectos registrados con triggers

### Daño
```jass
UnitDamageTarget(unit source, unit target, real amount, boolean attack, boolean ranged, attacktype at, damagetype dt, weapontype wt) returns boolean
```

### Efectos
```jass
AddSpecialEffect(string modelName, real x, real y) returns effect
AddSpecialEffectTarget(string modelName, widget target, string attachPoint) returns effect
DestroyEffect(effect whichEffect)
```

## Ejemplos del Proyecto

### Detección de Posición Válida (Leap.j)
```jass
private function IsPointJumpable takes real x, real y returns boolean
    if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
        return IsTerrainWalkable(x, y)
    endif
    return false
endfunction
```

### Verificar Unidad Viva
```jass
private function FilterUnits takes unit target, player owner returns boolean
    return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
endfunction
```

### Ángulo entre Dos Puntos
```jass
local real angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
```

### Distancia entre Puntos
```jass
local real dist = SquareRoot((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
```

### Verificar Channeling
```jass
function IsUnitChanneling takes unit whichUnit returns boolean
    // Retorna true si la unidad está canalizando una habilidad
endfunction
```

## Errores Comunes

1. **Z ignorado**: Olvidar altura en sistemas de proyectiles
2. **Unidades inválidas**: No verificar `GetUnitTypeId(u) == 0`
3. **Coordenadas wrong**: Confundir X e Y
4. **Memory leaks**: No destruir efectos, timers, lightnings
5. **Pathability**: Terreno no walkable causa bugs

## Cómo Modificar Correctamente

1. **Crear unidad temporal**: Usar DummyCaster para spells
2. **Añadir efecto**: `AddSpecialEffectTarget` con punto de attach válido
3. **Verificar terreno**: Siempre verificar pathability antes de mover
4. **Calcular movimiento**: Usar funciones trigonométricas (sin/cos/atan2)
5. **Daño**: Verificar unidades vivas antes de aplicar
