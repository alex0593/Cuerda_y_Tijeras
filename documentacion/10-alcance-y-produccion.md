# 10. Alcance y producción

## 1. Estrategia de alcance

El proyecto debe crecer mediante prototipos validados. No se producen todos los enemigos, objetos o animaciones finales antes de comprobar que el combate resulta divertido en pantalla móvil.

La prioridad es:

1. Movimiento y lectura.
2. Combate y tensión.
3. Una habitación clara y functional.
4. Una sinergia entre objetos.
5. Un jefe.
6. Estilo visual.
7. Contenido adicional.
8. Monetización y adaptaciones a otras plataformas.

## 2. Fase 0 — Preparación

### Objetivo

Reducir las decisiones desconocidas antes de construir el juego.

### Actividades

- Comparar Godot y libGDX con una prueba técnica.
- Definir controles táctiles.
- Crear un personaje provisional.
- Probar dash, tensión y rebobinado.
- Probar una animación de títer.
- Exportar a Android y escritorio.
- Probar guardado local.
- Elegir una resolución y una paleta provisional.

### Resultado esperado

Una decisión de motor, un estilo técnico básico y una lista de riesgos conocidos.

## 3. Fase 1 — Vertical slice

### Objetivo

Crear una experiencia de 5 a 10 minutos que represente la calidad y el carácter del juego final.

### Contenido

- Lela jugable.
- Joysticks y botones táctiles.
- Movimiento, disparo, dash, tensión y rebobinado.
- Una sala modular.
- Un enemigo de carga.
- Un enemigo de proyectiles.
- Un jefe breve con dos fases.
- Ocho objetos.
- Seis a diez sinergias de prueba.
- Inicio, resumen y derrota.
- Música provisional y efectos básicos.

### Criterios de aprobación

- Una persona nueva comprende los controles.
- La tensión modifica de forma perceptible el uso de las acciones.
- Rebobinar resulta útil sin trivializar el combate.
- El estilo de títer se entiende en un dispositivo real.
- El slice puede ejecutarse en Android y escritorio.
- La mayoría de quienes lo prueban quiere jugar otra partida.

## 4. Fase 2 — Prototipo completo

### Objetivo

Crear una partida completa de 10 a 15 minutos con principio, dificultad creciente y final.

### Contenido

- Acto I completo.
- Seis a ocho habitaciones por ruta.
- Un jefe.
- Cuatro a seis enemigos.
- Entre doce y dieciocho objetos.
- Entre doce y veinte interacciones.
- Cofres, taller, salas de riesgo y una sala secreta.
- Progresión de objetos.
- Resumen de partida.
- Semillas reproducibles.
- Guardado y migración de versión.

### Criterios de aprobación

- La partida se puede terminar sin ayuda externa.
- Ningún objeto es inútil sin sinergias.
- La dificultad aumenta sin volverse arbitraria.
- Las salas ofrecen decisiones y no solo limpieza de enemigos.
- El ritmo de la partida cumple el objetivo de duración.

## 5. Fase 3 — Producción del contenido

### Contenido de la versión inicial comercial

- Tres actos.
- Dos o tres personajes, si el sistema lo justifica.
- Ocho a diez enemigos.
- Tres jefes.
- Veinticuatro a treinta objetos.
- Veinte a treinta interacciones.
- Más de cuarenta plantillas de habitación.
- Historia ambiental completa.
- Colección de objetos y sinergias.
- Semillas diarias.
- Localización inicial en español.
- Opciones de accesibilidad.

### Regla

Añadir contenido solo cuando el sistema base sea estable. Cada nuevo elemento debe superar una validación de utilidad, rendimiento y lectura.

## 6. Fase 4 — Acabado

- Pulido de animaciones.
- Partículas y transiciones.
- Música final o mezcla revisada.
- Diseño de iconos.
- Tutorial final.
- Localización y revisión de textos.
- Pruebas de rendimiento.
- Preparación de tienda.
- Corrección de errores prioritarios.
- Compilación de distribución.

## 7. Trabajo por disciplina

### Programación

- Bucle de juego.
- Entrada.
- Movimiento y colisiones.
- Tensión y rebobinado.
- Enemigos, objetos y sinergias.
- Generación y guardado.
- Servicios de plataforma.

