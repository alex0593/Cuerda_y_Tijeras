# 02. Mecánicas y bucle de juego

## 1. Experiencia principal

La jugadora entra en una habitación, analiza el espacio, combate o evita peligros, recoge recursos y elige una recompensa. Después decide qué puerta, objeto o riesgo tomar. La partida avanza por actos hasta un jefe.

## 2. Cámara

- Vista cenital.
- Cámara fija por habitación o con desplazamiento muy limitado.
- Orientación horizontal.
- Resolución interna inicial de `640×360` o `960×540`, escalada a la pantalla.
- El jugador debe ver las amenazas antes de entrar en el área de peligro.

## 3. Controles Android

### Configuración estándar

- **Joystick izquierdo:** movimiento.
- **Joystick derecho:** apuntar y disparar.
- **Botón Dash:** desplazamiento corto.
- **Botón Rebobinado:** habilidad de supervivencia.
- **Botón de consumible:** usar objeto activo.
- **Pausa:** esquina superior derecha.

El disparo puede empezar automáticamente mientras se usa el joystick derecho. Se incluirá una opción de disparo manual.

### Opciones de asistencia

- Puntería asistida.
- Disparo automático hacia un enemigo cercano.
- Tamaño de joystick configurable.
- Velocidad de proyectiles ajustable.
- Vibración desactivable.
- Sacudida de cámara desactivable.
- Intensidad de destellos ajustable.

## 4. Movimiento

- Desplazamiento en ocho direcciones.
- Aceleración y frenado suaves.
- Animación de pequeño rebote de resorte.
- El dash ofrece una ventana breve de invulnerabilidad.
- El dash no atraviesa paredes ni es infinito.
- El golpe recibido produce un retroceso pequeño y legible.

## 5. Tensión de cuerda

La tensión es el recurso central de Lela.

### Acciones que la consumen

- Disparo.
- Dash.
- Habilidades activas.
- Interacciones especiales de algunos objetos.

### Reglas iniciales para prototipar

- Rango de 0 a 100.
- Ataque básico: coste pequeño.
- Dash: coste moderado.
- La regeneración comienza tras una pausa corta.
- Al llegar a cero, Lela no se bloquea: se ralentiza, sus cortes se debilitan y no puede ejecutar el dash completo.

Estos valores son de prueba. El ajuste final dependerá de partidas reales.

## 6. Rebobinado

### Propuesta inicial

- Dos cargas por partida.
- Recarga completa de 10 a 12 segundos por carga.
- Retrocede entre 1.5 y 2 segundos.
- Recupera la posición y velocidad previas de la jugadora.
- Recupera las posiciones previas de proyectiles y elementos reversibles.
- No borra daño ya causado a la jugadora o a los enemigos.
- No deshace decisiones de IA, recompensas ni objetos.

### Propósito

- Esquivar una carga después de atacar en el lugar incorrecto.
- Regresar a una línea de visión favorable.
- Corregir una entrada en una sala peligrosa.
- Crear una salida de emergencia sin recibir daño durante el rebobinado.

### Riesgos

Rebobinar sin límite podría permitir repetir una decisión perfecta o crear objetos duplicados. Por eso no se graba el estado completo de la partida y no se revierten recompensas.

## 7. Combate

### Arma inicial

Tijeras que lanzan pequeños cortes o fragmentos de hilo en la dirección elegida. El patrón debe ser simple de aprender y claramente visible.

### Vida

Propuesta inicial:

- Tres segmentos de vida.
- Un golpe fuerte quita un segmento.
- Un golpe normal quita una fracción.
- Los objetos curativos restauran una fracción o un segmento, según rareza.
- Existe una invulnerabilidad breve después de recibir daño.

### Respuesta audiovisual

- Destello breve de la silueta.
- Retroceso pequeño.
- Sonidos distintos para impacto, crítico y derrota.
- Enemigos aturdidos solo cuando la acumulación lo justifique.
- Los ataques enemigos deben ser visibles antes de golpear.

