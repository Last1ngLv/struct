import matplotlib.pyplot as plt
import numpy as np

INNER_RADIUS = 70
OUTER_RADIUS = 240
CONE_ANGLE_DEGREES = 130
facing_angle_deg = 0

half_angle_rad = np.radians(CONE_ANGLE_DEGREES / 2)
facing_angle_rad = np.radians(facing_angle_deg)

theta = np.linspace(facing_angle_rad - half_angle_rad, facing_angle_rad + half_angle_rad, 200)
outer_x = OUTER_RADIUS * np.cos(theta)
outer_y = OUTER_RADIUS * np.sin(theta)
inner_x = INNER_RADIUS * np.cos(theta)
inner_y = INNER_RADIUS * np.sin(theta)

# Rellenar área de daño correctamente
x_fill = np.concatenate([outer_x, inner_x[::-1]])
y_fill = np.concatenate([outer_y, inner_y[::-1]])

plt.figure(figsize=(6,6))
plt.fill(x_fill, y_fill, color='skyblue', alpha=0.5, label='Área de daño')
plt.plot(outer_x, outer_y, 'b', label='Borde exterior')
plt.plot(inner_x, inner_y, 'r', label='Borde interior')
plt.plot(0,0,'ko', markersize=8, label='Héroe')

plt.title('Lunar Slash - Arco de ataque predeterminado')
plt.xlabel('X')
plt.ylabel('Y')
plt.axis('equal')
plt.grid(True)
plt.legend()
plt.show()