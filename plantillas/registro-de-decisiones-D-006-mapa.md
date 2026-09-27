# D-006 — Mapa navegable de 9 salas en rejilla 3x3

- **ID:** D-006
- **Fecha:** 2026-09-26
- **Estado:** provisional
- **Área:** diseño / técnica

## Problema
El vertical slice era un flujo lineal: una sala cargada cada vez, una sola puerta a la derecha y
`room_index += 1` al cruzarla. La jugadora no podía recorrer el mapa, volver atrás ni encontrar
salas por su cuenta, y la tienda era una sala más de una lista ordenada. La petición fue
explícita: «que la tienda sea una sala sola y poder navegar en todo el mapa, que se generen salas
finitas y poder encontrar otras salas».

## Opciones consideradas
1. Flujo lineal con más salas y una sala secreta al final.
2. Grafo irregular de 8–12 salas sin rejilla, con conexiones orgánicas.
3. Rejilla 3x3 de 9 salas con todas las puertas abiertas.

## Opción elegida
Opción 3, con estas reglas:

- Rejilla de 9 salas de 960x540, inicio en (0,0) y jefe en la esquina opuesta (2,2).
- El taller se sortea a dos pasos o más de la entrada; las 6 salas libres son 3 combates,
  1 tesoro y 2 riesgos, barajados con la semilla.
- Las puertas están cerradas hasta limpiar la sala y se quedan abiertas para siempre.
- Las salas no se destruyen al salir: enemigos, botín y tienda conservan su estado.
- El contenido de cada sala se monta al entrar la primera vez, con el inventario de ese momento.
- La partida termina al recoger el objeto que suelta el jefe.

## Motivo
La rejilla se entiende sin explicación —siempre son 9 salas, siempre con las cuatro vecinas— y
cruzar el mapa se convierte en la decisión de ritmo de la partida. Mantener las salas vivas es lo
más simple para que nada se regene al volver atrás, que es justo lo que la jugadora pidió. Cerrar
las puertas hasta limpiar conserva el sentido del combate y evita correr por una sala llena de
enemigos.

## Consecuencias
- Ventajas: la tienda se elige cuándo visitarla, se pueden tantear rutas y el mapa deja de ser una
  lista; el objetivo (recoger el botín del jefe) es claro y visible en el suelo.
- Desventajas: la partida se alarga respecto a las 7 salas lineales; con 9 salas y 6 tipos libres
  hay más repetición de contenido; el jugador puede perderse o ir muy rápido.
- Riesgos: con 6 salas libres el botín por partida sube; la dificultad al poder elegir ruta puede
  desbalancearse. Revisar en el playtest H3 con el tiempo real y el recuento de salas visitadas.
- Plataformas afectadas: todas; la cámara que sigue a la jugadora es el cambio visual principal.

## Revisión
- **Fecha de revisión:** después del playtest H3 completo
- **Resultado:**
- **Nueva decisión relacionada:** D-005, D-003
