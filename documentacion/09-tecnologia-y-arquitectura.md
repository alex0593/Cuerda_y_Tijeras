# 09. Tecnología, multiplataforma y arquitectura

## 1. Objetivo

La primera versión comercial se publicará para Android, pero el proyecto no debe quedar limitado técnicamente a Android.

La estrategia es:

- Diseñar y desarrollar con una opción que pueda exportarse a varias plataformas.
- Mantener las reglas del juego separadas de los servicios de cada sistema.
- Usar una compilación de escritorio durante el desarrollo para detectar dependencias involuntarias de Android.
- Adaptar y publicar cada plataforma solamente después de comprobarla en dispositivos reales.

## 2. Plataformas

### Primera versión

- Android.
- Orientación horizontal.
- Controles táctiles.
- Teclado y ratón disponibles para desarrollo.

### Adaptaciones posteriores

1. Windows, Linux y macOS.
2. iOS.
3. Web, si las pruebas de rendimiento, audio y guardado son satisfactorias.

El orden puede cambiar. Por ejemplo, iOS podría adelantar a escritorio si el estudio decide priorizar esa plataforma y dispone de los sistemas de firma necesarios.

## 3. Opciones de motor

### Godot 4.x

Godot es un motor multiplataforma orientado especialmente al desarrollo de juegos 2D. Su documentación incluye exportación para Windows, Linux, macOS, Android, iOS y web.

**Ventajas para este proyecto:**

- Editor visual y entorno integrado.
- Buena herramienta para animación 2D, partículas, UI, escenas y recursos.
- Permite comprobar rápidamente las exportaciones de escritorio y Android.
- Existe un proyecto base que puede abrirse en PC sin esperar a preparar cada dispositivo móvil.
- Es una opción ligera para un equipo pequeño.

**Desventajas:**

- El juego no se escribiría principalmente en Kotlin.
- Usar GDScript implica aprender otro lenguaje.
- Cada plataforma tiene requisitos de herramientas, firma o empaquetado.
- La web presenta restricciones de rendimiento, memoria, almacenamiento y ejecución que deben probarse.

**Recomendación:** es la mejor opción si la prioridad es terminar y publicar el juego con el menor trabajo de infraestructura.

### libGDX con Kotlin

libGDX permite crear proyectos con Kotlin y ofrece backends para Android, escritorio, iOS y web.

**Ventajas para este proyecto:**

- Se utiliza Kotlin, por lo que se mantiene el interés original en Kotlin.
- Se puede construir un núcleo de reglas independiente del renderizado.
- Resulta conveniente para aprender arquitectura de juegos a bajo nivel.
- Los backends de plataforma están separados en módulos.

**Desventajas:**

- Requiere construir más infraestructura y herramientas que en Godot.
- El editor visual y el flujo de trabajo son menos integrados.
- La animación de títeres, la interfaz y las herramientas de diseño requieren más trabajo manual.
- No es Kotlin Multiplatform por sí mismo; es un motor JVM con backends.

**Recomendación:** elegir esta alternativa si saber Kotlin es tan importante como producir el juego rápidamente.

### Unity

**Ventajas:**

- Ecosistema amplio.
- Buena selección de herramientas y paquetes.
- Histórico soporte multiplataforma.

**Desventajas para este proyecto:**

- Puede resultar más pesado y configurado para un roguelite 2D pequeño.
- Introduce mayor dependencia de proyectos y paquetes externos.
- Godot ofrece una ruta más ligera para el prototipo propuesto.

**Recomendación:** alternativa válida, pero no la primera a considerar para el alcance actual.

### Kotlin Multiplatform con motor propio

Kotlin Multiplatform permite compartir código entre plataformas, pero no es un motor de juego. No incluye por sí mismo el editor, renderizado 2D, física, animación, entrada, audio, gestión de escenas y herramientas de exportación.

**Consecuencia:** construir sobre KMP desde cero supondría desarrollar gran parte de un motor antes de implementar el juego.

