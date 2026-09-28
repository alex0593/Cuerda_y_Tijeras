# 07. Niveles y generación

## 1. Estructura espacial

Cada acto se compone de un grafo de habitaciones. Las habitaciones pueden ser:

- Combates.
- Riesgos.
- Cofres.
- Bancos de reparación.
- Habitaciones de historia.
- Puerta especial.
- Jefe.

La jugadora ve un mapa abstracto del camino, no un minimapa detallado que revele todas las habitaciones de antemano.

## 2. Estructura de la partida

El vertical slice es **un mapa navegable de 9 salas en rejilla 3x3** (D-006), no un flujo lineal
de 7 salas. La jugadora camina por el mapa, cruza puertas, puede volver a las salas que ya
limpió y encuentra las que no ha visto. Todas las salas conservan su estado.

- Inicio y jefe van en **esquinas opuestas**: cruzar el mapa es la decisión de ritmo.
- El taller se sortea **a dos pasos o más de la entrada**, para que ir a comprar tensione algo.
- Las 6 salas libres se reparten barajadas con la semilla: 3 combates, 1 tesoro y 2 riesgos.
- Las puertas están **cerradas hasta limpiar la sala** y se quedan abiertas para siempre.
- La partida termina al **recoger el objeto que suelta el jefe** (§12.1).

Propuesta de actos (sigue pendiente de validar con la duración real):

- Acto I: 6–8 habitaciones y un jefe.
- Acto II: 7–10 habitaciones y un jefe.
- Acto III: 8–12 habitaciones y un jefe.
- Tiempo total objetivo: 10–15 minutos.

El número de habitaciones debe ajustarse según la duración real de las salas, no solo según el tiempo de caminar.

## 3. Tipos de habitación

### Sala de combate

- Enemigos y cobertura.
- Se limpia para abrir puertas.
- Puede tener un peligro de área.

### Sala de riesgo

- Una recompensa importante.
- Un peligro claramente anunciado.
- Opción de pasar o entrar.

### Sala del tesoro

- Cofre o herramienta.
- No necesita combate, pero puede tener una trampa.

### Sala del taller

- Permite cambiar un objeto o comprar una reparación.
- Solo aparece una vez cada pocas habitaciones.

### Sala secreta

- Se encuentra usando una llave, imán, sombra o pista.
- Recompensa de objeto o historia.

### Sala de historia

- Mecanismos, objetos y notas.
- No debe ser obligatoria para terminar el acto.

## 4. Plantillas de sala

La generación utiliza plantillas con zonas validadas:

- Sala abierta.
- Sala en cruz.
- Pasillo con cobertura.
- Sala circular.
- Dos plataformas separadas.
- Sala con columna central.
- Sala de entrada segura.
- Arena de jefe.

Cada plantilla define:

- Anchura y altura.
- Zonas de aparición.
- Puntos de cobertura.
- Zonas de peligro.
- Puertas.
- Iluminación.
- Límite de enemigos.
- Objetos y etiquetas permitidas.

## 5. Generación de una partida

Algoritmo del vertical slice (`core/room_generator.gd`, `GENERATOR_VERSION = 7`):

1. Crear la rejilla 3x3 de celdas; cada celda es una sala de **1728x972** (§5.2).
2. Fijar el inicio en la esquina (0,0) y el jefe en la opuesta (2,2).
3. Barajar con la semilla las celdas libres y colocar el taller en la primera que esté a dos
   pasos o más de la entrada.
4. Repartir las 6 salas libres (3 combates, 1 tesoro, 2 riesgos) barajadas con la semilla.
5. Asignar una plantilla compatible y colocar enemigos según el presupuesto de dificultad.
6. Calcular las puertas: cada sala conecta con sus vecinas de la rejilla.
7. Sortear el botín de hilos, la pool de la tienda (taller) y el objeto del jefe.
8. Validar el mapa entero y cada sala: cobertura de la rejilla, esquinas fijas, puertas
   simétricas, tipos de sala y precios.
