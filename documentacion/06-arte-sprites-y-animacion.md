# 06. Arte, sprites y animación

## 1. Objetivo visual

**Cuerda y Tijeras** se presenta como un teatro de títeres visto desde arriba. El jugador debe leer la acción por siluetas, contrastes, movimientos y colores aunque los objetos no tengan detalles fotorrealistas.

La dirección reduce la dependencia de sprites complejos sin convertir el juego en una colección de recursos provisionales.

## 2. Principios

- Silueta antes que detalle.
- Movimiento antes que textura.
- Contraste antes que decoración.
- Dos o tres colores de acento por elemento importante.
- Materiales sugeridos: papel, madera, latón, hilo y tela.
- Las sombras deben ser funcionales, no solo estéticas.
- Los ataques enemigos deben leerse más rápido que los efectos decorativos.

## 3. Dirección de arte provisional

- **Fondo:** papel crema o madera descolorida.
- **Títeres:** carbón oscuro con bordes ligeramente cálidos.
- **Jugadora:** marfil, hilo rojo y un detalle azul de tinta.
- **Peligro:** rojo desaturado o bordón dorado para evitar confusión.
- **Objetos:** pequeños acentos de latón y color.
- **Interfaz:** etiquetas cosidas, botones y papel.

La paleta exacta se cerrará después de una prueba de contraste en un dispositivo Android.

## 4. Sprites, recortes y animación

### Opción recomendada

Usar piezas 2D recortadas y pivotes, no una lámina enorme de fotogramas.

Ejemplo de Lela:

```text
cabeza
torso
brazo-izquierdo
brazo-derecho
falda
pierna-izquierda
pierna-derecha
tijeras
costura-interior
```

Ventajas:

- Las piezas se pueden reutilizar entre animaciones.
- Se pueden cambiar armas y accesorios.
- Es más fácil mantener una coherencia visual.
- Permite reducir el número de imágenes necesarias.
- Puede funcionar bien en escritorio, móvil y web.

### Herramientas según motor

- Godot: nodos 2D, `Skeleton2D`, `Polygon2D`, `AnimatedSprite2D` o esqueletos de recorte.
- libGDX: piezas con pivotes, atlas, Spine si se compra la licencia correspondiente o un sistema propio de recorte.
- No utilizar Spine si su licencia no encaja con el presupuesto o la distribución; comprobarlo antes de producir arte final.

## 5. Resolución y escala

Propuesta inicial:

- Lienzo base de diseño: `1920×1080` o `960×540` con archivos de origen a mayor resolución.
- Cámara de juego: `640×360` escalado a la pantalla.
- Lela: aproximadamente `42×56` unidades de diseño.
- Enemigo pequeño: `28–40` unidades.
- Enemigo mediano: `48–72` unidades.
- Jefe: `96–160` unidades.
- Interfaz independiente de la escala de los sprites.

La cifra exacta se decide con una prueba de lectura. Más grande no significa más legible en móvil.

## 6. Dirección de la animación de Lela

El juego no necesita ocho direcciones de animación si se usa una composición simétrica.

Propuesta:

- Arriba.
- Abajo.
- Lado, con inversión horizontal para el lado contrario.

Animaciones mínimas:

- Reposo: cuatro fotogramas.
- Caminar: seis fotogramas.
- Dash: tres poses.
- Corte: cuatro poses, usando el brazo y las tijeras como piezas.
- Rebobinado: destello, eco visual y tres o cuatro poses.
- Daño: dos poses.
- Muerte: cinco poses.

No crear una animación independiente para cada objeto. Las armas se montan sobre una pose base.

## 7. Enemigos y jefes

Cada enemigo tiene una prueba de silueta:

1. Verlo en negro sobre fondo crema.
2. Reducirlo al tamaño real de móvil.
3. Mostrarlo durante dos segundos sin sonido.
4. Preguntar qué hace y por qué se le debe temer.

Si no se entiende, hay que cambiar la silueta, el color o el movimiento antes de añadir textura.

### Variaciones

- Paletas alternativas.
- Accesorios de una o dos piezas.
- Variaciones de escala y postura.
- Avisos de color y movimiento.
- Variantes que cambian el patrón, no la lógica de recepción de daño.

No crear un sprite nuevo por cada sala. Una habitación puede combinar enemigos existentes con objetos de decorado.

## 8. Jefes

Cada jefe necesita:

- Silueta.
- Pose de reposo.
- Aviso de ataque.
- Ataque.
- Reacción al daño.
- Fase dos.
- Muerte o destrucción.

La cantidad de animación de un jefe depende de su tiempo en pantalla. Un jefe de cinco minutos necesita más detalle que un enemigo de diez segundos.

## 9. Escenarios

### Capas

1. Fondo pintado.
2. Decorado de fondo.
3. Suelo jugable.
4. Obstáculos con sombra.
5. Títeres y enemigos.
6. Proyectiles.
7. Efectos.
8. Primer plano, como cortinas y polvo.
9. HUD.

### Reglas visuales

- Las zonas jugables no deben ocultarse con decoración.
- Las puertas deben ser reconocibles por una luz, forma o sonido.
- Las trampas y peligros deben tener un borde contrastado.
- Los objetos interactivos no deben confundirse con decoración.
- La escena debe seguir siendo legible cuando la relación de pantalla es alta.

## 10. Objetos de decorado

Propuesta inicial:

