# 05. Objetos y sinergias

## 1. Objetivo del sistema

Los objetos deben crear decisiones y estrategias distintas. Un objeto no debería limitarse a sumar daño, reducir el tiempo de recarga o mejorar una cifra sin contexto.

Cada objeto necesita:

- Un efecto útil por sí solo.
- Una identidad visual y sonora reconocible.
- Al menos una interacción interesante.
- Un coste, una restricción o un momento adecuado para obtenerlo.
- Un texto breve que explique su función.

## 2. Estructura del inventario

Propuesta para el prototipo y la primera versión:

1. **Arma:** sustituye o modifica el ataque principal.
2. **Mecanismo:** afecta a la movilidad, la tensión o la interacción con el escenario.
3. **Amuleto pasivo:** modifica una regla de forma continua o con poca frecuencia.
4. **Consumible:** se activa manualmente y tiene cargas limitadas.

La jugadora comienza con tijeras, un mecanismo vacío y un amuleto vacío. Los objetos encontrados ocupan espacios ya existentes. Crear más espacios aumenta la complejidad y reduce el espacio visual en móvil.

## 3. Propiedades de un objeto

Cada objeto puede declarar:

- Identificador estable.
- Nombre y descripción.
- Rareza.
- Espacio ocupado.
- Coste de tensión adicional.
- Efecto principal.
- Efectos pasivos.
- Etiquetas temáticas.
- Interacciones permitidas.
- Restricciones.
- Sonidos y efectos visuales.
- Versión de balance.

## 4. Objetos del vertical slice

### Tijeras de precisión

**Espacio:** arma  
**Etiquetas:** corte, precisión, dirección

- Lanza cortes pequeños en la dirección elegida.
- Tiene mayor velocidad y menor tamaño de proyectil que el arma inicial.
- A corta distancia realiza un corte más potente.
- Puede cortar hilos, cintas y obstáculos marcados.

**Ventaja:** precisa y fácil de aprender.  
**Coste:** menor área de daño.

### Resorte saltador

**Espacio:** mecanismo  
**Etiquetas:** movimiento, dash, resorte

- El dash cubre algo más de distancia.
- Al terminar el dash se reproduce un pequeño rebote.
- Si termina contra una pared, la jugadora rebota hacia atrás.
- Permite encadenar un dash corto con un corte.

**Ventaja:** movilidad y control.  
**Coste:** aumenta el coste del dash y puede ser difícil de usar en salas estrechas.

### Imán de hierro

**Espacio:** mecanismo  
**Etiquetas:** atracción, metal

- Atrae monedas, llaves, clavos y algunos proyectiles metálicos.
- Puede atraer a un enemigo pequeño durante un instante.
- No atrae enemigos pesados ni bloquea la partida.
- Mantiene los objetos metálicos fuera de las trayectorias normales durante poco tiempo.

**Ventaja:** control y recuperación de recursos.  
**Coste:** no tiene capacidad de controlar masas grandes.

### Caja de música

**Espacio:** amuleto  
**Etiquetas:** música, ritmo, notas

- Al disparar, una nota puede girar alrededor de la jugadora durante un tiempo breve.
- Las notas dirigen un patrón de movimiento suave.
- El sonido indica cuándo empieza y termina la órbita.

**Ventaja:** control del espacio alrededor.  
**Coste:** las notas ocupan espacio y pueden bloquear una salida.

### Ojo de vidrio

**Espacio:** amuleto  
**Etiquetas:** revelar, luz, crítico

- Revela enemigos invisibles durante dos segundos.
- Marca el punto débil de enemigos que tienen uno.
- Aumenta ligeramente el daño de los cortes que acertan en ese punto.

**Ventaja:** información y precisión.  
**Coste:** depende de que exista una amenaza o un punto débil relevante.

### Hilo tensado

**Espacio:** amuleto  
**Etiquetas:** hilo, atar, control

- Ata brevemente a un enemigo pequeño o mediano cuando recibe un corte.
- El enemigo queda sujeto durante un instante y luego tira del anclaje.
- Puede atrapar proyectiles de ciertos jefes durante un tiempo limitado.

**Ventaja:** control táctico.  
**Coste:** la sujeción es breve y no detiene a los jefes.

### Tornillos y corcho

**Espacio:** mecanismo  
**Etiquetas:** rebote, proyectil

- Los proyectiles rebotan una vez contra paredes o enemigos señalizados.
- Al alcanzar su límite, vuelven a la jugadora como un corte corto.
- Cada rebote reduce ligeramente su daño.

**Ventaja:** cobertura y ángulos indirectos.  
**Coste:** un rebote incorrecto puede convertir un disparo útil en una colisión.

### Pegamento de juguete

**Espacio:** amuleto  
**Etiquetas:** adherir, construir, defensas

- Una parte de un proyectil puede quedarse pegada a un muro o enemigo durante unos segundos.
- Los proyectiles pegados sirven como pequeñas trampas o puntos de apoyo.
- No se pega permanentemente al objetivo.

**Ventaja:** flexibilidad espacial.  
**Coste:** efecto secundario y control directo limitado.

## 5. Sinergias iniciales

Las sinergias deben construirse con reglas simples. No hace falta una combinación especial para cada pareja.

### Tijeras + Resorte

**Resultado:** Tijeras de impulso.

- El dash atraviesa un sector corto en una dirección.
- Los cortes después del dash producen una onda de choque.
- Permite entrar y salir rápidamente de una zona.

### Tijeras + Hilo

**Resultado:** Puntadas vivas.

- Un corte deja una línea de hilo en el suelo.
- Un enemigo que cruza la línea recibe daño y queda registrado durante un instante.
- No crea una trampa permanente.

