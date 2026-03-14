# QA_GUIDE.md - Guía de Calidad

## Estándares de Calidad

### Código
- [ ] Naming consistente (convenciones del proyecto)
- [ ] Comentarios en secciones principales
- [ ] Validación de parámetros
- [ ] Nullificación de handles
- [ ] No crear objetos en loops

### Funcionalidad
- [ ] Spells funcionan correctamente
- [ ] Colisiones precisas
- [ ] Daño aplicado correctamente
- [ ] Recycling funciona
- [ ] Sin memory leaks

### Rendimiento
- [ ] No crear boolexpr en loops
- [ ] Usar Table/TimerUtils para reutilización
- [ ] Velocidad de missile apropiada
- [ ] Colisión optimizada

### Experiencia de Usuario
- [ ] Efectos visuales apropiados
- [ ] Mensajes de error claros
- [ ] Comportamiento intuitivo

## Checklist de Release

### Pre-Compilación
- [ ] Todas las dependencias presentes
- [ ] Constantes configuradas
- [ ] Modelos y sonidos referenciados existen
- [ ] Variables globales inicializadas

### Post-Compilación
- [ ] Sin errores de JASSHelper
- [ ] Warnings entendidos y aceptados

### Testing
- [ ] Spell funciona en caso normal
- [ ] Spell funciona en casos edge
- [ ] No crashes
- [ ] Recycling funciona
