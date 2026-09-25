# ROADMAP — Cuerda y Tijeras

Motor: **Godot 4.7.2 + GDScript**. Android horizontal es la plataforma inicial; Linux escritorio valida portabilidad. La base actual es un **vertical slice en estabilización**, no una versión comercial.

## H0 — Baseline y prueba técnica

- [x] Proyecto Godot portable, viewport 960×540, orientación sensor-landscape.
- [x] Migración de Godot 4.3 a 4.7.2 y plantillas de exportación 4.7.2 instaladas.
- [x] Autoloads separados: `GameState`, `SaveService`, `SynergyDB`, `RoomGenerator`, `PlatformService`.
- [x] Lela con movimiento, dash con frames de invulnerabilidad, tensión, disparo y rebobinado básico.
- [x] Guardado local versionado con backup y restauración de estado básica.
- [x] Smoke test real: la sala inicial avanza a `combat` con jugador y enemigos.
- [x] Test de reglas real para tensión, dash, daño, rebobinado, semilla y guardado.
- [x] Exportación Linux y APK Android debug generadas con Godot 4.7.2.
- [ ] Playtest H0 en Android 4.7.2: movement, dash, rewind, touch buttons, pause/restart y orientación.
- [ ] Confirmar la decisión D-001 después del playtest de hardware.

### Comandos H0

```sh
GODOT=/tmp/opencode/godot-4.7.2-bin/Godot_v4.7.2-stable_linux.x86_64
$GODOT --headless --import --path .
$GODOT --headless --script tests/test_rules.gd --path .
$GODOT --headless --script tests/test_h0_flow.gd --path .
$GODOT --headless --script tools/validate_content.gd --path .
python3 tools/validate_content.py

export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="$HOME/.local/share/minecrack/runtimes/java-21"
$GODOT --headless --export-debug "Linux Desktop" exports/cuerda-y-tijeras-linux.x86_64 --path .
$GODOT --headless --export-debug "Android" exports/cuerda-y-tijeras-debug.apk --path .
```

## H1 — Núcleo jugable y salas

- [x] Código de sala con entrada segura, cobertura, puerta y zona de salida real.
- [x] Soldado de estaño con escudo, carga y aviso; Caja de música con aviso circular y recompensa.
- [x] Presupuesto de enemigos, semillas por sala y drops deterministas.
- [x] Pausa/reanudación y reinicio Android/escritorio preparados.
- [x] Validación automatizada H1, export Linux/Android, instalación y lanzamiento en Android.
- [ ] Playtest manual completo de principio a jefe en hardware real.
- [ ] Ajustar la dificultad después de ese playtest.

## H2 — Objetos e inventario

- [x] `content/*.json` es la fuente runtime de objetos, sinergias y enemigos.
- [x] Slots de arma, dos mecanismos, dos amuletos y consumibles; decisión provisional D-002.
- [x] Rarezas, restricciones y cargas de consumibles en datos/runtime.
- [x] Efectos iniciales implementados: dash de tijeras, puntadas vivas, retorno magnético, notas atrapadas, órbita adhesiva y reparación con impulso.
- [ ] Validación automatizada y playtest de H2 en Android.

## H3 — Vertical slice 5–10 minutos

- [ ] Flujo completo con recompensas, elección, riesgo, taller y jefe.
- [ ] Caja de Cero con dos fases funcionales y contraestrategias.
- [ ] Inicio, resumen, derrota, victoria, pausa y guardado/carga conectados.
- [ ] Audio provisional, arte modular provisional y feedback audiovisual.
- [ ] Tutorial contextual, accesibilidad básica y controles de consumible.

## H4 — Calidad y publicación

- [ ] Playtests con personas y bitácora por dispositivo/semilla.
- [ ] Matriz Android real: gama baja/media, pantalla alargada, tablet y safe areas.
- [ ] Rendimiento, suspensión/reanudación, audio, guardado y compilación de distribución.
- [ ] APK/AAB release, firma, licencias, privacidad y clasificación por edad.

## Regla de avance

No marcar una fase como completada por tener escenas o datos: hace falta que sus pruebas automatizadas y el playtest de hardware correspondiente pasen. El diseño completo está en `documentacion/`; el estado ejecutable se demuestra con los tests y exports de este roadmap.
