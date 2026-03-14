# MODULES.md - Módulos del Proyecto

## Librerías Core

### libraries/Missile.j (v2.5.1)
Sistema de proyectiles principal. 1789 líneas.
- Creación y movimiento de missiles
- Detección de colisión
- Reciclaje de dummies
- Modelo de configuración opcional

### libraries/Table.j (v3.1.0.1)
Hashtable optimizado por Bribe.
- struct Table con operator[] y operator[]=
- struct TableArray para arrays de tablas
- Soporte para todos los tipos de JASS

### libraries/TimerUtils.j (v2.0)
Reutilización de timers.
- NewTimer(), NewTimerEx()
- ReleaseTimer()
- SetTimerData(), GetTimerData()
- Tres sabores: red, blue, orange

### libraries/DummyCaster.j (v2.0.0.1)
Lanzamiento de spells con dummies.
- cast(), castTarget(), castPoint()
- Requires: (opcional) UnitIndexer

### libraries/RegisterPlayerUnitEvent.j (v5.1.0.1)
Registro de eventos por jugador.
- RegisterPlayerUnitEvent()
- RegisterPlayerUnitEventForPlayer()
- GetPlayerUnitEventTrigger()

## Sistemas de Spells

### libraries/SpellIndex.j (v1.1)
Indexación de spells activos.
- struct SpellIndex con miembros predefinidos
- Auto-limpieza de handles en destroy()
- Requiere: Table, Missile, TimerUtils, DummyCaster, WorldBounds, SpellEffectEvent, RegisterPlayerUnitEvent

### libraries/SpellFinishEvent.j
Variante de SpellEffectEvent usando SPELL_FINISH.
- RegisterSpellFinishEvent()
- Requires: RegisterPlayerUnitEvent, (opcional) Table

### libraries/SpellEffectEvent.j
Detección de lanzamiento de spells.
- Registro de eventos de spell

### libraries/IsUnitChanneling.j (v2.1.0.0)
Detección de channeling.
- IsUnitChanneling()
- Requires: RegisterPlayerUnitEvent

## Utilidades

### libraries/WorldBounds.j
Definición de límites del mundo.
- Métodos para validación de posición

### libraries/TerrainPathability.j
Detección de pathability del terreno.

### libraries/CameraEQNoise.j
Efectos de cámara.

### libraries/IsDestructableTree.j
Detección de árboles.

### libraries/SimError.j
Mensajes de error simples.

## Sistemas Personalizados

### MyMissiles/PlayerMissileLoadout (v2.0)
Configuración de missiles por jugador.
- API: SetPlayerMissileLoadout(), GetPlayerMissileAbilityChoice(), etc.
- Uses: Table

### MyMissiles/Loadout Missile.j
Sistema base de missile por jugador.

### MyMissiles/Loadout Control.j
Spell de control tipo shotgun.
- Uses: SpellIndex, Missile, PlayerMissileLoadout, IsUnitChanneling, DamageTextUtil, Table
- 464 líneas

### MyMissiles/Loadout Leap.j
Spell de salto.
- 619+ líneas

### MyMissiles/Damage Text Util.j
Utilidades de texto para daño.

### MyMissiles/SwapMana.j
Sistema de intercambio de mana.

### MyMissiles/Lunar Slash.j
Spell de slash lunar.

## Ejemplos

### MissileExamples/BloodMage/
- Fireball.j - Proyectil explosivo
- Ice Siege.j - Asedio de hielo
- Chaosflare.j - Fuego caótico
- Choatic Boulder.j - Roca caótica

### MissileExamples/Rogue/
- Guided Arrow.j - Flecha guiada
- Target Sling.j - Honda
- Gravity Shell.j - Cápsula de gravedad
- Gun Barrage.j - Ráfaga de disparo

### MissileExamples/Blademaster/
- Leap.j - Salto
- Whirlwind.j - Torbellino

### MissileExamples/Mountain King/
- Fist of Thunder.j - Puño de trueno

### MissileExamples/Necromancer/
- Bone Spirit.j - Espíritus de hueso
- Reapers Scythe.j - Guadaña del segador
