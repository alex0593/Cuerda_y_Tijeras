# D-008 — Economía del mapa: qué se puede comprar al llegar al taller

- **ID:** D-008
- **Fecha:** 2026-09-28
- **Estado:** provisional
- **Área:** diseño / balance

## Problema

D-006 cambió el recorrido de 7 salas lineales a un mapa de 9 salas, y la economía se quedó en
los valores de cuando el recorrido era fijo. Con la medición por delante (`tools/measure_run.gd`,
200 semillas) las cifras de partida completa parecían insuffcientes: 9–20 hilos para una entrada
de 6 y objetos de 5 a 12.

La conclusión inicial, escrita en doc 07 §12.2, era que «la tienda abre justo y no queda para
comprar nada». **Era una lectura equivocada**, hecha con la curva de profundidad en vez de con la
cifra directa: al llegar al taller por primera vez se puede abrir el **84 %** de las partidas y
comprar un objeto en el **53 %**. El problema real era otro y está en §12.2.

## Opciones consideradas

1. Subir el botín de las salas y no tocar los precios.
2. Bajar la entrada al taller, para que abrir no fuera el cuello de botella.
3. Bajar los precios por rareza, sobre todo el de los objetos comunes.
4. Cambiar la estructura de las sinergias para que ocurran más.

## Opción elegida

**Combinación de 1, 2 y 3, con los valores medidos y no calculados a ojo:**

- Botín: combate 2–3, riesgo 3–4, tesoro 2–3, taller 2–3 (antes 1–2, 2–3, 1–2, 1–2).
- Entrada al taller: 6 → **4**. Abrir pasa de 84 % a 100 % de las partidas.
- Reparación: 6 → **5**, para que sea comparable a un objeto común.
- Precios: común 5 → **4**. Los de especial (8) y rara (12) **no se tocan**: los objetos raros
  tienen que seguir siendo raros, que es lo que hace que la tienda sea una decisión.

Lo que se midió antes y después, al llegar al taller por primera vez:

| | antes | después |
| --- | --- | --- |
| puede abrirlo | 84 % | **100 %** |
| puede comprar 1 objeto | 53 % | **85 %** |
| puede comprar 2 objetos | 18 % | **49 %** |
| objetos por partida (mapa entero) | 2,7 | **3,3** |
| sinergias por partida | 0,3 | **0,5** |

## Lo que la medición dejó claro y no se ha tocado

**Las sinergias no son un problema de precios.** Con un barrido de cinco combinaciones de precios
(`tools/sweep_economy.py`), bajando el común de 5 a 4, el especial de 8 a 6 y hasta el común a 3,
la media de sinergias por partida se queda entre **0,4 y 0,5** y no pasa de ahí. El motivo es
estructural: **las seis sinergias reales necesitan un objeto del taller más uno del jefe**, y el
jefe suelta exactamente uno. Por mucho que se mejore el taller, el techo lo pone el jefe.

Subir el taller hasta 4,5 objetos por partida (precio común 3) solo sube las sinergias de 0,5 a
0,5: se pagan objetos por objetos que no llegan a formar nada. No compensa.

Las opciones para subirlo de verdad son de diseño, no de números, y quedan pendientes de decidir:

- Que el jefe suelte **dos** objetos en vez de uno.
- Que alguna sinergia se forme con **dos objetos del taller**, que sí se pueden elegir.

Ninguna se ha aplicado. Hasta que se decida una, las sinergias ocurren en la mitad de las partidas
como mucho, y el vertical slice sigue jugando bien sin ellas.

## Motivo

El taller tiene que ser una decisión y no un trámite. Con los valores anteriores, llegar al taller
-era casi siempre un trámite: se abría con lo justo y no quedaba para nada. Con estos, se puede
comprar un objeto casi siempre y dos la mitad de las veces, pero no todo: los objetos raros siguen
 costando 8 y 12, y una partida da para tres o cuatro objetos de siete.

## Consecuencias

- Ventajas: el taller deja de ser decorativo; el objeto del jefe cuenta más, porque ahora hay con
  qué emparejarlo; reparar y comprar son decisiones comparables.
- Desventajas: el hilo pierde peso como recurso de supervivencia y pasa a ser sobre todo moneda
  de objetos. Si la tensión de la partida se apoyaba en escasear, hay que vigilarlo en el
  playtest.
- Riesgos: que la tienda se vuelva obvia si con 12,5 hilos de media se compran siempre dos
  objetos. El 49 % de dos compras deja margen, pero es el número que hay que mirar en la próxima
  partida.
- Plataformas afectadas: ninguna; es contenido.

## Revisión

- **Fecha de revisión:** después de tres partidas completas en hardware, con el número de
  objetos comprados y sinergias formadas anotados.
- **Resultado:**
- **Nueva decisión relacionada:** D-003, D-005, D-006
