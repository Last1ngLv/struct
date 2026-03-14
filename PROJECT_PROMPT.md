# PROJECT_PROMPT.md - Prompt para Agentes

Este es el prompt base que debe usar cualquier agente al trabajar en este proyecto.

---

## Contexto del Proyecto

Este es un proyecto de Warcraft III con código vJASS que contiene:
- Sistema de proyectiles (Missile.j)
- Librerías de soporte (Table, TimerUtils, DummyCaster, etc.)
- Sistemas de spells personalizados (Loadout)
- Ejemplos de spells por héroe

## Instrucciones

### Antes de Escribir Código

1. **Lee las skills relevantes** según la tarea:
   - Tarea de spell → `skills/gameplay_systems.md`
   - Tarea de datos → `skills/data_structures.md`
   - Tarea de debug → `skills/debugging.md`

2. **Consulta la API** en `knowledge/API_REFERENCE.md`

3. **Revisa las convenciones** en `docs/CONVENTIONS.md`

### Al Escribir Código

1. **Sigue el patrón del proyecto**:
   - Estructura de archivo: globals → funciones → struct → Init
   - Nombres: camelCase para funciones, UPPER_SNAKE para constantes
   - Comentarios: Encabezado con descripción

2. **Usa las librerías existentes**:
   - Missile para proyectiles
   - SpellIndex para tracking
   - Table para datos
   - TimerUtils para timers

3. **Nobmodifies librerías core** a menos que sea absolutamente necesario

### Después de Escribir Código

1. **Verifica**:
   - ¿Seguí las convenciones?
   - ¿Valido los handles?
   - ¿Libero los recursos?
   - ¿Registré el evento correctamente?

2. **Revisa** en `quality/QA_GUIDE.md`

---

## Ejemplo de Prompt para Nueva Tarea

```
Necesito crear un spell de tipo [DESCRIBE]. 
El spell debe [FUNCIONALIDAD].
Consulta las skills relevantes y crea el código siguiendo 
las convenciones del proyecto.
```

---

## Plantilla para Crear Spell

```jass
//TESH.scrollpos=0
//TESH.alwaysfold=0
library MiSpell initializer Init uses SpellIndex, Missile /* v1.0
/************************************************************************************
*
*   Descripción del spell
*
************************************************************************************/

// Configuración
globals
    private constant integer MI_HABILIDAD = 'ABCD'
    private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
    private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
endglobals

// Filtro
private function FilterUnits takes unit target, player owner returns boolean
    return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
endfunction

// Configuración por nivel
private constant function GetDamage takes integer level returns real
    return 100. + 50.*level
endfunction

// Struct
private struct MiSpell extends array
    private static method onRemove takes Missile missile returns boolean
        // Cleanup
        return true
    endmethod
    
    implement MissileStruct
endstruct

// Handler
private function OnEffect takes nothing returns nothing
    local unit source = GetTriggerUnit()
    local integer level = GetUnitAbilityLevel(source, MI_HABILIDAD)
    // Crear missile
    call MiSpell.launch(missile)
    set source = null
endfunction

// Init
private function Init takes nothing returns nothing
    call RegisterSpellEffectEvent(MI_HABILIDAD, function OnEffect)
endfunction

endlibrary
```

---

## Reglas de Oro

1. **Siempre** valida `GetUnitTypeId(u) == 0` antes de operar
2. **Siempre** usa `UnitAlive()` para verificar unidades
3. **Siempre** libera timers con `ReleaseTimer()`
4. **Siempre** destruye efectos con `DestroyEffect()`
5. **Siempre** llama `SpellIndex.destroy()` en onRemove
6. **Nunca** olvides `launch()` después de crear Missile
7. **Nunca** modifies las librerías core sin razón
