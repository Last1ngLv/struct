# CONVENTIONS.md - Convenciones de Código

## Convenciones de Nombres

### Librerías
- Nombre de archivo: `CamelCase.j` o nombre descriptivo
- Nombre de library: `library Nombre`
- Versión al final: `/* v1.0`

### Structs
- Nombre: `CamelCase`
- Ejemplo: `struct Missile`, `struct Fireball`, `struct SpellIndex`
- Herencia de array para MissileStruct: `private struct MiSpell extends array`

### Funciones
- camelCase para funciones
- Prefijos comunes:
  - `Get` - Getters
  - `Set` - Setters
  - `On` - Callbacks/Eventos
  - `Init` - Inicialización
  - `Filter` - Filtros

### Constantes
- UPPER_SNAKE_CASE para constantes
- `constant real`, `constant integer`, `constant string`
- Prefijo `MAX_`, `DEFAULT_`, `MIN_`

### Variables Globales
- Arrays con sufijo `[]`
- Privadas con prefijo `_` o en módulo privado
- Tablas como `byHandle`

## Estructura de Archivo

```jass
//TESH.scrollpos=0
//TESH.alwaysfold=0
library MiLibreria initializer Init uses Dependencia1, Dependencia2 /* v1.0
/************************************************************************************
*
*   Descripción breve del sistema
*
************************************************************************************/
// Configuración del usuario
globals
    private constant integer MI_CONSTANTE = 'ABCD'
    private constant real MI_REAL = 100.0
endglobals

// Funciones privadas
private function FilterUnits takes unit target, player owner returns boolean
    return UnitAlive(target) and IsUnitEnemy(target, owner)
endfunction

// Struct principal
private struct MiStruct extends array
    implement MiModulo
    
    method destroy takes nothing returns nothing
        // cleanup
    endmethod
endstruct

// Inicialización
private function OnEffect takes nothing returns nothing
    // lógica del spell
endfunction

private function Init takes nothing returns nothing
    call RegisterSpellEffectEvent(MI_HABILIDAD, function OnEffect)
endfunction

endlibrary
```

## Patrones de Código

### Spell Simple
1. Constants para configuración
2. FilterUnits privado
3. Struct con MissileStruct
4. onRemove/onCollide callbacks
5. OnEffect para lanzamiento
6. Init para registro

### Spell Complejo
1. Configuración extensa en globals
2. Múltiples funciones helper
3. Tablas para estado activo
4. Fases y contadores en SpellIndex
5. Múltiples callbacks

## Comentarios
- Encabezado con descripción en cada archivo
- Sección de configuración de usuario
- TODO: para código pendiente
- N/A en el proyecto para documentación inline