**Recomendación:** no hacer esto para la primera versión. Si el proyecto usa libGDX, el núcleo de reglas puede mantenerse en Kotlin puro y separarse con interfaces. KMP solo debería añadirse más adelante si realmente existe una segunda aplicación o un conjunto de plataformas que justifique esa capa.

## 4. Recomendación

La recomendación depende de una prioridad del desarrollador:

### Opción recomendada para terminar el juego

**Godot 4.x + GDScript**

### Opción recomendada para mantener Kotlin

**libGDX + Kotlin**, con un módulo de reglas independiente.

Antes de decidir, conviene realizar una prueba técnica breve en ambas opciones. La prueba debe incluir:

- Movimiento táctil.
- Disparo orientado.
- Dash.
- Una animación realizada mediante recortes o pivotes.
- Guardado local.
- Exportación a Android.
- Exportación a escritorio.

La decisión se toma según el tiempo de implementación, la facilidad para mantener el arte y la confianza del desarrollador en cada herramienta.

## 5. Arquitectura portable

La regla más importante es:

> El núcleo del juego no debe depender de clases, permisos o APIs de Android.

Con Godot, esta separación se realiza mediante escenas, scripts, recursos y servicios. Con libGDX, mediante módulos Gradle, interfaces e implementaciones por plataforma.

Estructura conceptual:

```text
Cuerda_y_Tijeras/
├── core/                 # Reglas, estado, combate y generación
├── content/              # Datos de objetos, enemigos, jefes y actos
├── gameplay/             # Actores, entrada, cámara y sesiones
├── ui/                   # HUD, menús y accesibilidad
├── platform/             # Interfaces de servicios
├── platform-android/     # Android
├── platform-desktop/     # Windows, Linux y macOS
├── platform-ios/         # iOS
├── platform-web/         # Web
├── assets/               # Arte, audio, animaciones y tipografías
├── tests/                # Pruebas de reglas y contenido
└── tools/                # Validación, medición y utilidades
```

### 5.1 Herramientas de medición

En `tools/` hay dos arneses que **no son tests**: generan informes para decidir el balance con
números en lugar de con playtests. No pasan ni fallan; informan.

```sh
# Forma del mapa, economía, botín y alcanzabilidad del catálogo.
#   --seeds N agrega sobre N semillas; --seed N vuelca una partida sala a sala.
godot --headless --script tools/measure_run.gd --path . -- --seeds 200

# Partidas jugadas por un bot en la escena real. --max acota el tope por partida.
godot --headless --script tools/measure_play.gd --path . -- --runs 8
```

`measure_run.gd` replica el RNG de botín de `base_enemy._drop()` con la misma semilla y el mismo
orden de aparición que usa la sala, así que los totales son exactos y no estimaciones. Además
replica el RNG del generador: con la misma semilla el mapa es idéntico.

`measure_play.gd` monta `game.tscn` y pulsa las mismas acciones que un dedo, sin llamar a nada
interno de la jugadora. **Tiene un sesgo declarado y hay que leerlo antes que los números: el
bot no esquiva, no usa el rebobinado para salvar una situación y no elige rutas. Es un jugador
competente, no uno bueno.** Si sobrevive, el juego es más fácil de lo que parece; si muere, no
demuestra que sea demasiado difícil. Sus números van siempre juntos con una partida que juega una
persona.

Cuando se cambie un número de balance, la comprobación es: medir, ajustar, volver a medir. Ningún
ajuste se da por bueno solo porque el test siga en verde.

Esta estructura es conceptual. Al seleccionar Godot no es obligatorio crear un proyecto Gradle por cada carpeta: puede mapearse con directorios, escenas, recursos y servicios globales.

## 6. Servicios que deben depender de una plataforma

El juego consume interfaces genéricas, no implementaciones concretas.

- `SaveService`: guardar y cargar.
- `SettingsService`: preferencias persistentes.
- `Haptics`: vibración cuando exista soporte.
- `ShareService`: compartir una semilla o resultado.
- `AchievementsService`: logros.
- `StoreService`: compras y productos digitales.
- `CloudSaveService`: guardado en la nube en el futuro.
- `AnalyticsService`: telemetría opcional y anonimizada.
- `FullscreenService`: gestión de pantalla.
- `SafeAreaService`: márgenes útiles del sistema.
- `NotificationService`: avisos locales, si fueran necesarios.

