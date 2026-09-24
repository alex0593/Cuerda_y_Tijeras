# ROADMAP — Vertical slice 5–10 min (primera versión jugable)
# Motor: Godot 4.x + GDScript. Plataforma inicial Android (horizontal), validación en escritorio.

## H0 — Repo y prueba técnica [HECHO parcial]
- [x] Git init, `project.godot` 960x540, input `move/aim/fire/dash/rewind/use_item/pause`
- [x] Autoloads: GameState, SaveService, SynergyDB, RoomGenerator, PlatformService
- [x] Lela: mover, dash i-frames, tensión, rebobinado reversible, consumible
- [ ] Verificar en Godot: `--headless --import` + abrir `gameplay/main/game.tscn` en editor
- [ ] Export escritorio Linux desde editor y jugar con WASD+ratón/espacio/Q

## H1 — Sala y primer enemigo
- [x] `room.tscn` 880x460, muros, entrada segura izquierda, spawn por presupuesto
- [x] Soldado de estaño (persigue/avisa/carga) + Caja de música (anillo 8 notas)
- [ ] Playtest: entrada sin sorpresas, aviso legible, sin objeto obligatorio
- [ ] Ajustar `move_speed`, `dash_cooldown`, costes en `core/` + `content/*.json`

## H2 — Objetos y sinergias (8+1, 6–10)
- [x] Datos en `SynergyDB` + `content/items.json`: tijeras_precisión, resorte, imán, caja_música, ojo, hilo, tornillos, pegamento, bobina
- [x] Pickup con imán, hilo que ata, rebotes, retorno magnético, crítico ojo
- [ ] Implementar órbitas reales (notas) y trampas adhesivas — hoy solo flags/daño parcial
- [ ] Playtest: cada objeto útil solo; 6–10 sinergias forman tarjeta sin bloquear

## H3 — Jefe, flujo y cierre slice
- [x] Caja de Cero 2 fases (abanico; abanico+hilos), sala boss_arena
- [x] Flujo `start→combat→treasure→risk→workshop→boss`, recompensas, resumen con semilla, R reintenta
- [x] Guardado versionado `profile/settings/partida-a.v1.json` + `.bak`, export semilla
- [ ] Audio provisional (buses música/efectos), HUD final, pausa confirmada, iconos tienda no
- [ ] Export Android (debug) en dispositivo real + matriz mínima doc 12

## Comandos
```sh
/tmp/opencode/Godot_v4.3-stable_linux.x86_64 --headless --import --path .
/tmp/opencode/Godot_v4.3-stable_linux.x86_64 --headless --check-only --script tools/validate_content.gd --path .
python3 tools/validate_content.py
/tmp/opencode/Godot_v4.3-stable_linux.x86_64 --path . gameplay/main/game.tscn
```

## Criterio de salida (doc 10 Fase 1)
Controles <30s, tensión <1min, rebobinado útil sin trivializar, 3 objetos con estrategias distintas, partida 5–10min, arte provisional legible, Android+escritorio, ganas de repetir.
