# 12. Pruebas, riesgos y métricas

## 1. Objetivo de las pruebas

El objetivo no es encontrar todos los errores posibles antes de publicar, sino reducir la probabilidad de que la jugadora no pueda disfrutar de una partida y detectar rápidamente los problemas críticos.

## 2. Tipos de prueba

### Pruebas automáticas

- Tensión y costes.
- Daño y estados.
- Reglas de sinergias.
- Generación de salas.
- Guardado y carga.
- Migración de partidas.
- Validación de datos.
- Semillas y versión del generador.
- Entrada y acciones.

### Pruebas manuales

- Lectura de ataques.
- Ergonomía táctil.
- Flujo de una partida completa.
- Tutorial.
- Pausa y recuperación.
- Menús.
- Audio.
- Accesibilidad.
- Rendimiento en dispositivos.

### Pruebas de diseño

- Diversidad de objetos.
- Interés de las combinaciones.
- Curva de dificultad.
- Duración de la partida.
- Comprensión de las decisiones.
- Percepción de justicia.

## 3. Matriz mínima de dispositivos

Definir al menos:

- Dispositivo Android de gama baja.
- Android de gama media.
- Android de gama alta con pantalla de alta frecuencia.
- Pantalla compacta.
- Pantalla alargada.
- Tablet, si se decide soportar.
- Dispositivo con muesca o área segura.
- Dispositivo con una muesca pronunciada.

La lista exacta depende del público y de los dispositivos disponibles. No se debe usar un emulador como sustituto de un dispositivo real.

## 4. Prueba de partida completa

Repetir:

1. Inicio de partida.
2. Movimiento y dash.
3. Consumo y regeneración de tensión.
4. Rebobinado.
5. Muerte y reinicio.
6. Elección de objeto.
7. Sinergia.
8. Elección de puerta.
9. Sala secreta.
10. Taller.
11. Jefe.
12. Resumen.
13. Continuación de partida.
14. Resultado de la partida.

Medir el tiempo de cada paso y anotar dónde se pierde la jugadora.

## 5. Pruebas de habitaciones

Para cada sala nueva:

- Entrada segura.
- Puerta abierta correctamente.
- Puertas bloqueadas antes de completar.
- Salidas siempre accesibles.
- Avisos visibles.
- Enemigos dentro de los límites.
- Objetos de decorado que no bloquean el movimiento.
- Dificultad dentro del presupuesto.
- Reacción al dash, al daño y a la muerte.
- Funcionamiento con distintos objetos.
- Comportamiento al repetir la sala.
- Funcionamiento en distintos tamaños de pantalla.

## 6. Pruebas de objetos

Para cada objeto:

- Adquisición.
- Aparición en el inventario.
- Descripción.
- Efecto individual.
- Coste de tensión.
- Interacción con cada etiqueta compatible.
- Interacción con un espacio vacío.
- Comportamiento al repetirlo.
- Comportamiento en la sala más pequeña.
- Respuesta visual y sonora.
- Efecto sobre el jefe.
- Equilibrio frente a la alternativa.

## 7. Pruebas con personas

### Antes de la sesión

- Explicar que no se busca una respuesta correcta.
- No explicar la solución.
- Preparar una versión de compilación.
- Definir qué datos se recopilan.
- Pedir permiso para grabar solo si es necesario.

### Durante la sesión

- Observar sin intervenir.
- Anotar la hora de cada bloqueo.
- No corregir la estrategia de la persona.
- Repetir las preguntas después.

### Después

- ¿Qué esperaba que hiciera?
- ¿Qué hizo realmente?
- ¿Dónde entendió la mecánica?
- ¿Dónde se sintió injusta la situación?
- ¿Qué objeto utilizó más?
- ¿Qué objeto ignoró?
- ¿Cuándo usó rebobinado?
- ¿Qué volvería a jugar?

## 8. Métricas recomendadas

Solo medir lo que tendrá una decisión asociada.

### Primera sesión

- Inicio de partida.
- Tutorial completado.
- Primer movimiento.
- Primer disparo.
- Primer dash.
- Primer objeto.
- Primera sinergia.
- Primera muerte.
- Primer reinicio.

### Partidas

- Duración media.
- Habitaciones visitadas.
- Enemigos derrotados.
- Objetos obtenidos.
- Sinergias descubiertas.
- Muertes por causa.
- Progreso por acto.
- Porcentaje que alcanza cada jefe.
- Porcentaje que completa la partida.
- Semillas compartidas.

### Experiencia