9. Guardar la semilla y la versión del generador.

La baraja usa el generador con semilla de la partida, **no** el aleatorio global: con la misma
semilla el mapa es idéntico.

No se debe construir una habitación generada sin comprobar que la jugadora tiene una ruta segura.

### 5.1 Reglas del mapa

- Las puertas de una sala están cerradas hasta limpiarla; al abrirse, se quedan abiertas.
- Las salas **no se destruyen** al salir: enemigos muertos, botín sin recoger y tienda abierta
  se conservan. Volver atrás nunca castiga ni regona.
- El contenido de una sala (enemigos, hilos, taller) se monta la **primera vez que se entra**,
  con lo que la jugadora lleve en ese momento, para que la pool nunca repita lo ya recogido.
- La jugadora es **una sola** en todo el mapa y la cámara la sigue.
- La jugadora **aparece en el centro de la sala de inicio**: las esquinas de la pantalla las
  cubren los joysticks táctiles, y aparecer debajo de uno hace que no se vea.
- La jugadora se dibuja **por encima del suelo** de la sala (`PLAYER_Z` en `game.gd`). Como es
  hija del mapa y no de la sala, el orden de hermanos la coloca la última, pero el z_index lo
  deja a salvo de que alguien reordene el árbol.

### 5.2 Tamaño de sala y encuadre de cámara

La sala mide **1728x972** y su interior está diseñado en 960x540: el nodo de la sala lleva un
escalado de 1,8, así que una sala más grande no obliga a rehacer la colocación de muros,
cobertura, puertas, botín y taller.

**Regla: la sala tiene que ser más grande que el viewport en los dos ejes.** Si no, la cámara no
tiene margen y los límites del mapa empujan a la jugadora hasta el borde de la pantalla en
cuanto se acerca a un muro. Con el flujo lineal de una sola sala no se notaba; al abrir el mapa
salió enseguida.

El viewport no es el que parece. Con `window/stretch/aspect = "expand"` Godot **conserva el alto**
(540) y ensancha el ancho, así que en un móvil panorámico de 2412x1080 el viewport es
**1206x540**, no 960x430. Cualquier cálculo de encuadre tiene que hacerse sobre
`get_viewport_rect().size` en tiempo de ejecución, nunca de la proporción del diseño.

El zoom se calcula en `_fit_camera()` a partir del viewport real, con un tope de 1,0 para no
alejarse más de la cuenta. Se acerca lo justo para que la jugadora ocupe alrededor del **5 % del
alto de la pantalla**: si la sala y el viewport casi coinciden, la jugadora aparece con media
pantalla de tamaño.

Los enemigos **no** se escalan con la sala (`scale = 1/SCALE`): si crecieran, el combate
cambiaría sin tocar el balance. La jugadora tampoco crece, por el mismo motivo; lo que sube es
su velocidad, de 220 a 260, para que cruzar una sala un 80 % más grande no alargue la partida
(4,4 s en vez de 7,9 s por sala).

## 6. Presupuesto de dificultad

Costes aproximados por enemigo:

- Soldado de estaño: 1.
- Caja de música: 2.
- Oso de trapo: 3.
- Sombra de títere: 2.
- Cadena de piezas: 3.

Una sala inicial utiliza un presupuesto de uno o dos puntos. Las salas de riesgo pueden utilizar un presupuesto superior, pero deben avisar claramente. La dificultad final no se decide solo por la cantidad de enemigos.

## 7. Reglas de seguridad

- La primera habitación no debe contener una sorpresa mortal.
- Siempre existe un espacio de recuperación después de un peligro.
- Las puertas de salida no quedan bloqueadas por un enemigo.
- No colocar un proyectil inicial sin aviso.
- Evitar más de dos enemigos pesados en una sala pequeña.
- No usar una combinación de objetos obligatoria para superar a un solo enemigo.
- El grafo debe tener al menos una ruta alternativa después del primer jefe.

