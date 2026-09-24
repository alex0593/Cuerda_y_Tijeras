# Bitácora de pruebas — 2026-09-24 Android

## Sesión

- **Fecha:** 2026-09-24
- **Versión:** 0.1.0-h0 (commit 9991f03, Godot 4.3, APK debug)
- **Objetivo:** primer playtest H0 en hardware real
- **Personas que participan:** Aela (jugadora)
- **Dispositivo:** Honor CLK-LX3, Android 14 (SDK 34)
- **Semilla:** aleatoria

## Resultado

- **Qué funcionó:** instalación APK + lanzamiento OK; dash/rewind responden.
- **Dónde se bloqueó:** imposible moverse con sentido (ejes invertidos).
- **Qué no se entendió:** —
- **Qué pareció injusto:** —
- **Qué objeto funcionó mejor:** —
- **Qué objeto se ignoró:** —
- **Cuándo se usó rebobinado:** —

## Incidencias

1. **Ejes invertidos (crítico):** `ui/touch_controls.gd:_apply_stick` negaba el vector (`-n.x`, `-n.y`): derecha→izquierda, arriba→abajo.
2. **Disparo táctil no funciona (crítico):** el aim dependía de `get_global_mouse_position()` (doc 09: escritorio), sin posición de ratón válida en táctil. Fix: stick derecho escribe `aim_vec` y dispara mientras se mantiene.
3. **Juego en portrait (mayor):** `window/handheld/orientation=1` es portrait en Godot 4 (0=landscape, 4=sensor_landscape). Fix: `4` en `project.godot` y `export_presets.cfg` (doc 02: orientación horizontal).

## Decisiones

- **Mantener:** twin-stick (izq mover, der apuntar+disparar), WASD+ratón en escritorio.
- **Cambiar:** signos stick, aim táctil por vector, orientación sensor_landscape.
- **Probar después:** tamaño de joysticks, auto-disparo opcional, botón consumible táctil (hoy sin botón).
- **Responsable:** OpenCode
- **Fecha de revisión:** próximo playtest Android
