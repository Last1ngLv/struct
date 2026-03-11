import matplotlib.pyplot as plt
import numpy as np

# Parámetros base de Lunar Slash
INNER_RADIUS = 70
OUTER_RADIUS_BASE = 240
CONE_ANGLE_DEGREES_BASE = 130
NEXT_TICK_EXTRA_RADIUS = 24
NEXT_TICK_EXTRA_ANGLE_DEGREES = 12

TICKS = 4  # número de tics que queremos visualizar
facing_angle_deg = 0

plt.figure(figsize=(6,6))

for tick in range(1, TICKS + 1):
    # Calcular radio y ángulo para este tic
    outer_radius = OUTER_RADIUS_BASE + (tick - 1) * NEXT_TICK_EXTRA_RADIUS
    half_angle_rad = np.radians((CONE_ANGLE_DEGREES_BASE + (tick - 1) * NEXT_TICK_EXTRA_ANGLE_DEGREES) / 2)
    facing_angle_rad = np.radians(facing_angle_deg)
    
    # Crear puntos del arco
    theta = np.linspace(facing_angle_rad - half_angle_rad, facing_angle_rad + half_angle_rad, 200)
    outer_x = outer_radius * np.cos(theta)
    outer_y = outer_radius * np.sin(theta)
    inner_x = INNER_RADIUS * np.cos(theta)
    inner_y = INNER_RADIUS * np.sin(theta)
    
    # Dibujar arco con color según el tic
    alpha = 0.3 + 0.15*tick  # más brillante para tics posteriores
    plt.fill_betweenx(outer_y, inner_x, outer_x, alpha=alpha, label=f'Tic {tick}')
    plt.plot(outer_x, outer_y, 'b')
    plt.plot(inner_x, inner_y, 'r')

# Dibujar héroe
plt.plot(0,0,'ko', markersize=8, label='Héroe')

plt.title('Lunar Slash - Expansión por tics')
plt.xlabel('X')
plt.ylabel('Y')
plt.axis('equal')
plt.grid(True)
plt.legend()
plt.show()