Cada plataforma implementa lo que soporte. Las funciones no disponibles pueden desactivarse o utilizar una alternativa segura.

## 7. Qué permanece fuera del núcleo

No deben aparecer directamente en las reglas del juego:

- APIs de Android.
- Rutas absolutas del sistema.
- Servicios de Google Play.
- Vibración específica.
- Flujo nativo de compartir.
- Compras específicas de una tienda.
- Permisos del sistema.
- Integraciones de logros de una plataforma.
- Captura de pantalla nativa.

## 8. Entrada

Definir acciones lógicas en lugar de botones concretos:

- `move`
- `aim`
- `fire`
- `dash`
- `rewind`
- `use_item`
- `pause`

Mapeos previstos:

| Acción | Android | Escritorio | iOS |
|---|---|---|---|
| Mover | Joystick izquierdo | WASD/flechas | Joystick izquierdo |
| Apuntar y disparar | Joystick derecho | Ratón | Joystick derecho |
| Dash | Botón | Espacio | Botón |
| Rebobinar | Botón | Q/E | Botón |
| Consumible | Botón | 1–3 | Botón |
| Pausa | Botón | Escape | Botón |

En escritorio también debe ser posible usar mando.

## 9. UI y resolución

- Usar contenedores, anclajes y escalado; no posiciones fijas para toda la pantalla.
- Respetar `safe areas`, muescas y barras del sistema.
- Probar relaciones de aspecto 16:9, 20:9, 4:3 y tablet.
- Permitir cambiar el tamaño de los controles táctiles.
- Mantener una separación mínima entre botones.
- Comprobar que la cámara nunca deje zonas esenciales fuera de pantalla.
- Separar la escala de la interfaz de la escala de los sprites.

## 10. Guardado portable

- Guardado local como base.
- Separar perfil, ajustes y partida.
- Incluir una versión de formato en cada archivo.
- Validar los datos al cargarlos.
- Crear una copia antes de migrar.
- Usar las carpetas lógicas del motor en lugar de rutas del sistema operativo.
- Exportar manualmente la semilla de una partida.
- Probar la expansión del espacio al añadir nuevos objetos o actos.

Estructura conceptual:

```text
profile.v1.json
settings.v1.json
partida-a.v1.json
```

La extensión exacta depende del motor. Si los datos son muy frecuentes o binarios, puede usarse otro formato, pero siempre con versionado.

## 11. Audio

- Buses separados para música, efectos y ambiente.
- Volúmenes independientes.
- Música adaptativa sencilla basada en vida, acto o tensión.
- Silenciar o pausar el audio al perder el foco.
- Respetar el modo de sonido del dispositivo cuando corresponda.
- Probar descodificación de audio en cada plataforma.
- Mantener efectos importantes en pocos canales para web.

## 12. Rendimiento

Objetivo inicial:

- Mantener 60 FPS en un dispositivo Android de gama media definido como referencia.
- Medir CPU, memoria, draw calls y tiempo de frame.
- Reutilizar proyectiles y objetos temporales.
- Usar atlas de texturas cuando sea conveniente.
- Limitar partículas y transparencias.
- Evitar muchas luces dinámicas.
- Crear habitaciones modulares.
- Definir una alternativa de resolución escalable si el dispositivo no alcanza el objetivo.

No optimizar de forma preventiva sin mediciones.

## 13. Contenido basado en datos

Los objetos, enemigos, recompensas y niveles deberían ser datos, no código repartido por el proyecto.

Cada objeto puede declarar:

- Identificador estable.
- Nombre y descripción.
- Rareza.
- Coste o condición de obtención.
- Efecto principal.
- Efectos pasivos.
- Interacciones.
- Restricciones.
- Sonidos.
- Iconos.
- Textos localizados.

Ejemplo conceptual:

