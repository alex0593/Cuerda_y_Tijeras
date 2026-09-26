# D-005 — Compra directa en el suelo, sin objetos gratis y sin límite de huecos

- **ID:** D-005
- **Fecha:** 2026-09-26
- **Estado:** provisional
- **Área:** diseño / balance

## Problema
Tras el playtest H3 en el Honor (80 s, semilla `2136690460-v4`) la tienda no funcionaba como se esperaba: se abría con un panel que congelaba la partida (una ventana extra encima de la sala), los objetos caían gratis en todas las salas y por eso no había motivo para guardar hilos, los huecos limitaban la recogida («ya lo llevas», «slot lleno») y la llave no apareció ni una vez en toda la partida, así que no servía para nada.

## Opciones consideradas
1. Mantener el panel del taller y el catálogo completo, solo con mejor rótulo.
2. Compra directa en el suelo, sin paneles, pero conservando los objetos gratis de las salas.
3. Compra directa en el suelo + ningún objeto gratis + sin límite de huecos + la llave renombrada y con uso.

## Opción elegida
Opción 3, con `content/economy.json` como única fuente de números:

- `loot` bajado: combat 1–2, treasure 1–2, risk 2–3, workshop 1–2 (≈6–12 hilos por partida).
- `shop.offers = 2` de la pool exclusiva, con precio por rareza (común 5, especial 8).
- `shop.entry_cost = 6` para forzar la tienda sin alfiler.
- `shop_pool` sin `offers_with_key`: ya no hay tercera oferta.
- `version = 3` y `FORMAT_VERSION = 2` en el guardado.

## Motivo
La jugadora pidió literalmente «que no haya ninguna ventana extra», que los objetos estén en el suelo del taller con su precio y que se autocomprasen al pisarlos. Quitar los objetos gratis convierte la tienda en el único destino del botín, y quitar el límite de huecos (con la pool filtrando lo que ya llevas) acaba con los rechazos que se vieron en la partida. La llave pasa a llamarse **Alfiler** y se gasta al abrir la tienda, así que el botín de enemigos vuelve a importar.

## Consecuencias
- Ventajas: la compra es inmediata y legible, cada partida ofrece 2 objetos nuevos y el jefe regala uno del catálogo común; el alfiler tiene un uso claro.
- Desventajas: solo 3 objetos por partida (2 de tienda + 1 de jefe), así que las sinergias son más difíciles de formar; el panel de cambio de objetos queda fuera del flujo y se retira del juego.
- Riesgos: con 6–12 hilos por partida puede no llegar ni para un objeto especial; el nudo se corta con un tiro, así que disparar a la tienda sin querer cobra la entrada. Revisar en el playtest H3 con el recuento de hilos gastados.
- Plataformas afectadas: todas; la interfaz táctil es la que más lo nota.

## Revisión
- **Fecha de revisión:** después del playtest H3 completo
- **Resultado:**
- **Nueva decisión relacionada:** D-004 (sustituida), D-003
