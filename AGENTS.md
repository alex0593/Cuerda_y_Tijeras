# AGENTS.md

## Estado y fuentes

- Proyecto Godot 4.7.2 + GDScript en estabilización H0 del vertical slice. `ROADMAP.md` manda; `README.md` + `documentacion/` son contexto; `plantillas/` para fichas y decisiones.
- D-001 (`plantillas/registro-de-decisiones-D-001-motor.md`) está provisional hasta el playtest H0 en Android real; no añadir una segunda ruta de motor todavía.
- Estructura: `core/` (autoloads GameState/SaveService/SynergyDB/RoomGenerator), `content/*.json` (balance editable), `gameplay/` (player/enemies/rooms/main), `ui/`, `platform/`, `assets/`, `tests/`, `tools/`, `saves/`.

## Flujo de trabajo

- Alcance congelado: vertical slice 5–10 min (`ROADMAP.md` H0–H3). No arte final ni más enemigos/objetos/actos antes de validar núcleo.
- Controles: `move/aim/fire/dash/rewind/use_item/pause` en `project.godot`. Escritorio WASD+ratón/espacio/Q-E; táctil en `ui/touch_controls.tscn`.
- Android primero horizontal, local sin cuentas. Desktop valida desacoplo: reglas en `core/`, sin APIs Android fuera de `platform/`.

## Invariantes de diseño y técnica

- La **tensión** limita disparar, hacer dash y activar habilidades. Al llegar a cero Lela se ralentiza y sus cortes se debilitan, pero no queda bloqueada; estos valores son de prueba.
- **Rebobinar** solo debe revertir estado limitado y reversible (posición/velocidad, proyectiles y elementos reversibles). No debe deshacer daño, IA, recompensas, objetos ni progreso, ni permitir duplicar estados. La propuesta inicial es de dos cargas y 1,5–2 segundos.
- Cada objeto debe ser útil por sí solo; una sinergia debe cambiar una decisión o comportamiento, tener coste/limitación y no convertirse en un botón automático. Limitar las relaciones activas por objeto. Ningún objeto o sinergia debe ser obligatorio para superar una sala o jefe.
- Los ataques enemigos necesitan aviso visible y predecible; la legibilidad a tamaño móvil, el color acompañado de forma/audio, la entrada segura de las salas y una salida visible son requisitos, no detalles de arte.
- Cuando exista implementación, mantiene objetos, enemigos, recompensas y niveles como datos con identificadores estables; versiona guardados y semillas, y registra la versión del generador para reproducir errores. No codifiques números de balance directamente en escenas.

## Cambios documentales

- Para cada objeto, enemigo, jefe o habitación, copia la plantilla correspondiente de `plantillas/` y conserva los estados exactos `idea`, `prototipo`, `producción`, `aprobado` o `descartado`.
- Registra cada decisión importante con `plantillas/registro-de-decisiones.md` (fecha, problema, opciones, elección, motivo, consecuencias, fecha de revisión y estado). Enlaza una ficha con el documento general solo cuando el elemento pase a producción.
- Registra todo recurso externo en `plantillas/registro-de-recursos.md`, incluyendo autoría/fuente, licencia, fecha, modificaciones y atribución. No copies recursos protegidos ni referencias; conserva también la procedencia de cualquier resultado generado con IA.
- Usa `plantillas/bitacora-de-pruebas.md` para evidencia de playtests: versión, dispositivo, semilla, bloqueos y decisiones derivadas. Al cambiar una mecánica, sala, objeto, enemigo, jefe o regla de plataforma, actualiza el documento temático correspondiente y los checklists/backlog relacionados.
- El idioma inicial de producto y documentación es español; los textos de interfaz deben ser breves y legibles, y ninguna mecánica básica debe depender de texto largo.

## Verificación

- **No ejecutes pruebas, builds, exportaciones ni instalaciones hasta que el usuario lo pida explícitamente.** Los comandos siguientes son la fuente de verificación, pero no se lanzan por iniciativa propia.
- Godot 4.7.2 local: `/tmp/opencode/godot-4.7.2-bin/Godot_v4.7.2-stable_linux.x86_64`; las plantillas están en `~/.local/share/godot/export_templates/4.7.2.stable/`.
- `python3 tools/validate_content.py` — valida el JSON; las relaciones >2 son advertencia hasta que H2 las normalice.
- `godot --headless --import --path .` — import sin errores de parseo.
- `godot --headless --script tests/test_rules.gd --path .` — estado, dash, daño, rebobinado, semilla y guardado.
- `godot --headless --script tests/test_h0_flow.gd --path .` — smoke `start -> combat` con jugador/enemigos.
- `godot --headless --script tools/validate_content.gd --path .` — valida las constantes GDScript y la generación.
- Exportar con `ANDROID_HOME=$HOME/Android/Sdk`, `ANDROID_SDK_ROOT=$ANDROID_HOME` y `JAVA_HOME` configurado; no inventes rutas de keystore para otros equipos.
- Antes de afirmar compatibilidad con una plataforma, genera una compilación limpia de distribución y pruébala en hardware real (no solo emulador), incluyendo rendimiento, ciclo de vida, orientación/áreas seguras, controles, audio y guardar/cargar/migrar. La regresión crítica incluye movimiento, dash, tensión, rebobinado, carga de partida, puertas, objetos y regeneración de semilla.
- No se debe publicar si se pierde una partida, se corrompe un guardado, hay ataques invisibles, controles inutilizables, errores de licencia o fallos graves de compilación/firma; consulta los criterios de bloqueo de `documentacion/12-pruebas-riesgos-y-metricas.md`.