```text
item_id: scissors
name: Tijeras de precisión
slot: weapon
base_effect: directional_cut
tags:
  - cutting
  - precision
synergies:
  - spring
  - thread
```

Esta estructura permite ajustar el balance sin reescribir el sistema de combate.

## 14. Semillas y generación reproducible

- Usar generadores pseudoaleatorios con semillas separadas.
- Separar el generador de salas, recompensas, combate y variantes.
- Guardar la semilla y la versión del algoritmo.
- Mantener un paso de simulación fijo cuando el motor lo permita.
- Registrar cambios de balance como una versión de reglas.
- Añadir una opción para repetir una semilla.

El objetivo es reproducir errores y comparar runs, no crear obligatoriamente un simulador de partida totalmente determinista.

## 15. Pruebas automatizadas

Prioridad para el núcleo:

- Tensión, dash, daño y estados.
- Generación de habitaciones.
- Validación de objetos y sinergias.
- Recompensas y progresión.
- Guardado, carga y migración.
- Compatibilidad de formatos de pantalla.
- Reglas de puertas y tutoriales.

La sensación de control, la animación y la lectura de enemigos se prueban con personas.

## 16. Integración futura de Kotlin Multiplatform

Si el motor elegido es libGDX:

1. Mantener el núcleo de reglas en Kotlin independiente de libGDX.
2. Definir modelos como `PlayerState`, `EnemyState`, `RoomState` y `RunState`.
3. Exponer funciones puras para tensión, daño, recompensas y generación.
4. Usar interfaces para renderizado, entrada, audio y almacenamiento.
5. Añadir un módulo KMP solamente si realmente se comparte lógica con otra aplicación o plataforma no cubierta por el backend.

Ejemplo:

```text
game-core/
  tension
  combate
  inventory
  synergies
  generation
```

No conviene introducir KMP simplemente para mostrar una pantalla técnica. Debe existir una razón medible de reutilización.

## 17. Pruebas multiplataforma obligatorias

Antes de anunciar una plataforma:

- Generar una compilación limpia.
- Ejecutarla en hardware real, no solo en un emulador.
- Probar rendimiento y memoria.
- Probar orientación, pantalla completa y áreas seguras.
- Probar suspensión, reanudación y pérdida de foco.
- Probar guardado tras cerrar la aplicación.
- Probar todos los controles disponibles.
- Probar audio con auriculares y altavoz.
- Probar assets de alta resolución.
- Probar una compilación de distribución, no solo una compilación de desarrollo.

## 18. Orden recomendado de adaptaciones

### Android

Primera prioridad debido al público inicial y a la financiación del proyecto.

### Escritorio

Primera validación técnica. Permite probar rápidamente si la lógica está desacoplada de Android y suele ayudar al desarrollo.

### iOS

Adaptar tiendas, firma, áreas seguras, entrada y requisitos vigentes. Probar siempre en dispositivo físico.

### Web

Hacer al final, salvo que exista un objetivo comercial específico. Medir:

- Tiempo de carga.
- Memoria.
- Rendimiento.
- Audio y desbloqueo por interacción.
- Persistencia.
- Compatibilidad de navegadores.
- Tamaño de descarga.

## 19. Decisión provisional

**Android primero, proyecto multiplataforma desde el inicio y exportación de escritorio como primera prueba de portabilidad.**

No iniciar todavía un motor propio con KMP. Primero comparar Godot y libGDX mediante un prototipo breve y seleccionar la ruta que mejor permita mantener el proyecto.

## 20. Fuentes técnicas consultadas

Consultadas el 24 de septiembre de 2026:

- Godot, índice de exportación: <https://docs.godotengine.org/en/stable/tutorials/export/index.html>
- Godot, consideraciones por plataforma: <https://docs.godotengine.org/en/stable/tutorials/platform/index.html>
- libGDX, generación de proyecto y backends: <https://libgdx.com/wiki/start/project-generation>
- Kotlin Multiplatform: <https://kotlinlang.org/docs/multiplatform.html>

Estas fuentes confirman las capacidades generales. Los requisitos concretos de publicación pueden cambiar y deben comprobarse cuando se prepare cada adaptación.
