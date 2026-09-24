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

Propuesta inicial:

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

Algoritmo conceptual:

1. Crear un grafo con un número limitado de nodos.
2. Reservar un nodo inicial, un nodo de taller y un nodo de jefe.
3. Añadir conexiones con una o dos rutas alternativas.
4. Asignar el tipo de habitación según la distancia al jefe.
5. Asignar una plantilla compatible.
6. Colocar enemigos según el presupuesto de dificultad.
7. Colocar recompensas y puertas.
8. Validar que el recorrido sea transitable.
9. Ejecutar una simulación de tensión.
10. Guardar la semilla y la versión.

No se debe construir una habitación generada sin comprobar que la jugadora tiene una ruta segura.

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

## 13. Taller

El taller permite:

- Cambiar un objeto.
- Reparar vida a cambio de moneda.
- Obtener una pista.
- Vender un objeto.

En el prototipo puede ser un menú con un subconjunto de objetos. No hace falta una tienda grande.

## 14. Salas de jefe

- Entrada segura.
- Arena con espacio para dash.
- Avisos grandes.
- Peligros ambientales controlables.
- Una estrategia válida con el ataque inicial.
- No depender de un consumible guardado por error.

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
