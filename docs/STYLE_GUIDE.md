# STYLE_GUIDE.md - Guía de Estilo

## Formato General
- Archivos vJASS con extensión `.j`
- TESH scrollpos y alwaysfold al inicio
- Encabezado de documentación en cada archivo
- Sangría: 4 espacios (estándar JASS)

## Encabezado de Librería
```jass
//TESH.scrollpos=0
//TESH.alwaysfold=0
library MiLibreria initializer Init uses Dependencia /* v1.0
/************************************************************************************
*
*   Descripción breve
*
************************************************************************************/
```

## Sección Globals
- Constants primero
- Arrays después
- Tablas privadas
- Separación lógica con comentarios

## Structs
```jass
private struct MiStruct extends array
    // miembros
    unit source
    real damage
    
    // métodos
    method destroy takes nothing returns nothing
        // cleanup
    endmethod
endstruct
```

## Implementación de Módulos
```jass
private struct MiSpell extends array
    implement MissileStruct
    // callbacks
endstruct
```

## Callbacks de Missile
```jass
private static method onRemove takes Missile missile returns boolean
    // lógica
    return true // destruir missile
endmethod

private static method onCollide takes Missile missile, unit hit returns boolean
    // lógica
    return true // destruir missile
endmethod
```

## Registro de Eventos
```jass
private function Init takes nothing returns nothing
    call RegisterSpellEffectEvent(HABILIDAD, function OnEffect)
endfunction
```

## Funciones Privadas
- Filter para boolexpr
- Helper para cálculos
- Getters para configuración
