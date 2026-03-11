import matplotlib.pyplot as plt
import numpy as np

# Parámetros de Lunar Slash predeterminados
INNER_RADIUS = 70
OUTER_RADIUS = 240
CONE_ANGLE_DEGREES = 130  # ángulo total del arco
facing_angle_deg = 0       # frente al eje X positivo

# Convertir ángulo a radianes
half_angle_rad = np.radians(CONE_ANGLE_DEGREES / 2)
facing_angle_rad = np.radians(facing_angle_deg)

# Crear puntos para dibujar el arco
theta = np.linspace(facing_angle_rad - half_angle_rad, facing_angle_rad + half_angle_rad, 200)
outer_x = OUTER_RADIUS * np.cos(theta)
outer_y = OUTER_RADIUS * np.sin(theta)
inner_x = INNER_RADIUS * np.cos(theta)
inner_y = INNER_RADIUS * np.sin(theta)

# Dibujar el arco
plt.figure(figsize=(6,6))
plt.fill_betweenx(outer_y, inner_x, outer_x, color='skyblue', alpha=0.5, label='Área de daño')
plt.plot(outer_x, outer_y, 'b', label='Borde exterior')
plt.plot(inner_x, inner_y, 'r', label='Borde interior')

# Dibujar héroe
plt.plot(0,0,'ko', markersize=8, label='Héroe')

# Configuración del gráfico
plt.title('Lunar Slash - Arco de ataque predeterminado')
plt.xlabel('X')
plt.ylabel('Y')
plt.axis('equal')
plt.grid(True)
plt.legend()
plt.show()