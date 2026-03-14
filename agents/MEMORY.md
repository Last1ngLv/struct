# MEMORY.md - Memoria de Trabajo

**Este archivo se modifica dinámicamente conforme el agente trabaja.**

---

## Formato de Entradas

Para agregar nueva información:

```markdown
## [FECHA] - Nuevo Hallazgo

**Contexto**: [Describe cuándo/aplicación]
**Aprendizaje**: [Qué se aprendió]
**Código ejemplo**:
```jass
// código relevante
```
**Relacionado con**: [archivo/skill relacionado]
```

---

## Entradas Activas

### 2026-03-14 - Configuración Inicial

**Contexto**: Análisis inicial del proyecto
**Aprendizaje**: 
- Missile.j es el sistema core de proyectiles
- SpellIndex para tracking de spells activos
- PlayerMissileLoadout para configuración por jugador

**Relacionado con**: `libraries/Missile.j`, `libraries/SpellIndex.j`, `MyMissiles/Loadout Missile.j`

---

## Errores Resueltos

| Fecha | Error | Solución | Archivo |
|-------|-------|----------|---------|
| | | | |

---

## Códigos Útiles Descubiertos

```jass
// [Agregar aquí códigos útiles que el agente descubra]

// Ejemplo:
function GetUnitZ takes unit u returns real
    return GetUnitFlyHeight(u) + GetTerrainZ(GetUnitX(u), GetUnitY(u))
endfunction
```

---

## Decisiones de Diseño

| Fecha | Decisión | Rationale |
|-------|----------|----------|
| | | |

---

## Pendientes de Investigación

- [ ] [Agregar temas a investigar]
- [ ] 

---

## Patrones Confirmados

```jass
// [Agregar patrones de código que funcionan]
```

---

## Notas de Sesión

### Sesión: [número]
**Objetivo**: 
**Resultado**:
**Problemas encontrados**:
**Soluciones aplicadas**:
```

---

## Cómo Usar Este Archivo

1. **Nueva sesión**: Leer entradas anteriores para contexto
2. **Descubrimiento**: Agregar nuevo aprendizaje inmediatamente
3. **Error resuelto**: Documentar en tabla de errores
4. **Código útil**: Agregar a sección correspondiente
5. **Decisión**: Documentar con rationale

---

## Tags de Referencia

- `#spell` - Creación de spells
- `#bug` - Bug y solución
- `#optimization` - Mejoras de rendimiento
- `#pattern` - Patrón reusable
- `#api` - Nueva función API
- `#hack` - Solución no estándar
