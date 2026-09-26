# D-003 — Economía de hilos: taller y botín de jefe

- **ID:** D-003
- **Fecha:** 2026-09-25
- **Estado:** provisional
- **Área:** diseño / balance

## Problema
Los Hilos se generaban y se contaban en el HUD, pero no servían para nada: ninguna sala dejaba moneda garantizada en el suelo, el taller era una sala de recompensa más y el jefe no soltaba ningún objeto. La jugadora no podía decidir qué objeto llevaba, solo aceptar las tres ofertas aleatorias de cada sala.

## Opciones consideradas
1. Subir el número de ofertas por sala de 3 a 6.
2. Catálogo completo de compra solo en el taller.
3. Moneda de partida con botín en el suelo, taller como tienda (objeto a elegir + reparación) y objeto garantizado al morir el jefe.

## Opción elegida
Opción 3, con los valores de `content/economy.json`: botín por tipo de sala, precio por rareza y coste/curación de la reparación.

## Motivo
Responde directamente a la petición de «agarrar los items que quiera»: la moneda convierte el taller en una decisión y no en otra ruleta. Mantiene la regla de que ningún objeto es obligatorio y deja el balance editable sin tocar escenas ni código.

## Consecuencias
- Ventajas: toda la elección relevante pasa por la jugadora; el jefe recompensa con un objeto alcanzable; el catálogo completo es comprable con suerte o ahorro.
- Desventajas: una sala de taller abierta de más puede trivializar la rareza si los precios bajan.
- Riesgo: los precios y el botín son valores de prueba, no de balance final; revisar en el playtest H3.

## Revisión
- **Fecha de revisión:** después del playtest H3
- **Resultado:**
- **Nueva decisión relacionada:** D-002
