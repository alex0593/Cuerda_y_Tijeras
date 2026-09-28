# 08. Audio, experiencia y accesibilidad

## 1. Objetivo de experiencia

La partida debe ser clara en una pantalla pequeña y funcionar sin obligar a leer textos largos. Cada acción importante necesita una combinación de feedback visual, sonoro y, cuando está disponible, háptica.

## 2. Flujo de pantallas

### Menú principal

Es la escena principal del proyecto: el juego arranca aquí, no en la partida.

- **Continuar.** Apagado si no hay partida guardada. Con ella, muestra la semilla, los hilos y
  los objetos que llevaba. Al pulsarlo, la partida vuelve **exactamente** donde estaba: misma
  semilla, mismo mapa, misma sala, mismo botín sin recoger (doc 09 §10).
- **Nueva partida.** Borra lo que hubiera guardado: si no, «Continuar» ofrecería un mapa que ya
  no tiene nada que ver con esta partida.
- **Volver al menú.** Solo aparece si había una partida en marcha. Sale desde la pausa y deja la
  partida guardada.
- Pendiente: Colección, Opciones y Créditos. No hay contenido detrás todavía, así que no se
  muestran botones vacíos.

### Preparación de partida

- Elegir figura inicial cuando exista más de una.
- Elegir una configuración de objetos.
- Mostrar la semilla si está disponible.
- Tutorial de controles solo en la primera partida o cuando se solicite.

### Partida

- Inicio de acto.
- Nombre de habitación o área, no dirección constante.
- HUD discreto.
- Pausa siempre accesible.

### Resumen de partida

- Duración, habitaciones visitadas y enemigos derrotados, en una línea.
- Objetos obtenidos, por su nombre de catálogo y no por su identificador.
- Sinergias formadas, por su nombre.
- Causa de muerte, contada en palabras: un identificador en el resumen no dice nada.
  Solo aparece si hubo derrota.
- Semilla.
- Botones de Reintentar y de Menú, propios del resumen.

Los objetos y las sinergias que se han visto pasan al perfil, que es lo que hay detrás de la
colección y de las sinergias descubiertas entre partidas.

## 3. HUD

Elementos visibles:

- Vida.
- Tensión.
- Cargas de rebobinado.
- Objeto activo.
- Botón de consumible.
- Indicador de arma o efecto sinérgico.
- Pausa.

Reglas:

- No tapar la posición de la jugadora.
- No mostrar demasiado texto.
- Mostrar el valor de un recurso solo cuando cambie o sea importante.
- Usar una animación breve al ganar o perder una carga.
- El HUD no debe indicar toda la información de la sala.

## 4. Distribución de controles táctiles

- Joystick izquierdo en la zona inferior izquierda.
- Joystick derecho en la zona inferior derecha.
- Botón de dash cerca del pulgar derecho, sin bloquear el joystick.
- Botón de rebobinado más arriba, con área amplia.
- Consumible en la parte inferior central o derecha, según el tamaño de pantalla. En el
  vertical slice está en el hueco entre el centro y el joystick derecho, para no solapar
  con ninguna palanca ni tapar a la jugadora, que la cámara mantiene siempre en el centro.
- Pausa lejos de los controles de juego.

El diseño debe funcionar con una mano si la jugadora elige esa opción. No es obligatorio ofrecer una mano única, pero sí evitar que todos los controles estén en el borde.

## 5. Tutorial contextual

La primera partida enseña:

1. Mover a Lela.
2. Apuntar con el joystick derecho.
3. Romper un objetivo.
4. Evitar una carga con dash.
5. Recoger el primer objeto.
6. Ver una primera sinergia.
7. Elegir una puerta.
8. Usar rebobinado antes del jefe.

Después, los tutoriales se ocultan automáticamente. Siempre puede abrirse una sección de ayuda desde Opciones.

## 6. Respuesta audiovisual del combate

### Jugadora

- Corte: pequeño arco de papel y sonido metálico.
- Impacto recibido: destello breve, retroceso y vibración si está disponible.
- Dash: eco visual de hilo y una línea de movimiento.
- Rebobinado: reversión de partículas, sonido de cuerda y destello no agresivo.
- Tensión baja: cambia la animación, no solo la barra.

### Enemigos

- Aviso claro antes de atacar.
- El color es un apoyo, nunca la única señal.
- Sonido específico por tipo.
- Muerte breve y estilizada.

## 7. Dirección de audio

### Música

- Instrumentos de cuerda, caja de música, piano viejo, metal y percusión ligera.
- La música debe ser melódica y no tapar ataques.
- El acto I puede usar una melodía más alegre y rota.
- El acto II utiliza ritmo y capas.
- El acto III reduce gradualmente el ritmo antes del jefe final.

### Efectos

- Madera: cajas, mesas y puertas.
- Metal: tijeras, llaves y botones.
- Tela: oso, cortinas y cuerpos blandos.
- Papel: proyectiles, notas y recompensas.
- Reloj: tensión, rebobinado y final de acto.

