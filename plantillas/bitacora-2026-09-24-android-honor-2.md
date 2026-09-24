# Bitácora de pruebas — 2026-09-24 Android ronda 2

## Sesión

- **Fecha:** 2026-09-24
- **Versión:** 0.1.1 (Godot 4.3, APK debug)
- **Objetivo:** verificar fixes de ejes, disparo y horizontal
- **Dispositivo:** Honor CLK-LX3, Android 14
- **Semilla:** aleatoria

## Resultado

- **Qué funcionó:** horizontal OK, ejes correctos.
- **Dónde se bloqueó:** mover también dispara; cualquier toque dispara.
- **Qué no se entendió:** —
- **Qué pareció injusto:** —

## Incidencias

1. **Mover dispara (crítico):** el toque de Dash/⟲ (a la derecha) entraba por `_input` antes que la GUI y se registraba como aim+disparo. Fix: `_unhandled_input` (los botones consumen su toque) + aim solo si `x >= 40%`.
2. **Cualquier toque dispara (crítico):** `fire` se activaba al apoyar el dedo. Fix: tocar no dispara; solo el arrastre del stick derecho más allá de la zona muerta (`aim_vec != ZERO`). Lela ya disparaba por `aim_vec`.
3. **Decorativos tapaban toques:** los `ColorRect` de los sticks (mouse_filter STOP) podían comerse toques. Fix: `mouse_filter = 2` (IGNORE) en los 6 decorativos; botones siguen en STOP.

## Decisiones

- **Mantener:** twin-stick con disparo solo por arrastre derecho.
- **Probar después:** botón táctil de consumible, tamaño de joysticks, auto-disparo opcional.
- **Responsable:** OpenCode
- **Fecha de revisión:** próximo playtest Android
