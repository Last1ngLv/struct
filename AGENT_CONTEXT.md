# AGENT_CONTEXT.md - Contexto para Agentes IA

Este archivo contiene las instrucciones base que un agente debe seguir al trabajar en este proyecto.

## Carga de Skills

Antes de realizar cualquier acción, el agente DEBE cargar las skills relevantes:

### Skills Obligatorias
```
skills/vjass_core.md         - Fundamentos del lenguaje
skills/warcraft3_engine.md   - API del juego
```

### Skills por Tipo de Tarea

| Tarea | Skills a Cargar |
|-------|-----------------|
| Crear spell | gameplay_systems.md, triggers_system.md |
| Modificar spell existente | gameplay_systems.md, debugging.md |
| Optimizar código | performance.md, data_structures.md |
| Debuggear | debugging.md, triggers_system.md |
| Añadir estructura de datos | data_structures.md, vjass_core.md |
| Trabajar con eventos | triggers_system.md, warcraft3_engine.md |

## Flujo de Trabajo del Agente

### 1. Análisis de Tarea
```
1. Identificar tipo de tarea
2. Cargar skills relevantes
3. Revisar arquitectura en docs/
4. Consultar API reference si es necesario
```

### 2. Implementación
```
1. Seguir convenciones en docs/CONVENTIONS.md
2. Aplicar reglas de docs/CODING_RULES.md
3. Usar mejores prácticas de docs/BEST_PRACTICES.md
4. Mantener estilo del proyecto en docs/STYLE_GUIDE.md
```

### 3. Verificación
```
1. Revisar quality/QA_GUIDE.md
2. Verificar con TEST_STRATEGY.md
3. Aplicar checklist de testing
```

## Verificación de Dependencias

Antes de modificar código, verificar dependencias en:
- `knowledge/DEPENDENCIES.md` - Diagrama de dependencias
- `docs/MODULES.md` - Lista de módulos disponibles

## shortcuts de Consulta Rápida

### Crear Nuevo Spell
```
1. Leer skills/gameplay_systems.md (sección "Spell Básico")
2. Ver ejemplo en MissileExamples/
3. Consultar API: Missile.create(), MissileStruct
4. Registrar en Init con RegisterSpellEffectEvent
```

### Añadir Sistema de Loadout
```
1. Leer skills/gameplay_systems.md (sección "Sistema de Loadout")
2. Ver PlayerMissileLoadout en MyMissiles/
3. Consultar API de Table
4. Seguir patrón de SlotOfPlayer
```

### Debuggear un Spell
```
1. Leer skills/debugging.md
2. Usar BJDebugMsg para verificar flujo
3. Verificar SpellIndex en callbacks
4. Validar con FilterUnits
```

## Restricciones

- NO crear código sin consultar skills relevantes primero
- NO modificar librerías core (Missile.j, Table.j, etc.)
- SIEMPRE seguir convenciones del proyecto
- SIEMPRE validar handles antes de usar
- SIEMPRE liberar recursos (timers, effects)