## 8. Elección de puertas

Cada puerta puede mostrar:

- Icono de peligro.
- Recompensa probable.
- Llave o requisito.
- Efecto ambiental.

La información debe ser suficiente para elegir, no para resolver toda la partida. La primera partida puede mostrar iconos; las repeticiones pueden revelar más información.

## 9. Habitaciones de riesgo

Ejemplos:

- Enemigos extra a cambio de un objeto.
- Un cofre que requiere una llave.
- Un jefe opcional que suelta una mejora.
- Una puerta que consume tensión para abrirse.
- Un peligro de láseres con una zona segura.
- Una sala cuyas puertas permanecen cerradas hasta limpiar a los enemigos.

Cada riesgo debe tener una alternativa viable.

## 10. Colocación de enemigos

- Entrada con un segundo de margen.
- Enemigos de apoyo lejos de los enemigos pesados.
- Avisos que no se superpongan de forma ilegible.
- Un enemigo de área no debe tapar toda la pantalla.
- La posición debe permitir al menos una salida.
- Los objetos de atracción no deben acercar involuntariamente a un enemigo pesado.

## 11. Recompensas

Tipos:

- Objeto.
- Mejora de vida.
- Carga de rebobinado.
- Semilla de bonificación.
- Llave.
- Pieza de historia.
- Pieza cosmética.
- Aumento de capacidad de tensión.

La primera recompensa debe ser útil y fácil de entender.

## 12. Economía de la partida

La economía no necesita una moneda global compleja. Puede utilizar:

- Hilos: moneda de la partida.
- Perfiles: moneda permanente mínima.
- Claves: acceso temporal.
- Engranajes: mejoras pequeñas.
- Fragmentos: desbloqueos cosméticos y objetos.

Evitar que una moneda permanente convierta el combate en un sistema de números.

### 12.1 Hilos (vertical slice)

Los Hilos son la moneda de la partida y se gastan **solo** en el taller. Todo el balance vive en `content/economy.json`; ninguna cifra está en escenas ni en scripts.

- **Botín en el suelo.** Cada sala deja un rango de hilos recogibles, indicado por su tipo de sala:

  | Sala | Hilos |
  | --- | --- |
  | start | 0 |
  | combat | 2–3 |
  | treasure | 2–3 |
  | risk | 3–4 |
  | workshop | 2–3 |
  | boss | 0 |

- **Ningún objeto gratis.** Las salas ya no regalan objetos: solo dejan hilos. Los objetos salen de **dos sitios** (D-005): el **suelo del jefe** y la **tienda del taller**.
- **Botín de jefe.** La Caja de Cero **siempre** suelta un objeto al morir, distinto del arma inicial, generado como `boss_drop` en la semilla y fuera de la pool del taller: lo especial se compra y lo común lo regala el jefe. **Recoger ese objeto cierra la partida con victoria**; el resumen sale entonces mismo.
- **Alfileres.** Recurso que cae de los enemigos y se gasta para abrir la tienda del taller (§13).

Los precios son por rareza, no por objeto: **común 4, especial 8, rara 12**. La reparación cuesta **5 hilos** y cura **1,0 segmento**; forzar la tienda sin alfiler cuesta **4 hilos**. Los de especial y rara no se bajaron a propósito: los objetos raros tienen que seguir siendo raros para que comprar sea una decisión (D-008).

El **consumible no lo suelta el jefe**: se compra en el taller, como el resto. Ganar no puede
consistir en recoger una bobina de reparación. La pool del jefe excluye el arma inicial, la pool
del taller y los consumibles; `validate_room()` lo denuncia y `validate_content.py` comprueba que
todo objeto del catálogo tenga alguna fuente.

### 12.2 Lo que dice la medición (200 semillas)