### Ambiente

- Viento y lluvia fuera del taller.
- Crujidos de madera.
- Latido de mecanismos.
- Silencio breve antes de un jefe.

## 8. Buses de audio

Propuesta:

- Música.
- Efectos.
- Ambiente.
- Interfaz.
- Voz, si finalmente se graba.

Cada bus tiene volumen independiente. El juego guarda la configuración y la aplica al cambiar de primer plano a segundo plano.

## 9. Música adaptativa

Primera versión:

- Capa tranquila durante exploración.
- Capa de tensión cuando hay enemigos activos.
- Capa de jefe.
- Acorde breve al descubrir una sinergia.
- Música de resumen al terminar la partida.

No se necesita un sistema de composición procedural al principio.

## 10. Vibración

- Pulso corto al dash.
- Pulso doble al rebobinar.
- Vibración breve al recibir daño.
- Vibración solo en eventos importantes.
- Intensidad y activación configurables.

La vibración no debe ser la única indicación de daño.

## 11. Accesibilidad

### Opciones de visión

- Alto contraste.
- Reducir destellos.
- Reducir sacudidas.
- Aumentar tamaño del texto.
- Tamaño de los joysticks.
- Mostrar opcionalmente el nombre del enemigo o su aviso.
- Iconos además de colores.

### Opciones de control

- Puntería asistida.
- Disparo automático.
- Dash con doble toque opcional.
- Sensibilidad del control derecho.
- Botón de rebobinado más grande.
- Remapeo básico en escritorio.
- Pausa y menú accesibles desde cualquier plataforma.

### Opciones de audio

- Volúmenes independientes.
- Silenciar efectos.
- Silenciar música.
- Reducir sonidos repentinos.
- Subtítulos si se incorpora voz.

## 12. Subtítulos y texto

- Texto grande y con sombra.
- Duración suficiente para leer.
- No aparece texto debajo de un área de combate.
- El texto crítico también tiene icono o respuesta visual.
- Español como idioma inicial.

## 13. Primera experiencia de uso

- No mostrar todos los menús al principio.
- No exigir crear una cuenta.
- No pedir permisos innecesarios.
- Explicar un concepto por vez.
- Ofrecer un botón de ayuda.
- No castigar una partida por no terminar el tutorial.

Después de la segunda partida, el juego puede mostrar una pantalla de objetos nuevos descubiertos en lugar de repetir todo el proceso de aprendizaje.

## 14. Comportamiento de la pausa

- Pausar música, efectos y simulación.
- Mostrar el estado actual, las opciones y la posibilidad de volver.
- Confirmar antes de abandonar la partida.
- Guardar automáticamente en puntos seguros.
- No contar el tiempo de pausa como tiempo de partida.

## 15. Respuesta a errores

Si una acción no está disponible:

- El botón se atenúa.
- Se muestra una pequeña explicación.
- No aparece un error vacío.
- No se pierde una partida por una entrada incorrecta.
- Se puede recuperar una partida corrupta mediante una copia de seguridad.

## 16. Rendimiento y experiencia

- Mostrar un modo de reducción de efectos si el dispositivo lo necesita.
- Reducir partículas, sombras y sacudidas.
- Mantener la legibilidad al bajar calidad.
- No cambiar la justicia del juego por rendimiento.

## 17. Localización

### Primer idioma

Español.

### Preparación

- No concatenar cadenas directamente en el código.
- Usar claves de traducción.
- Permitir textos largos sin desbordamiento.
- Revisar nombres propios.
- Probar acentos, signos y mayúsculas.
- Guardar fuentes que soporten español.

## 18. Checklist de experiencia

- [ ] Una usuaria nueva puede comenzar sin cuenta.
- [ ] Los controles táctiles no se superponen.
- [ ] Los botones tienen área suficiente.
- [ ] La interfaz no tapa la acción.
- [ ] Los estados importantes no dependen solo del color.
- [ ] El tutorial aparece en contexto.
- [ ] La pausa funciona.
- [ ] Los errores tienen una salida.
- [ ] El resumen muestra información útil.
- [ ] Se puede ajustar la experiencia.

## 19. Preguntas para la primera prueba

- ¿Entendiste cómo moverte sin un tutorial largo?
- ¿Entendiste para qué sirve la tensión?
- ¿En qué momento intentaste usar rebobinado?
- ¿Qué objeto resultó menos claro?
- ¿Qué habitación fue más justa?
- ¿Qué habitación pareció injusta?
- ¿El jefe dio suficientes señales?
- ¿Preferiste un objeto o una sinergia? ¿Por qué?
- ¿La partida terminó demasiado pronto o demasiado tarde?
- ¿Qué cambiarías antes de otra partida?

Hacer las preguntas después de jugar, no durante la partida.