- Caja abierta.
- Caja de música.
- Llave.
- Resorte.
- Carrete.
- Tijeras.
- Lámpara.
- Baúl.
- Mesa de trabajo.
- Cortina.
- Tensor de tela.
- Silla.
- Relleno de oso.

Se pueden combinar variantes de color, escala y orientación para dar variedad.

## 11. Interfaz

### Pantallas

- Menú principal.
- Nueva partida.
- Selección inicial.
- Partida.
- Pausa.
- Resumen de partida.
- Colección de objetos y sinergias.
- Opciones.
- Créditos.

### Elementos

- Botones con forma de botón o etiqueta cosida.
- Barra de vida con hilo rojo.
- Barra de tensión con muelle.
- Cargas de rebobinado como relojes de resorte.
- Minimapa opcional solo si no tapa la acción.
- Textos breves y no bloqueantes.

Las cifras importantes deben tener icono además de color.

## 12. Color, contraste y accesibilidad

- No usar rojo y verde como única diferencia.
- Añadir formas o iconos a estados de peligro.
- Ofrecer un modo de alto contraste.
- Respetar la opción de reducir destellos.
- Evitar texto pequeño para tutoriales.
- Comprobar el juego sobre fondos claros y oscuros.

## 13. Flujo de producción del arte

### Fase A — Siluetas

- Fondos grises.
- Lela negra.
- Tres enemigos negros.
- Un jefe negro.
- Pruebas de tamaño y movimiento.

### Fase B — Prueba de estilo

- Paleta definitiva.
- Materiales.
- Una habitación.
- Un efecto de ataque.
- Una animación de jefe.
- Capturas en un dispositivo real.

### Fase C — Producción modular

- Recursos base.
- Variaciones.
- Objetos de decorado.
- Animaciones.
- Interfaz.
- Respuesta sonora.

### Fase D — Acabado

- Partículas.
- Luces.
- Transiciones.
- Texturas.
- Microanimaciones.
- Optimización.

No pasar a producción antes de aprobar las fases A y B.

## 14. Organización de archivos

```text
assets-source/
  characters/lela/
  characters/enemies/
  characters/bosses/
  environment/act-1/
  props/
  ui/
  vfx/
  audio/
  fonts/
```

En el motor:

```text
assets/
  characters/
  environment/
  props/
  ui/
  vfx/
  audio/
  fonts/
```

## 15. Nombres de archivo

Usar nombres estables y descriptivos:

```text
lela_idle_down_01.png
lela_walk_side_03.png
enemy_tin_soldier_telegraph.png
boss_music_box_phase2.png
act1_crate_open.png
ui_relic_button_hover.png
vfx_scissor_cut_01.png
```

Evitar espacios, acentos y números ambiguos. Mantener el mismo nombre lógico entre el archivo fuente y el importado.

## 16. Formatos de trabajo

- Fuente: PNG con transparencia o SVG para piezas vectoriales.
- Sprites: PNG importado en atlas o como piezas.
- Animaciones: datos del motor, no vídeos.
- Audio: WAV para fuentes; OGG o equivalente comprimido para ejecución.
- Fuentes: preferiblemente con licencia abierta y soporte Unicode.
- Documentación: ficha de recurso, autor, fuente y licencia.

## 17. Recursos provisionales

Los recursos provisionales deben ser deliberados:

- Círculos y rectángulos con nombres de depuración.
- Un color por entidad.
- Avisos con símbolos grandes.
- Colisiones visibles con una opción de depuración.
- Evitar que un recurso temporal parezca arte final cuando todavía no se ha aprobado.

## 18. Inteligencia artificial y recursos

La inteligencia artificial puede ayudar con:

- Conceptos.
- Láminas de referencia.
- Variaciones de color.
- Texturas experimentales.
- Ideas de fondos y atmósfera.

No se debe asumir que una imagen generada es automáticamente libre para uso comercial. Guardar:

- Prompt y herramienta.
- Fecha.
- Modelo o servicio usado.
- Resultado original.
- Licencia aplicable.
- Edición humana realizada.

No copiar prompts que pidan explícitamente la apariencia de artistas, juegos o personajes protegidos.

## 19. Contratar arte externo

Al encargar trabajo, definir:

- Silueta y referencia.
- Número de piezas.
- Formatos y dimensiones.
- Uso de piezas modulares.
- Archivos fuente editables.
- Licencia y transferencia de derechos.
- Reutilización en otras plataformas.
- Revisiones.
- Tabla de entregables.

No pedir sprites aislados sin pensar en la animación y la escalabilidad.

## 20. Criterios de aprobación de un recurso

- [ ] Se entiende en el tamaño real del juego.
- [ ] Encaja con la paleta y los materiales.
- [ ] No utiliza referencias protegidas.
- [ ] Tiene fuente, autoría y licencia registradas.
- [ ] Funciona en todos los formatos de pantalla previstos.
- [ ] Se puede exportar a las plataformas objetivo.
- [ ] Está optimizado o tiene un plan de optimización.
- [ ] Su animación no oculta ataques ni colisiones.

## 21. Mejor mitigación del problema de los sprites

La mejor solución no es dibujar más rápido, sino hacer que un solo recurso rinda más:

- Piezas reutilizables.
- Pivotes.
- Paletas alternativas.
- Escala.
- Siluetas.
- Objetos modulares.
- Simbología visual.
- Menos animaciones únicas.
- Más reutilización de poses.

El objetivo de arte del primer prototipo es validar lectura, no producir la versión final.
