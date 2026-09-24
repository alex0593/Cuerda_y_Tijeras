# 04. Enemigos y jefes

## 1. Principios de diseño

- Silueta reconocible a tamaño móvil.
- Ataque principal fácil de aprender.
- Debilidad o interacción interesante.
- Aviso claro antes de causar daño.
- Evitar daño aleatorio difícil de anticipar.
- Reutilizar animaciones sin que parezcan idénticas.
- Permitir más de una solución.

## 2. Enemigos del vertical slice

### Soldado de estaño

- Avanza en línea hacia la jugadora.
- Se detiene y levanta el escudo antes de cargar.
- El escudo puede romperse con dash, ataques por detrás o cortes.
- Al morir deja una llave, moneda o pieza de resorte.

### Caja de música

- Permanece en una zona y gira una llave.
- Emite notas en patrón circular.
- Tiene un núcleo brillante vulnerable.
- Silenciarla detiene temporalmente el patrón.
- Su derrota deja un consumible o una pieza de música.

### Oso de trapo

- Realiza una carga horizontal avisada.
- Choca contra obstáculos y deja rastro de relleno.
- Puede ralentizarse con magnetismo o hielo.
- Su segundo impacto abre una costura vulnerable.

## 3. Enemigos finales

### Bota de latón

- Rodea por las paredes.
- Rebota en cuatro direcciones.
- Puede atraerse con un imán.
- Deja chispas dañinas durante un tiempo corto.

### Tornillo saltador

- Avanza mediante saltos predecibles.
- Cambia de dirección al recibir un proyectil.
- Su salto se anuncia con un clic.
- Al morir fabrica una bala metálica.

### Sombra de títere

- Se vuelve casi invisible fuera de una luz.
- Reaparece al recibir un proyectil o durante el dash.
- Un objeto de luz u ojo revela su posición.
- No recibe daño cuando está completamente oculta.

### Caja espejo

- Copia durante tres segundos el último objeto de la jugadora.
- Dispara una versión débil de ese objeto.
- Puede romperse con un ataque cercano o de área.
- Su copia no genera el objeto real.

### Ojo de botón

- Gira y dispara un rayo breve.
- Cambia de objetivo cuando pierde de vista a la jugadora.
- Puede actuar como interruptor para ciertos objetos.
- Su ojo central es vulnerable.

### Cadena de piezas

No es un enemigo individual, sino una formación de piezas unidas. Cambia de configuración según la sala y exige romper una pieza concreta.

## 4. Jefe 1 — La Caja de Cero

### Función

Introducir patrones de proyectiles, música y rebobinado.

### Fase 1

- Gira y dispara en abanico.
- Una llave central puede golpearse para abrir una ventana.
- Al golpearla cambia la orientación del patrón.

### Fase 2

- Se divide en tres cajas pequeñas.
- Una reproduce el patrón de la primera fase.
- Otra dispara láseres de hilo.
- Otra crea notas en órbita.

### Interacción con objetos

Los objetos musicales pueden aumentar el daño y, al mismo tiempo, atraer proyectiles. Rebobinado es especialmente útil contra los patrones de la segunda fase.

## 5. Jefe 2 — El Oso de la Última Función

### Función

Introducir carga, control de espacio y protección.

### Fase 1

- Carga por la sala.
- Deja paredes de tela que reducen la visibilidad.
- Golpear la costura de su cabeza lo ralentiza.

### Fase 2

- Se divide en cuerpo y dos brazos.
- El cuerpo es invulnerable durante una ventana.
- Los brazos tiran de los objetos del escenario.
- Magnetismo puede atraerlos o crear una estrategia de control de espacio.

### Debilidad

- Requiere una combinación de velocidad o área.
- Las tijeras y proyectiles cortantes rompen las puntadas.

## 6. Jefe 3 — la Maestra de las Cuerdas

### Función

Combinar los elementos de los tres actos y cerrar la historia.

### Fase 1

- Se mueve como marioneta.
- Ataca mediante líneas de hilo controladas desde arriba.
- El jugador corta líneas para crear zonas seguras.

### Fase 2

- Usa sombras de los jefes anteriores.
- Invoca patrones pequeños aprendidos durante la partida.
- La sala cambia de manera visible.

### Fase 3

- Aparece la silueta de Lela manipulando a la Maestra.
- La tensión sube y baja rápidamente.
- Deben romperse tres puntos de anclaje.
- La última decisión utiliza recursos u objetos acumulados.

## 7. Tabla de amenazas

| Enemigo | Amenaza principal | Interacción interesante | Riesgo |
|---|---|---|---|
| Soldado de estaño | Carga frontal | Dash, corte, imán | Bajo |
| Caja de música | Proyectiles rítmicos | Música, rebobinado | Medio |
| Oso de trapo | Carga y espacio | Velocidad, imán, ralentización | Medio |
| Tornillo saltador | Posición | Empuje, imán, cortes | Bajo |
| Sombra de títere | Visibilidad | Luz, ojos, rebobinado | Medio |
| Ojo de botón | Rayo dirigido | Telas, proyectiles | Medio |
| Caja espejo | Copia de la combinación de objetos | Objeto contrario, rebobinado | Medio-alto |
| Cadena de piezas | Sala peligrosa | Dash, corte, área | Medio-alto |

## 8. Reglas de diseño de jefes

- Cada fase cambia algo más que la vida.
- Cada nueva fase utiliza una mecánica ya vista.
- El tiempo de aviso nunca es cero.
- Un cambio de patrón se identifica por sonido, movimiento o color.
- El jefe no depende solamente de una prueba de daño.
- La primera muerte debe aportar información.
- Los objetos siempre tienen una respuesta básica, aunque una combinación sea mejor.

## 9. Respuesta al derrotar enemigos

- Pequeña explosión de papel, tela o metal.
- Sonido distinto por material.
- Partículas de hilo, escamas o latón.
- Recurso con atracción magnética suave.
- Animación breve y estilizada.
- Indicador visual si el enemigo deja una sinergia.

## 10. Aparición de enemigos

- Máximo de tres enemigos del mismo tipo en el prototipo.
- Mantener espacio libre al entrar.
- Evitar colocar un enemigo grande detrás de otro.
- Los ataques deben ser compatibles con el espacio de la habitación.
- La dificultad modifica mezclas y tiempos, no solamente la velocidad.

## 11. Progresión de dificultad

- Acto I: ataques individuales y muy legibles.
- Acto II: combinaciones de dos tipos.
- Acto III: tres patrones, peligros ambientales y nuevas fases.
- El generador evita concentraciones de enemigos pesados en salas pequeñas.

## 12. Adaptaciones futuras

- Enemigos que reflejan proyectiles.
- Variantes por acto.
- Enemigos que solo se mueven bajo una luz.
- Enemigos que se dividen al rebobinar.
- Enemigos que copian un objeto.

Estas variantes solo deben entrar después de validar el conjunto base.

## 13. Checklist de enemigo

- [ ] Se reconoce a tamaño móvil.
- [ ] Su ataque se entiende en una partida de prueba.
- [ ] Tiene al menos una interacción o debilidad.
- [ ] La animación no oculta el aviso.
- [ ] Funciona en la sala más pequeña.
- [ ] Puede derrotarse sin un objeto obligatorio.
- [ ] Su derrota aporta algo más que un número.