- Caídas.
- Bloqueos de entrada.
- Tamaño de joystick modificado.
- Uso de asistencia.
- Vibración desactivada.
- Opciones de accesibilidad activadas.
- Quejas sobre los controles.

### Técnicas

- Fotogramas por segundo.
- Memoria.
- Tiempo de carga.
- Tiempo de guardado.
- Tamaño de la compilación.
- Errores de compilación.
- Errores de recursos.
- Fallos de compra.

## 9. Privacidad de las métricas

- Recopilar lo mínimo.
- No guardar texto libre que pueda contener datos personales.
- Documentar eventos y finalidade.
- Permitir que la jugadora desactive la telemetría opcional cuando sea posible.
- No utilizar datos de una persona para publicidad.
- No publicar rangos de cada dato sin un plan de privacidad.

## 10. Riesgos principales

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---:|---:|---|
| Controles incómodos | Alta | Alto | Pruebas tempranas y ajustes |
| Demasiadas combinaciones | Alta | Alto | Límite de objetos y reglas simples |
| Rebobinado rompe el juego | Media | Alto | Instantáneas limitadas y pruebas de estado |
| Arte inconsistente | Media | Alto | Pruebas de silueta y modularidad |
| Partida demasiado larga | Media | Medio | Medir duración y recortar salas |
| Partida demasiado frustrante | Media | Alto | Avisos y asistencia |
| Guardado corrupto | Baja | Alto | Versionado y copias |
| Rendimiento bajo | Media | Alto | Presupuesto y pruebas en dispositivos |
| Dependencia de plataforma | Media | Medio | Interfaces y exportación de escritorio |
| Dependencia de una librería | Media | Medio | Mantener adaptadores pequeños |
| Licencias incorrectas | Baja | Alto | Registro de recursos |
| Alcance excesivo | Alta | Alto | Hitos y criterio de corte |
| Falta de comentarios | Media | Alto | Pruebas y métricas |

## 11. Plan de mitigación

### Controles

Crear una prueba con dos o tres configuraciones de joystick. No decidir la distribución solo desde un emulador.

### Combinaciones

Limitar cada objeto a dos relaciones principales. Eliminar una combinación si no cambia una decisión.

### Rebobinado

Empezar con una simulación de 1.5 segundos y reproducir únicamente posición, proyectiles y elementos reversibles.

### Arte

Aprobar una prueba de estilo con Lela, un enemigo y un jefe antes de producir el resto.

### Alcance

Mantener el primer acto como producto publicable si los tres actos no caben en el plazo disponible.

### Legal

No publicar hasta tener un inventario de recursos y una comprobación básica de licencias.

## 12. Pruebas de regresión

Marcar como críticos:

- Movimiento.
- Dash.
- Tensión.
- Rebobinado.
- Guardado.
- Carga de partida.
- Compra de objetos.
- Apertura de puertas.
- Regeneración de una semilla.
- Rotación o suspensión de la aplicación.
- Inicio de la aplicación.
- Puntuación y resumen.

Una modificación en un sistema crítico debe volver a pasar su prueba.

## 13. Criterios de bloqueo de una compilación

No publicar si existe:

- Pérdida de partida sin recuperación.
- Imposibilidad de continuar después de una compra.
- Fallos frecuentes.
- Controles inutilizables en el dispositivo de referencia.
- Ataques enemigos invisibles.
- Guardado que borra una partida válida.
- Recursos o créditos con licencia desconocida.
- Texto provisional en la versión comercial.
- Error de compilación o firma.
- Rendimiento muy por debajo del objetivo en una parte importante de dispositivos.

## 14. Registro de incidencias

Cada error debe registrar:

- Fecha.
- Versión.
- Dispositivo.
- Sistema operativo.
- Pasos para reproducir.
- Resultado esperado.
- Resultado real.
- Frecuencia.
- Captura o vídeo.
- Semilla.
- Estado.
- Prioridad.
- Responsable.
- Solución y commit o versión compilada.

## 15. Criterios de calidad de una partida

Antes de pedir una revisión externa:

- No hay errores bloqueantes conocidos.
- La partida se puede ganar y perder correctamente.
- Los tutoriales no bloquean.
- Los objetos tienen iconos legibles.
- Los jefes son superables sin un objeto concreto.
- El resumen de partida aparece siempre.
- La partida se puede abandonar sin corromper el guardado.
- El tiempo está dentro del rango objetivo.
- La música no tapa los avisos.
- El formato de pantalla no oculta información.