### Imán + Tornillos y corcho

**Resultado:** Sistema de recuperación magnética.

- Los proyectiles que rebotan son atraídos hacia la jugadora.
- Puede cambiar un patrón de rebote en un ataque de retorno más agresivo.
- El imán no teletransporta al enemigo a través de paredes.

### Caja de música + Resorte

**Resultado:** Ritmo de reloj.

- Las notas orbitan a una velocidad determinada por el resorte.
- El dash cambia temporalmente la dirección de la órbita.
- Permite modificar la trayectoria sin añadir un botón.

### Caja de música + Hilo

**Resultado:** Notas atrapadas.

- Las notas pueden quedar fijadas a un punto del escenario.
- Crean líneas o zonas de corte temporal.
- Si no hay espacio útil, siguen orbitando normalmente.

### Ojo de vidrio + Sombra de títere

**Resultado:** Luz reveladora.

- El objetivo visible recibe un contorno estable.
- Los ataques hacia él tienen una pequeña confirmación visual.
- El objeto no daña más a las sombras; las hace predecibles.

### Pegamento + Tornillos y corcho

**Resultado:** Órbita adhesiva.

- Los proyectiles adheridos giran alrededor del punto donde impactan.
- Interceptan algunos proyectiles cercanos.
- El efecto desaparece al expirar el pegamento.

### Resorte + Bobina de reparación

**Resultado:** Reparación con impulso.

- Usar un consumible que no sea vital puede convertir parte de la tensión en cargas adicionales de dash.
- El objeto no debe hacer que la curación sea obligatoria ni infinita.

### Imán + Caja de música

**Resultado:** Melodía cargada.

- Las notas orbitan más lejos y dañan al contacto.
- El imán atrae las notas después de completar una órbita.
- Durante la órbita la jugadora tiene menos espacio para moverse.

## 6. Sinergias candidatas para futuras versiones

- Tijeras + Caja de Música: los cortes producen ondas sonoras.
- Hilo + Ojo de vidrio: los enemigos atados muestran puntos débiles.
- Resorte + Pegamento: saltos adhesivos contra paredes.
- Tornillos + Hilo: los rebotes se anclan a una línea.
- Imán + Ojo de vidrio: se marcan automáticamente objetivos metálicos.
- Pegamento + Caja de Música: notas pegadas a enemigos que actúan como detonadores remotos.
- Hilo + curación: se restauran puntos de tensión al cortar ataques.
- Resorte + Ojo de vidrio: desplazamiento corto en lugar de un dash convencional.

## 7. Rareza y selección

Rareza inicial:

- **Común:** un efecto funcional, sin sinergia garantizada.
- **Especial:** modifica el arma o un sistema de forma notable.
- **Rara:** cambia las reglas del combate o crea una oportunidad grande.
- **Prototipo:** disponible en la compilación de desarrollo para pruebas; todavía no es una rareza visible para la jugadora.

Reglas:

- El primer objeto debe seleccionarse entre dos o tres opciones.
- La jugadora nunca debe recibir un objeto completamente inútil por accidente.
- Un objeto raro es poderoso, pero tiene una desventaja o requisito claro.
- Las sinergias se descubren observando dos iconos en el inventario y escuchando la combinación.
- El juego no debe mostrar todas las combinaciones en una lista larga.

## 8. Presentación de una sinergia

Cuando se forma una sinergia:

1. Reproducir una animación breve sin bloquear.
2. Mostrar una tarjeta de una línea con nombre y efecto.
3. Cambiar el borde o el icono secundario del objeto.
4. Añadir una capa sonora única.
5. Guardar la sinergia en el registro de la partida.

El texto debe ser suficientemente breve para leerse sin pausar el juego.

## 9. Reglas para combinaciones

- Máximo de dos relaciones activas por objeto en el lanzamiento.
- Una sinergia no puede convertir el juego en un botón automático.
- Un objeto debe ser útil sin una sinergia.
- Una sinergia no puede eliminar permanentemente la acción principal.
- Una sinergia no puede hacer que un jefe sea inevitable sin una contraestrategia.
- Las interacciones deben ser legibles a velocidad móvil.
- La misma combinación puede tener valores de balance distintos, pero conserva su identidad.

## 10. Fuentes de objetos

- Recompensa al completar una habitación.
- Cofre.
- Enemigo específico.
- Puerta de riesgo.
- Jefe.
- Evento ambiental.
- Elección entre tres objetos después de un acto.

El primer acto introduce como máximo dos etiquetas a la vez.

## 11. Consumible de ejemplo

### Bobina de reparación

- Repara una fracción de vida.
- Devuelve algo de tensión si la jugadora tiene mucha.
- No puede usarse con la vida completa.
- Es útil como botón de emergencia y como recurso para el resorte.

## 12. Ejemplo de datos de balance

```text
id: scissors_precision
name: Tijeras de precisión
slot: weapon
tags: [cut, precision]
base_damage: 10
projectile_speed: 420
fire_interval: 0.28
tension_cost: 4
status_effects:
  - critical_chance: 0.05
compatible_tags: [spring, thread]
```

Los números son para pruebas. Deben guardarse en datos de contenido, no codificarse directamente en las escenas.

## 13. Checklist de objeto

- [ ] Es útil por sí solo.
- [ ] Tiene un icono legible.
- [ ] Se puede obtener en una partida razonable.
- [ ] Tiene un coste o una limitación clara.
- [ ] No rompe los controles móviles.
- [ ] Funciona en una sala pequeña.
- [ ] Tiene respuesta sonora y visual.
- [ ] Se ha probado con las sinergias más probables.
- [ ] No depende de un personaje concreto.
- [ ] Se puede explicar en una o dos frases.
