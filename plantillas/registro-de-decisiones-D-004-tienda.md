# D-004 — Taller con pool propia, 2 ofertas a la vista y llave

- **ID:** D-004
- **Fecha:** 2026-09-26
- **Estado:** provisional
- **Área:** diseño / balance

## Problema
Al jugárselo en el Honor durante el playtest H3, la tienda no se leía como tienda: era una cajita marrón con un rótulo «tocar para entrar» en la esquina de la sala, un NPC con otra forma. Vendía el catálogo entero, así que no había motivo para guardar hilos ni para distinguir qué se compra aquí y qué se recoge gratis. Por otro lado las llaves caían de los enemigos y no se gastaban en ningún sitio.

## Opciones consideradas
1. Mantener la cajita y el catálogo completo, solo con mejor rótulo.
2. Sala-tienda de acceso automático: el panel se abre solo al entrar y se cierra para recoger la recompensa.
3. Pool de objetos exclusiva del taller, expuesta en la sala con su precio; catálogo acotado a esas ofertas y llave que abre una más.

## Opción elegida
Opción 3, con `content/economy.json` como única fuente de números:

- `shop_pool`: `scissors_precision`, `music_box`, `glass_eye`, `iron_magnet`, `toy_glue`.
- `shop.offers = 2` (a la vista) y `shop.offers_with_key = 3` (con una llave).
- `shop.key_cost = 6`; la reparación sigue en 6.

La sala de recompensa del taller **sigue regalando sus 3 objetos**; lo que está en la pool no se reparte gratis en ninguna otra sala ni en el botín del jefe.

## Motivo
El taller tiene que justificar que la jugadora se resigne a gastar el botín de toda la partida. Un stock propio, visible en la sala con precio, convierte la visita en una decisión en vez de en otro panel de catálogo. La segunda oferta se oculta tras una llave para darle uso a un recurso que ya existía sin gastarse, y se sortean las 3 de golpe para que abrir la tercera no cambie lo que hay (determinismo por semilla).

## Consecuencias
- Ventajas: el taller es reconocible como tienda, la moneda tiene un destino claro y cada partida enseña un stock distinto; el acceso es tocar la fila de ofertas, sin texto ni precisión fina.
- Desventajas: los 5 objetos de la pool dejan de estar en el botín gratis, así que los objetos especiales solo se obtienen comprando; el resto de salas reparten solo 4 objetos.
- Riesgos: con 2 ofertas sorteadas puede no salir nada que le interese a la jugadora; si nadie gasta hilos, el taller no aporta. Revisar en el playtest H3 con el recuento de hilos gastados.
- Plataformas afectadas: todas; la interfaz táctil es la que más lo nota.

## Revisión
- **Fecha de revisión:** después del playtest H3 completo
- **Resultado:**
- **Nueva decisión relacionada:** D-003