### Arte

- Siluetas.
- Animaciones modulares.
- Objetos de decorado y escenarios.
- Jefes.
- Interfaz.
- Efectos visuales.

### Audio

- Música adaptativa sencilla.
- Efectos de combate.
- Ambiente.
- Interfaz.

### Diseño

- Bucle.
- Curva de dificultad.
- Objetos.
- Salas.
- Historia.
- Balance.

### Control de calidad

- Pruebas funcionales.
- Rendimiento.
- Guardado.
- Dispositivos.
- Compilaciones de distribución.
- Regresión.

## 8. Orden de desarrollo recomendado

1. Prueba técnica.
2. Prototipo de movimiento y cámara.
3. Tensión, dash y rebobinado.
4. Sala de combate.
5. Un enemigo.
6. Un objeto que cambie el ataque.
7. Un jefe de prueba.
8. Controles y ergonomía.
9. Generación básica.
10. Progreso y recompensas.
11. Arte y audio definitivos.
12. Actos y jefes restantes.
13. Balance.
14. Lanzamiento.

## 9. Dependencias

- No finalizar el arte antes de aprobar la silueta.
- No añadir un tercer acto antes de validar el primero.
- No crear una tienda antes de tener objetos y recompensas.
- No integrar nube antes de tener guardado local estable.
- No preparar iOS o web antes de demostrar el núcleo en Android y escritorio.

## 10. Equipo mínimo

### Una persona

Puede producir el proyecto si:

- Reduce el alcance inicial.
- Usa recursos modulares.
- Crea su propia música o utiliza recursos con licencia clara.
- Realiza sus propias pruebas.
- Acepta un lanzamiento pequeño.

### Varias personas

Funciones posibles:

- Programación.
- Arte.
- Audio.
- Diseño.
- Control de calidad parcial.

La primera versión no necesita un equipo grande. La consistencia de dirección es más importante que añadir muchas personas.

## 11. Presupuesto

Categorías:

- Motor y herramientas.
- Arte externo.
- Música y sonido.
- Dispositivos de prueba.
- Cuenta de tienda.
- Localización.
- Legal y licencias.
- Marketing.
- Reservas para correcciones.

No se debe comprar un paquete grande de recursos sin revisar su licencia y estilo. El arte modular puede reducir mucho el coste.

## 12. Criterios para recortar

Si el proyecto se retrasa, recortar en este orden:

1. Personajes adicionales.
2. Salas opcionales.
3. Objetos cosméticos.
4. Historia secundaria.
5. Variantes de enemigos.
6. Un acto completo, reduciendo la campaña.
7. Sinergias secundarias.

No recortar:

- Legibilidad del combate.
- Controles táctiles.
- Guardado fiable.
- Bucle de respuesta audiovisual.
- Audio básico.
- Accesibilidad esencial.
- Pruebas del dispositivo de referencia.

## 13. Hitos

| Hito | Resultado |
|---|---|
| H0 | Motor y controles decididos |
| H1 | Movimiento, dash y rebobinado funcionando |
| H2 | Sala y primer enemigo legibles |
| H3 | Vertical slice jugable |
| H4 | Acto I completo |
| H5 | Prototipo de partida completa |
| H6 | Contenido inicial completo |
| H7 | Compilación candidata de lanzamiento |
| H8 | Publicación inicial |

## 14. Definición de terminado

Una funcionalidad está terminada cuando:

- Funciona con la configuración principal.
- Tiene respuesta audiovisual.
- Está probada en el dispositivo de referencia.
- No bloquea la partida si falla un dato externo.
- Tiene documentación mínima.
- Mantiene el rendimiento dentro del presupuesto.
- Se ha añadido a la lista de regresión si es crítica.

## 15. Riesgos de producción

- El arte consume más tiempo del previsto.
- Las combinaciones generan demasiadas excepciones.
- El rebobinado rompe la lógica del juego.
- La partida resulta demasiado corta o demasiado larga.
- Los controles no se sienten bien en dispositivos pequeños.
- El generador produce salas injustas.
- La música y los efectos no cubren el ritmo de las partidas.

Cada riesgo debe probarse en una fase pequeña antes de añadir contenido.