Medido con `tools/measure_run.gd`. Los valores de `content/economy.json` **no** están puestos a ojo:
salen de este arnés, y con los que había antes (botín 1–2 por sala, entrada 6, común 5) se
midieron y se ajustaron (D-008).

**La cifra que decide si el taller sirve de algo no es la de la partida entera, sino la del
momento en que se llega al taller**, que está a dos pasos de la entrada:

| Al llegar al taller por primera vez | Antes | Ahora |
| --- | --- | --- |
| hilos que llevas | 2–17 (media 8,4) | 4–23 (media 12,5) |
| puede abrirlo | 84 % | **100 %** |
| puede comprar 1 objeto | 53 % | **85 %** |
| puede comprar 2 objetos | 18 % | **49 %** |

Con el mapa entero limpio se compran 3,3 objetos de media y se forman **0,5 sinergias**.

> Una versión anterior de este apartado afirmaba que «la tienda abre justo y no queda para comprar
> nada». Era una lectura equivocada, hecha con la curva de profundidad en vez de con la cifra
> directa. El arnés mide ahora las dos cosas por separado, precisamente para que no se confuse
> el total de la partida con lo que se puede gastar cuando toca.

**Lo que la medición deja claro y no se ha tocado:** las sinergias no son un problema de precios.
Con cinco combinaciones de precios probadas (`tools/sweep_economy.py`), la media de sinergias se
queda entre 0,4 y 0,5 por partida y no sube de ahí. Las seis sinergias reales necesitan **un objeto
del taller más uno del jefe**, y el jefe suelta exactamente uno: ese es el techo. Subirlo es una
decisión de diseño (que el jefe suelte dos, o que alguna sinergia se forme con dos objetos del
taller), no un número. Está en D-008.

## 13. Tienda del taller

El taller es una sala única y es **la única tienda** de la partida. No hay paneles ni ventanas: la compra es directa en el suelo (D-005).

- **Pool exclusiva** (`shop_pool` en `content/economy.json`): `scissors_precision`, `music_box`, `glass_eye`, `iron_magnet`, `toy_glue` y `repair_coil`. Ninguno de ellos cae gratis en ninguna sala ni en el botín del jefe: solo se compran aquí.
- **Dos ofertas.** Cada partida sortea `shop.offers` (2) objetos de esa pool con la semilla. Se exponen en el mostrador con su nombre y su precio en hilos.
- **Sin repetir lo que ya llevas.** Al entrar en la sala se retiran de las ofertas los objetos que ya tienes y se repone con la semilla de la sala, así que siempre hay 2 opciones nuevas que coger.
- **La cerradura es un nudo.** El mostrador está cerrado con un nudo que se **corta con un tiro**: el mismo mecanismo de disparo que usan todas las salas. No hace falta ningún artículo para pasar.
- **Entrar no es gratis.** Cortar el nudo cobra la entrada: un **alfiler** (botín de enemigos) o, si no tienes, **forzarla con hilos** (`shop.entry_cost`). Sin ninguno el nudo no se corta y no se puede comprar, pero nunca se bloquea el paso.
- **Compra al pisar.** Cada oferta del suelo se compra al tocarla si hay hilos suficientes; si faltan, se queda en el suelo y puedes volver. La reparación de vida es otra oferta en el suelo con su precio.

Reglas de la compra:

- Los hilos solo se descuentan cuando el objeto acaba entrando.
- Un objeto ya equipado no se compra dos veces; los consumibles sí se reponen hasta su máximo de cargas.
- Con la vida llena la reparación no está disponible.
- Sin límite de huecos: todo lo que aparece se puede llevar, y la tijera de precisión es una mejora que se aplica al tenerla.

## 14. Salas de jefe

- Entrada segura.
- Arena con espacio para dash.
- Avisos grandes.
- Peligros ambientales controlables.
- Una estrategia válida con el ataque inicial.
- No depender de un consumible guardado por error.

### 14.1 La Caja de Cero

