# TESTING.md - Testing

## Estado de Testing
**Nota**: Warcraft III vJASS no tiene framework de testing tradicional.

## Métodos de Verificación

### Pruebas Manuales
1. Compilar mapa en World Editor
2. Ejecutar en Warcraft III
3. Verificar comportamiento de spells
4. Verificar efectos visuales

### Debugging
```jass
// Usar BJDebugMsg para debugging
call BJDebugMsg("Debug: " + I2S(valor))

// Usar SimError para errores de usuario
call SimError(GetTriggerPlayer(), "Mensaje de error")

// Verificar en SpellIndex
if GetUnitTypeId(source) == 0 then
    return // Unit inválida
endif
```

### Validación de Código
- Compilación exitosa en JASSHelper
- Sin errores de sintaxis
- Dependencias resueltas

## Áreas Críticas a Verificar
1. Creación de Missile
2. Callbacks de colisión
3. Destrucción de recursos
4. Validación de unidades
5. Sistema de recycling

## Notas
- No hay tests unitarios automatizados
- Testing es manual mediante el juego
- Validación de código mediante compilación