## 8. Inventario

Para el prototipo:

- Un espacio de arma.
- Un espacio de mecanismo.
- Un espacio de amuleto pasivo.
- Nota H2: el vertical slice usa dos espacios provisionales de mecanismo y amuleto para hacer alcanzables las sinergias; ver D-002.
- Un consumible activo.

### Tipos

- **Arma:** cambia el ataque principal.
- **Mecanismo:** afecta movimiento, tensión o interacción con el mundo.
- **Amuleto:** modifica una regla de manera pasiva o poco frecuente.
- **Consumible:** uso manual y cargas limitadas.

## 9. Habitaciones y puertas

Al completar una habitación se abren sus puertas. El jugador puede ver:

- Riesgo principal.
- Recompensa probable.
- Llave, si es privada.
- Efecto especial de la puerta.

Cada elección normal debe incluir al menos una salida segura o claramente menos peligrosa.

## 10. Bucle de una partida

1. Preparación breve y elección inicial.
2. Primera habitación de aprendizaje.
3. Combate o evasión.
4. Elección de puerta.
5. Recompensa de objeto o mejora.
6. Cambio de estrategia.
7. Jefe de acto.
8. Descanso breve.
9. Acto siguiente con mayor complejidad.
10. Resumen y nueva partida.

## 11. Estructura de actos

### Acto I — La Sala de las Cajas

Enseña movimiento, disparo, dash, tensión y las primeras combinaciones. Los enemigos son individuales y las habitaciones enseñan sus avisos de ataque.

### Acto II — La Caja de Música

Introduce rebobinado, imanes, proyectiles combinados y elecciones de riesgo. Aparecen mezclas de enemigos.

### Acto III — El Teatro de las Sombras

Combina todos los sistemas. Los enemigos aprovechan interacciones ya aprendidas y los jefes utilizan mecánicas de actos anteriores.

## 12. Progresión permanente

### Desbloqueos recomendados

- Nuevos objetos.
- Nuevas configuraciones iniciales.
- Nuevos consumibles.
- Semillas diarias.
- Temas, marcos y cosméticos.
- Posibles variantes de personajes después de validar el juego.

### Evitar

- Mejorar permanentemente el daño hasta que la partida se convierta en un trámite.
- Tareas repetitivas obligatorias durante cientos de horas.
- Mantener objetos básicos bloqueados hasta un nivel alto de repetición.

## 13. Semillas

- Una semilla define generación, recompensas y variaciones.
- La semilla diaria puede estar disponible sin conexión.
- Cada partida muestra y permite copiar su semilla.
- La misma semilla puede reproducirse en otro momento.
- La versión del generador se guarda para reproducir errores.

## 14. Decisiones de riesgo

Cada tramo debería ofrecer al menos una elección significativa:

- Objeto potente con una restricción.
- Puerta peligrosa con mejor recompensa.
- Llave que abre una ruta y consume recurso.
- Ataque rápido contra un enemigo lento.
- Dash para obtener un objeto o evitar un golpe.
- Reparar la vida a cambio de perder tensión.

## 15. Tutorial

El tutorial ocurre durante el juego:

1. Movimiento.
2. Disparo orientado.
3. Primer objetivo destructible.
4. Primer dash para evitar un ataque.
5. Primer objeto combinable.
6. Primera elección entre puertas.
7. Primer uso de rebobinado antes del jefe.

Las explicaciones aparecen en el momento y se pueden omitir.

## 16. Checklist de diseño

Antes de añadir otro sistema, comprobar:

- ¿Cambia una decisión del jugador?
- ¿Se entiende sin texto largo?
- ¿Se puede representar con la estética actual?
- ¿Es necesario para el prototipo?
- ¿Se puede probar en pocos minutos?
- ¿Funciona sin un objeto específico?

Si no cumple, se aplaza a ideas posteriores.
