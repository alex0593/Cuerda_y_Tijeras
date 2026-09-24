# Bitácora de pruebas — 2026-09-24 Android ronda 4

## Sesión

- **Fecha:** 2026-09-24
- **Versión:** 0.1.3 (Godot 4.3, APK debug)
- **Objetivo:** verificar que mover no dispara
- **Dispositivo:** Honor CLK-LX3, Android 14
- **Semilla:** aleatoria

## Resultado

- **Qué funcionó:** mover ya no dispara.
- **Dónde se bloqueó:** botones Dash y ⟲ muertos.

## Incidencias

1. **Dash/rebobinado no responden (crítico):** los `Button` vivían de la emulación ratón-desde-toque desactivada en ronda 3. Fix: `TouchControls` detecta el toque en el rect de cada botón (`grow(12)`) y pulsa/suelta la acción (`dash`/`rewind`) de forma nativa; esos toques nunca entran a aim. Se eliminan las conexiones `pressed/button_up`.

## Decisiones

- **Mantener:** `emulate_mouse_from_touch=false`, botones nativos por rect.
- **Probar después:** botón táctil de consumible, feedback visual de pulsación en Dash/⟲, tamaño de joysticks, auto-disparo opcional.
- **Responsable:** OpenCode
- **Fecha de revisión:** próximo playtest Android
