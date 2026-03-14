# CI_CD.md - Integración Continua

## Estado Actual
**Nota**: Este proyecto no tiene CI/CD automatizado actualmente.

## Posible Configuración Futura

### GitHub Actions
```yaml
# .github/workflows/jass.yml
name: JASS Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate syntax
        run: |
          # Placeholder for validation
          echo "JASS validation would go here"
```

## Validación Manual
1. Compilar en World Editor
2. Verificar sin errores
3. Test en juego

## Notas
- Warcraft III map development no tiene tooling CI estándar
- Validación principal es compilación exitosa
- Testing requiere intervención manual
