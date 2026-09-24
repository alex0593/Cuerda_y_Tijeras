# 13. Backlog, decisiones y checklists

## 1. Decisión principal pendiente

### Elección del motor

**Estado:** pendiente de prueba técnica.

### Opción A: Godot

Elegir si la prioridad es:

- Terminar el juego con menos infraestructura.
- Tener un editor visual.
- Usar una ruta rápida a Android y escritorio.
- Aceptar GDScript como lenguaje principal.

### Opción B: libGDX + Kotlin

Elegir si la prioridad es:

- Aprender Kotlin.
- Mantener el proyecto cercano al lenguaje elegido originalmente.
- Construir una arquitectura propia y controlada.
- Aceptar más trabajo de herramientas y edición.

### Decisión sugerida

Realizar dos pruebas pequeñas, cronometrar el tiempo y elegir la opción que permita mantener el proyecto a largo plazo. No crear todavía un motor KMP propio.

## 2. Decisiones de diseño provisionales

- Android es la primera publicación.
- La arquitectura debe admitir otras plataformas.
- El juego es 2D, cenital y horizontal.
- Lela es la protagonista.
- La tensión limita disparar, dash y habilidades.
- Rebobinar es la habilidad de supervivencia.
- El estilo es teatro de títeres y recortes de papel.
- El primer contenido es un vertical slice de 5–10 minutos.
- El primer motor se decide con una prueba.
- La primera versión es local y sin cuentas.

## 3. Decisiones pendientes

- [ ] Motor.
- [ ] Nombre final.
- [ ] Número de personajes en la versión inicial.
- [ ] Número final de enemigos.
- [ ] Publicación en Google Play desde el primer lanzamiento.
- [ ] Demo o versión completa de pago.
- [ ] Idioma inicial adicional.
- [ ] Soporte de mando.
- [ ] Soporte de una sola mano.
- [ ] Resolución y escala final.
- [ ] Modelo de monetización.
- [ ] Sincronización en la nube.
- [ ] Nivel de violencia y clasificación por edad.

## 4. Backlog de producción inicial

### P0 — Antes de crear contenido

- [ ] Comparar Godot y libGDX.
- [ ] Crear proyecto de prueba.
- [ ] Implementar movimiento táctil.
- [ ] Implementar dash.
- [ ] Implementar tensión básica.
- [ ] Implementar rebobinado mínimo.
- [ ] Probar guardado local.
- [ ] Exportar a Android.
- [ ] Exportar a escritorio.
- [ ] Definir una prueba de silueta.
- [ ] Crear Lela provisional.
- [ ] Crear una sala rectangular.

### P1 — Vertical slice

- [ ] Soldado de estaño.
- [ ] Caja de música.
- [ ] Caja de Cero.
- [ ] Tijeras de precisión.
- [ ] Resorte saltador.
- [ ] Imán de hierro.
- [ ] Caja de música como amuleto.
- [ ] Ojo de vidrio.
- [ ] Hilo tensado.
- [ ] Tornillos y corcho.
- [ ] Pegamento de juguete.
- [ ] Bobina de reparación.
- [ ] Seis a diez interacciones.
- [ ] Inicio de partida.
- [ ] Resumen de partida.
- [ ] Muerte y reinicio.

### P2 — Prototipo completo

- [ ] Grafo de habitaciones.
- [ ] Selección de puertas.
- [ ] Cofres.
- [ ] Taller.
- [ ] Sala secreta.
- [ ] Sala de riesgo.
- [ ] Acto I completo.
- [ ] Segundo acto.
- [ ] Tercer acto.
- [ ] Jefes restantes.
- [ ] Semillas.
- [ ] Progresión de objetos.
- [ ] Estadísticas.
- [ ] Audio adaptativo.
- [ ] Guardado versionado.

### P3 — Producción inicial

- [ ] Arte final.
- [ ] Animaciones definitivas.
- [ ] Música final.
- [ ] Más combinaciones.
- [ ] Lugares de historia.
- [ ] Opciones de accesibilidad.
- [ ] Iconos de tienda.
- [ ] Política de privacidad.
- [ ] Pruebas de dispositivos.
- [ ] Compilación candidata.

## 5. Checklist de diseño de una mecánica

Antes de implementar:

- [ ] ¿Tiene una regla comprensible?
- [ ] ¿Se puede explicar en una frase?
- [ ] ¿Tiene una limitación interesante?
- [ ] ¿Cambia una decisión?
- [ ] ¿Tiene respuesta visual?
- [ ] ¿Tiene respuesta sonora?
- [ ] ¿Funciona en pantalla pequeña?
- [ ] ¿Es compatible con el guardado?
- [ ] ¿Se puede probar aislada?
- [ ] ¿Se puede retirar sin romper otras mecánicas?

## 6. Checklist de una habitación

- [ ] Tiene una función clara.
- [ ] La entrada es segura.
- [ ] La salida es visible.
- [ ] Los peligros tienen aviso.
- [ ] El presupuesto de dificultad es adecuado.
- [ ] Existe una solución con el ataque inicial.
- [ ] Funciona con distintos objetos.
- [ ] Puede repetirse sin volverse injusta.
- [ ] Puede reproducirse con una semilla.
- [ ] Funciona en distintos tamaños de pantalla.

## 7. Checklist de un objeto

- [ ] Es útil sin sinergia.
- [ ] Tiene una identidad clara.
- [ ] Su coste o limitación es justo.
- [ ] Se puede obtener en una partida normal.
- [ ] Se entiende en el inventario.
- [ ] Sus efectos tienen respuesta audiovisual.
- [ ] Se ha probado con sus combinaciones.
- [ ] No rompe el ritmo.
- [ ] Está equilibrado.
- [ ] Está documentado.

## 8. Checklist de un enemigo

- [ ] Se reconoce a tamaño móvil.
- [ ] Tiene un ataque principal.
- [ ] El ataque tiene aviso.
- [ ] Tiene una debilidad o interacción.
- [ ] Funciona en una sala pequeña.
- [ ] Se puede derrotar de más de una forma.
- [ ] Su muerte aporta algo.
- [ ] Su animación no oculta el peligro.
- [ ] Está equilibrado.
- [ ] Está probado con varios objetos.

## 9. Checklist de un jefe

- [ ] La primera fase enseña el patrón.
- [ ] La segunda fase cambia la estrategia.
- [ ] La transición es segura.
- [ ] Los ataques son visibles.
- [ ] La vida y el daño son justos.
- [ ] La combinación de la jugadora tiene una contraestrategia.
- [ ] El ataque inicial funciona.
- [ ] La sala tiene espacio para moverse.
- [ ] El final es claro.
- [ ] El tiempo de la pelea es adecuado.

## 10. Checklist de una compilación

- [ ] Compila desde limpio.
- [ ] Se instala en el dispositivo de referencia.
- [ ] Guarda y carga.
- [ ] Pausa y reanudación.
- [ ] Audio funciona.
- [ ] No tiene recursos provisionales visibles.
- [ ] No tiene errores de licencia conocidos.
- [ ] La telemetría es correcta.
- [ ] La versión aparece en la pantalla correcta.
- [ ] La partida se puede terminar.
- [ ] Se ha probado el informe de errores.

## 11. Ideas futuras para guardar

Estas ideas no entran en el primer alcance:

- Más personajes con armas y diseños propios.
- Taller de creación de títeres.
- Contratos de reparación de juguetes.
- Modo de desafíos con semillas diarias.
- Nuevas zonas en el almacén.
- Jefes de temporada.
- Editor de combinaciones de prueba.
- Una campaña corta de títeres.
- Un modo limitado con el reloj como protagonista.
- Una segunda biografía de jefe.
- Módulos para una secuela.
- Un modo cooperativo local, solo si el núcleo es estable.

## 12. Registro de decisiones

Cada decisión importante debe registrar:

- Fecha.
- Problema.
- Opciones.
- Opción elegida.
- Motivo.
- Consecuencias.
- Fecha de revisión.
- Estado: provisional, confirmada o reemplazada.

## 13. Próxima sesión de trabajo

1. Crear dos carpetas de prueba del motor.
2. Hacer el movimiento táctil.
3. Añadir dash y tensión.
4. Añadir una forma provisional de Lela.
5. Exportar a Android y escritorio.
6. Comparar tiempo, comodidad y mantenimiento.
7. Elegir motor.
8. Eliminar la prueba perdedora.
9. Crear la primera sala del vertical slice.

## 14. Criterio para detenerse

Antes de añadir una funcionalidad, preguntar:

> ¿Esto demuestra la fantasía central del juego o solo añade trabajo?

Si no responde claramente que sí, se puede posponer.
