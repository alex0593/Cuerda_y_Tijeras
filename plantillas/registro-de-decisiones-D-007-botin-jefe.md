# D-007 — El jefe no suelta consumibles y todo objeto tiene una fuente

- **ID:** D-007
- **Fecha:** 2026-09-28
- **Estado:** provisional
- **Área:** diseño / balance / técnica

## Problema

La medición del mapa (`tools/measure_run.gd`, 200 semillas) mostrou que el botín del jefe salía
`repair_coil` en 1 de cada 5 partidas. Es un consumible, y recoléalo **cerraba la partida**
porque sueltar el botín del jefe es la condición de victoria. Es decir: se podía «ganar» sin
coger ningún objeto del taller y sin llevar nada más que las tijeras de mano.

Al excluir los consumibles del botín del jefe apareció un agujero más grave: `repair_coil`
**no tenía ninguna fuente**. Está en la sinergia `impulse_repair` con el resorte saltador, se usa
con `use_item` y recupera un segmento de vida, pero no estaba en la pool del taller ni lo soltaba
nadie. Solo se conseguía por el accidente del jefe. Es decir, el contenido tenía un invariante
roto que nadie comprobaba: *todo objeto del catálogo tiene que ser alcanzable*.

## Opciones consideradas

1. Dejarlo como estaba: el jefe a veces suelta un consumible y ya está.
2. Quitar `repair_coil` del contenido, por ser un objeto raro y de un solo uso.
3. Excluir los consumibles del botín del jefe y darle una fuente real en el taller.
4. Excluir los consumibles y cambiar la victoria para que no dependa del objeto.

## Opción elegida

**Opción 3**, y comprobarlo de forma automática:

- El jefe sortea de `_boss_reward_pool()`, que excluye el arma inicial, la pool del taller y
  cualquier consumible. `boss_drop_for()` usa la misma pool, para que el reemplazo en partida no
  pueda colar un consumible.
- `validate_room()` lo denuncia, con regresión en `tests/test_h3_rewards.gd`.
- `repair_coil` entra en `shop_pool`, que es lo que lo hace alcanzable sin cambiarle el sentido a
  la reparación del taller (que sigue siendo un servicio instantáneo aparte).
- `validate_content.py` comprueba la cobertura **en los dos sentidos**: todo objeto tiene fuente
  (taller o jefe) y el jefe no suelta consumibles.

Se descartó la opción 4 porque el objeto que suelta el jefe es el objetivo legible de la partida
y merece seguir siéndolo.

## Motivo

Un objeto consumible como recompensa final confunde: la bobina de reparación se compra en el
taller, ocupa un hueco, y ganarse el final del recorrido recogiéndola resta todo el sentido a la
tienda. Y el agujero de fondo era peor que el síntoma: un objeto de una sinergia que no se puede
conseguir significa que esa sinergia no existe, y sin ningún comprobador nadie se entera.

## Consecuencias

- Ventajas: la victoria vuelve a ser un objeto del catálogo; `impulse_repair` se puede formar
  alguna vez; la cobertura de contenido pasa a comprobarse sola.
- Desventajas: la pool del taller pasa de 5 a 6 objetos, así que las dos ofertas de la partida
  sorteadas quedan algo más diluidas. No es un problema: el filtro de lo que ya llevas
  sigue garantizando que siempre haya 2 nuevas.
- Riesgos: ninguno conocido. El consumible sigue siendo el objeto más barato (5 hilos) y es el
  único que se puede reponer, así que puede competir con un objeto de especial por un hueco.
- Plataformas afectadas: ninguna en concreto; es contenido y validación.

## Revisión

- **Fecha de revisión:** con el ajuste de la economía (doc 07 §12.2), donde habrá que decidir si
  un consumible entra en el presupuesto de compra de la jugadora.
- **Resultado:**
- **Nueva decisión relacionada:** D-003, D-005, D-006
