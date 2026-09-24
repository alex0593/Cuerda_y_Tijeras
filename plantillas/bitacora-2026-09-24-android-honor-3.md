# Bitácora de pruebas — 2026-09-24 Android ronda 3

## Sesión

- **Fecha:** 2026-09-24
- **Versión:** 0.1.2 (Godot 4.3, APK debug)
- **Objetivo:** verificar disparo solo por arrastre derecho
- **Dispositivo:** Honor CLK-LX3, Android 14
- **Semilla:** aleatoria

## Resultado

- **Qué funcionó:** horizontal, ejes, botones ya no disparan, toques sueltos no disparan.
- **Dónde se bloqueó:** el joystick de movimiento sigue disparando.

## Incidencias

1. **Mover dispara (crítico):** `pointing/emulate_mouse_from_touch` venía activado por defecto y cada toque generaba un clic izquierdo emulado; `fire` incluye el botón izquierdo del ratón (doc 09: escritorio). Fix: `emulate_mouse_from_touch=false` en `project.godot`. Los botones táctiles responden al toque nativo, no dependen de la emulación.

## Decisiones

- **Mantener:** `emulate_touch_from_mouse=true` (probar táctil con ratón en escritorio).
- **Probar después:** botón táctil de consumible, tamaño de joysticks, auto-disparo opcional.
- **Responsable:** OpenCode
- **Fecha de revisión:** próximo playtest Android