La Caja de Cero (120 de vida, 6 de presupuesto) tiene **dos fases** y un **contraataque** legible:

- **Fase 1 (100 %–50 %):** abanico de 5 cortes dirigidos a la jugadora, cada 1,6 s.
- **Fase 2 (por debajo del 50 %):** el mismo abanico más una lluvia de 3 cortes hacia abajo, cada 1,2 s. El cambio se anuncia con un destello y tiñe la caja de rojo.
- **Aviso previo:** antes de cada ráfaga la caja se queda quieta 0,6 s y la **llave central** crece y se enciende. Ese es el aviso: donde hay aviso, hay contraataque.
- **Contraataque:** golpear la caja mientras avisa **cancela la ráfaga**, deja 1,4 s de calma y hace el daño ×1,5. Fuera del aviso el daño es el normal.
- La **llave central** es su debilidad declarada (`content/enemies.json`): mientras está encendida, el jefe está abierto.
- Al morir suelta siempre un objeto del catálogo (`boss_drop` de la semilla), distinto del arma inicial y fuera de la pool del taller.

El timings son valores de prueba, no balance final: revisar en el playtest H3.

## 15. Acto I — La Sala de las Cajas

Objetivos:

- Enseñar puertas.
- Enseñar cobertura.
- Enseñar una sinergia.
- Introducir dos o tres enemigos.
- Terminar con La Caja de Cero.

Secuencia sugerida:

1. Inicio seguro.
2. Combate de cajas.
3. Cofre con llave.
4. Sala de riesgo.
5. Combate con sombra.
6. Mini-taller.
7. Jefe.

## 16. Acto II — La Caja de Música

Objetivos:

- Introducir rebobinado.
- Combinar imanes con enemigos.
- Introducir peligros rítmicos.
- Terminar con El Oso de la Última Función.

Incluir combinaciones de salas, una sala circular con patrones, una sala secreta, un combate de caja espejo y el jefe final del acto.

## 17. Acto III — El Teatro de las Sombras

Objetivos:

- Combinar todos los sistemas.
- Usar sombras y líneas de hilo.
- Hacer que la jugadora use rebobinado de forma significativa.
- Terminar con la Maestra de las Cuerdas.

## 18. Semilla y reproducibilidad

Una semilla incluye:

- Versión del generador.
- Grafo.
- Tipos de habitación.
- Plantillas.
- Enemigos.
- Recompensas.
- Variantes de decorado.
- Posiciones iniciales.

El objetivo no es que cada partida sea idéntica, sino que una semilla pueda reproducirse para pruebas y soporte.

## 19. Curación del contenido

Aunque el nivel se genere, parte del contenido debe ser fija:

- Jefes.
- Tutoriales.
- Primeras habitaciones.
- Habitaciones de historia.
- Salas de recompensa.
- Actos con identidad propia.

La generación debe aportar variedad, no borrar la sensación de que existe un mundo diseñado.

## 20. Checklist de sala

Antes de aprobar una plantilla:

- [ ] La entrada es segura.
- [ ] Existe una ruta visible de salida.
- [ ] Los enemigos pueden leerse.
- [ ] El objeto principal tiene una función clara.
- [ ] El peligro no cubre más de lo necesario.
- [ ] La sala funciona con el ataque inicial.
- [ ] No exige un consumible específico.
- [ ] Se puede generar de forma reproducible.
- [ ] Funciona en el formato de pantalla más estrecho.
- [ ] Se ha probado con distintos objetos.

## 21. Balance de riesgo

Para cada sala nueva anotar:

- Dificultad percibida.
- Muertes por enemigo.
- Tiempo medio de limpieza.
- Porcentaje de uso de dash.
- Porcentaje de uso de rebobinado.
- Objetos que más se eligen.
- Rutas abandonadas.

Estos datos ayudan a detectar una sala visualmente interesante pero matemáticamente injusta.
