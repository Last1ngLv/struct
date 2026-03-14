# TEST_STRATEGY.md - Estrategia de Testing

## Estrategia

### Phase 1: Validación de Compilación
- [ ] Compilar en JASSHelper
- [ ] Verificar dependencias
- [ ] Resolver errores de sintaxis

### Phase 2: Pruebas Unitarias Manuales
- [ ] Test de cada spell individual
- [ ] Verificar creación de Missile
- [ ] Verificar colisiones
- [ ] Verificar callbacks

### Phase 3: Integración
- [ ] Test de múltiples spells
- [ ] Test de sistema de loadout
- [ ] Test multiplayer

### Phase 4: Casos Edge
- [ ] Unidades inválidas
- [ ] Objetivos nulos
- [ ] Destrucción de unidades durante spell
- [ ] Reciclaje de missiles

## Casos de Prueba

### Spell Básico (Fireball)
1. Lanzar spell a ubicación válida
2. Verificar missile creado
3. Verificar movimiento
4. Verificar colisión con enemy
5. Verificar daño
6. Verificar FX de impacto
7. Verificar recycling

### Spell Complejo (Guided Arrow)
1. Lanzar spell a enemigo
2. Verificar tracking
3. Verificar colisión inicial
4. Verificar pierce
5. Verificar búsqueda de nuevo objetivo
6. Verificar destrucción final

### Sistema de Loadout
1. Cambiar configuración de jugador
2. Verificar cambio de modelo
3. Verificar cambio de damage
4. Verificar cambio de speed
