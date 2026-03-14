# vJASS Core

## Sistema
vJASS es una extensión del lenguaje JASS (Warcraft III) que añade:
- Librerías (`library`/`endlibrary`)
- Módulos (`module`/`endmodule`)
- Structs que extienden arrays
- Tipos genéricos
- Texto macros (`//! textmacro`)

## Reglas Importantes

### Estructura de Librería
```jass
library MiLibreria initializer Init uses Dependencia1, Dependencia2 /* v1.0
    // código
endlibrary
```

### Módulos
- Se implementan en structs con `implement MiModulo`
- Pueden tener métodos estáticos y de instancia
- No pueden tener variables de instancia directamente (usar struct)

### Structs que Extienden Arrays
```jass
private struct MiStruct extends array
    // miembros
endstruct
```
- Son estáticos por defecto
- No necesitan `create()` parainstanciar
- El "this" es el índice del array

### Text Macros
```jass
//! textmacro MI_MACRO takes VAR
    call BJDebugMsg($VAR$)
//! endtextmacro

//! runtextmacro MI_MACRO("Hola")
```

## Ejemplos del Proyecto

### Librería Simple (SimError.j)
```jass
library SimError initializer init
    globals
        private sound error
    endglobals

    function SimError takes player ForPlayer, string msg returns nothing
        set msg="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n|cffffcc00"+msg+"|r"
        if (GetLocalPlayer() == ForPlayer) then
            call ClearTextMessages()
            call DisplayTimedTextToPlayer(ForPlayer, 0.52, 0.96, 2.00, msg)
            call StartSound(error)
        endif
    endfunction

    private function init takes nothing returns nothing
         set error=CreateSoundFromLabel("InterfaceError",false,false,false,10,10)
    endfunction
endlibrary
```

### Struct con Módulo (Fireball.j)
```jass
private struct Fireball extends array
    private static method onRemove takes Missile missile returns boolean
        local unit u
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, GetExplosionRadius(missile.data), null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, missile.owner) then
                call UnitDamageTarget(missile.source, u, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            endif
        endloop
        call DestroyEffect(AddSpecialEffectTarget(ON_EXPLOSE_FX, missile.dummy, "origin"))
        return true
    endmethod
    
    implement MissileStruct
endstruct
```

### Verificación de Librería Disponible
```jass
static if LIBRARY_Table then
    // Table está disponible
else
    // Usar alternativa
endif
```

## Errores Comunes

1. **Olvidar `endlibrary`**: Causa error de compilación
2. **Dependencias circulares**: Library A usa B, B usa A = error
3. **Module sin implementar**: Struct no puede usar módulo que no existe
4. **Textmacro mal usado**: Sintaxis `//! runtextmacro` incorrecta
5. **Struct array sin `private`**: Debe ser `private struct X extends array`

## Cómo Modificar Correctamente

1. **Añadir nueva librería**: Crear archivo .j con estructura `library ... endlibrary`
2. **Añadir dependencia**: Agregar en línea `uses` de la librería
3. **Crear módulo reutilizable**: Definir en archivo separado o al inicio
4. **Usar textmacro para código repetitivo**: Definir y ejecutar con runtextmacro
