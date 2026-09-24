# 01. Concepto y pilares

## 1. Concepto central

**Cuerda y Tijeras** es un roguelite de acción en el que una muñeca de cuerda despierta en un taller de juguetes que no logra concluir una representación. Todos los objetos parecen repetir las órdenes de una última función y las puertas solo se abren cuando la obra alcanza el ritmo correcto.

La protagonista utiliza piezas del taller para sobrevivir. No encuentra armas fantásticas: improvisa con tijeras, resortes, imanes, hilos, botones, llaves y cajas de música. El jugador aprende a combinar esas piezas durante la partida.

## 2. Propuesta de valor

La experiencia debe ofrecer:

- Combate inmediato y controlado.
- Decisiones sobre cuándo atacar, moverse o rebobinar.
- Objetos que crean estrategias claramente diferentes.
- Habitaciones con riesgos y recompensas.
- Una atmósfera cálida, táctil e inquietante.
- Partidas que caben en una sesión móvil.
- Una arquitectura que permita añadir otras plataformas después.

## 3. Fantasía del jugador

> «Soy una pequeña muñeca, pero puedo convertir las herramientas de este taller en un equipo inesperado».

El jugador debe sentirse:

- Ágil y capaz de improvisar.
- Curioso por los objetos y sus combinaciones.
- Presionado por una energía que debe administrarse.
- Amenazado por ataques que puede aprender a leer.
- Responsable de las decisiones que ponen en riesgo la partida.

## 4. Pilares

### Pilar 1 — La cuerda como energía

Disparar, hacer dash y usar habilidades consume tensión. La gestión de este recurso crea ritmo sin obligar al jugador a permanecer quieto.

### Pilar 2 — Objetos que transforman el combate

Un objeto no debe ser solamente un aumento de daño. Puede modificar el disparo, la movilidad, la defensa, las interacciones con enemigos o la generación de recursos.

### Pilar 3 — Improvisación legible

Las combinaciones deben poder comprenderse mediante iconos, sonido, color y una demostración sencilla:

- Imán y metal significan atracción.
- Resorte y tijeras significan corte con impulso.
- Música e hilo significan notas orbitales.
- Luz y sombra significan revelar enemigos.

### Pilar 4 — Teatro de títeres

El juego se presenta como una obra de títeres. Esto permite utilizar siluetas, recortes, pivotes, texturas de papel y efectos de sombra sin depender de sprites complejos.

### Pilar 5 — Partidas breves y rejugables

Una partida debe durar entre 10 y 15 minutos. La repetición ofrece nuevas combinaciones, rutas y decisiones, no solamente una lista de tareas repetitivas.

### Pilar 6 — Android primero, diseño portable

El diseño está pensado para pantalla táctil y sesiones cortas. La arquitectura evita dependencias directas de Android para permitir futuras adaptaciones.

## 5. Referencias de diseño

Se pueden estudiar las siguientes decisiones, nunca sus recursos ni su contenido exacto:

- *The Binding of Isaac*: estructura de habitaciones y lectura de objetos.
- *Enter the Gungeon*: claridad de patrones enemigos y respuesta audiovisual.
- *Dead Cells*: animación, respuesta de combate y ritmo.
- *Luck be a Landlord*: interacciones de objetos sencillos.
- *Brotato*: arenas breves y variedad de combinaciones.
- *Badland*: lectura visual y controles táctiles.

## 6. Límites de originalidad

No se deben copiar:

- Personajes, nombres, arte, música, sonidos o animaciones de otros juegos.
- Listas de objetos con funciones equivalentes exactas.
- Jefes que solo cambian de nombre o color.
- Distribuciones de salas o combinaciones idénticas de una obra existente.
- Marcas, logotipos o lenguaje de las tiendas.

Las referencias sirven para entender principios de diseño. La identidad final debe ser propia.

## 7. Público objetivo

### Público principal

- Jugadores de roguelites de acción.
- Jugadores que disfrutan las combinaciones de objetos.
- Personas que juegan en sesiones cortas.
- Fans de títeres, juguetes antiguos, papel, mecanismos y terror corporal ligero.

### Edad orientativa

Diseñar para **13+**. Puede incluir tensión, transformaciones estilizadas y humor negro, pero debe evitar violencia gráfica realista, sexualización infantil o material que produzca rechazo en una tienda familiar.

## 8. Identidad visual

- **Paleta:** papel crema, carbón, hilo rojo, metal dorado y tinta azul.
- **Formas:** círculos, puntadas, botones, resortes y hojas afiladas.
- **Luz:** fondo cálido y siluetas oscuras en primer plano.
- **Movimiento:** rebotes pequeños de muelle, inercia de tela y cortes bruscos.
- **Sonido:** cuerda, madera, metal, tela y cajas de música.
- **Interfaz:** etiquetas cosidas, botones y barras de hilo.

## 9. Rasgos diferenciales

1. La tensión limita todas las acciones.
2. Rebobinar cambia decisiones de posicionamiento y supervivencia.
3. Los objetos del mundo se convierten en herramientas de combate.
4. La estética de títeres crea una identidad visual clara.
5. La historia se distribuye mediante objetos y comportamientos ambientales.
6. El juego funciona completamente local en la primera versión.
7. La estructura técnica no depende de una sola plataforma.

## 10. Objetivos que no forman parte de la primera versión

- Multijugador.
- Servidor o cuentas.
- Mundo abierto.
- Generador de interiores completamente libre.
- Motor 3D.
- Editor de niveles para jugadores.
- IA obligatoria para jugar.
- Decenas de personajes.
- Finales múltiples.
- Sistemas de cajas de botín.

## 11. Riesgos de diseño

### Demasiadas combinaciones

Puede provocar indecisión y parálisis. Solución: ocho objetos y seis a diez relaciones en el prototipo; ampliar solo después de probar cuáles resultan divertidas y útiles.

### Objetos sin función individual

Un objeto no debe depender completamente de otro. Cada objeto tiene un efecto básico y la sinergia lo transforma.

### Rebobinado demasiado poderoso

Puede eliminar los desafíos. Solución: duración corta, cargas limitadas y ningún rebobinado completo de vida o progreso.

### Arte difícil de mantener

Solución: guía visual, piezas modulares, prueba de estilo antes de producción y paleta limitada.

### Partida demasiado larga

Solución: actos cortos, una recompensa por habitación y un jefe cada cinco o siete salas.

### Falta de orientación

Solución: tutorial contextual, primera habitación sencilla y mensajes breves.

## 12. Criterios de éxito del concepto

El concepto funciona si el prototipo cumple lo siguiente:

- Una jugadora unfamiliar comprende los controles en menos de 30 segundos.
- Entiende la función de la tensión en menos de un minuto.
- Rebobinar resulta útil sin trivializar el combate.
- Tres objetos producen estrategias claramente distintas.
- Una partida se completa entre 5 y 10 minutos.
- El arte provisional transmite la identidad del juego.
- La mayoría de quienes prueban el juego quieren jugar otra partida.

## 13. Promesa del juego

**Cuerda y Tijeras** es un pequeño roguelite de acción e ingenio, construido con resortes, tijeras, papel y una estrella mal enrollada, donde cada objeto aparentemente ordinario puede convertirse en una respuesta extraordinaria.
