# Documentación del Proyecto

Este proyecto contiene documentación especializada para agentes IA que trabajen en código vJASS de Warcraft III.

## Estructura de Documentación

```
/
├── agents/          # Estado y contexto del agente
├── docs/           # Documentación técnica
├── knowledge/      # Base de conocimiento
├── quality/        # Testing y calidad
├── devops/         # Despliegue
└── skills/         # Skills reutilizables
```

## Cómo Usar Esta Documentación

### Para Agentes IA

1. **Skills (skills/)**: Información técnica específica
   - `vjass_core.md` - Fundamentos de vJASS
   - `warcraft3_engine.md` - Motor del juego
   - `triggers_system.md` - Sistema de eventos
   - `gameplay_systems.md` - Sistemas de gameplay
   - `data_structures.md` - Estructuras de datos
   - `debugging.md` - Técnicas de debug
   - `performance.md` - Optimización

2. **API Reference (knowledge/API_REFERENCE.md)**: Referencia de funciones

3. **Architecture (docs/)**: Diseño del sistema

### Uso en Conversación

Cuando trabajes en este proyecto:

1. **Crear nuevo spell**: Consulta `skills/gameplay_systems.md`
2. **Usar librerías**: Consulta `knowledge/API_REFERENCE.md`
3. **Debuggear**: Consulta `skills/debugging.md`
4. **Optimizar**: Consulta `skills/performance.md`
5. **Entender estructura**: Consulta `docs/ARCHITECTURE.md`

## Reglas del Proyecto

- No modificar librerías externas a menos que sea necesario
- Mantener compatibilidad con el sistema de eventos existente
- Usar las convenciones de nombres del proyecto
- Siempre validar unidades antes de operar
- Usar recycling de timers y missiles
