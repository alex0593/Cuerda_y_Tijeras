# Cuerda y Tijeras

> Roguelite de acción 2D para Android, pensado desde el inicio para una futura adaptación a otras plataformas.

**Estado:** preproducción  
**Versión del documento:** 0.2  
**Plataforma inicial:** Android  
**Plataformas futuras posibles:** Windows, Linux, macOS, iOS y web  
**Género:** roguelite cenital de acción, exploración de habitaciones y combinaciones de objetos  
**Estilo visual propuesto:** títeres de sombra, recortes de papel y juguetes mecánicos  
**Motor:** pendiente de una prueba técnica; Godot 4.x es la opción más rápida y libGDX + Kotlin la opción si Kotlin es prioritario  
**Duración objetivo:** 10–15 minutos por partida  
**Orientación:** horizontal  

## Concepto

Controlas a **Lela**, una muñeca de cuerda que despierta en un taller de juguetes incapable de terminar su última representación. Sus herramientas son piezas del propio taller: tijeras, resortes, imanes, botones, hilos, llaves y cajas de música. Al combinar esos objetos, la jugador crea armas y habilidades nuevas.

La cuerda que da vida a Lela también controla su energía. Disparar, hacer dash y activar habilidades consume **tensión**. Cuando está a cero, Lela se ralentiza y sus cortes se debilitan. La habilidad **Rebobinado** devuelve la acción unos segundos hacia atrás para escapar de una situación peligrosa.

## Diferenciales

- **Combate móvil:** dos joysticks, acción rápida y partidas breves.
- **Energía y rebobinado:** la tensión condiciona cada decisión.
- **Objetos combinables:** las sinergias no aumentan solamente el daño; cambian el comportamiento.
- **Teatro de títeres:** siluetas, papel, madera, metal, hilos y sombras reducen la dependencia de sprites detallados.
- **Todo local:** la primera versión no necesita cuenta, servidor ni conexión.
- **Arquitectura portable:** el núcleo del juego no dependerá de APIs de Android.

## Objetivo del primer prototipo

El primer objetivo es un **vertical slice** de 5–10 minutos, no el juego completo. Debe incluir:

- Un personaje jugable.
- Movimiento, apuntado, disparo, dash y rebobinado.
- Una habitación modular.
- Dos o tres enemigos.
- Un jefe de prueba.
- Ocho objetos.
- Entre seis y diez interacciones entre objetos.
- Una partida corta con jefe.
- Arte provisional pero legible.
- Audio provisional.
- Exportación funcional para Android y escritorio.

## Documentación

1. [Concepto y pilares](documentacion/01-concepto-y-pilares.md)
2. [Mecánicas y bucle de juego](documentacion/02-mecanicas-y-bucle.md)
3. [Mundo, historia y personajes](documentacion/03-mundo-historia-y-personajes.md)
4. [Enemigos y jefes](documentacion/04-enemigos-y-jefes.md)
5. [Objetos y sinergias](documentacion/05-objetos-y-sinergias.md)
6. [Arte, sprites y animación](documentacion/06-arte-sprites-y-animacion.md)
7. [Niveles y generación](documentacion/07-niveles-y-generacion.md)
8. [Audio, experiencia y accesibilidad](documentacion/08-audio-experiencia-y-accesibilidad.md)
9. [Tecnología, multiplataforma y arquitectura](documentacion/09-tecnologia-y-arquitectura.md)
10. [Alcance y producción](documentacion/10-alcance-y-produccion.md)
11. [Monetización, legal y publicación](documentacion/11-monetizacion-legal-y-publicacion.md)
12. [Pruebas, riesgos y métricas](documentacion/12-pruebas-riesgos-y-metricas.md)
13. [Backlog, decisiones y checklists](documentacion/13-backlog-decisiones-y-checklists.md)

También se incluyen plantillas en [`plantillas/`](plantillas/) para registrar objetos, enemigos, habitaciones, recursos y publicaciones.

## Decisiones provisionales

| Tema | Recomendación |
|---|---|
| Lanzamiento inicial | Android |
| Arquitectura | Multiplataforma desde el diseño |
| Orden técnico sugerido | Android, escritorio, iOS y web |
| Motor | Comparar Godot con libGDX + Kotlin |
| Orientación | Horizontal |
| Cámara | Cenital y fija por habitación |
| Control | Dos joysticks táctiles |
| Ataque | Manual, con asistencia opcional |
| Partida | 10–15 minutos |
| Estilo | Títeres de sombra y recortes de papel |
| Personajes finales | 2–3; uno en el prototipo |
| Enemigos finales | 8–10; dos o tres en el prototipo |
| Jefes finales | 3; uno en el prototipo |
| Objetos finales | 24–30; ocho en el prototipo |
| Sinergias finales | 20–30; seis a diez en el prototipo |
| Progresión | Variedad y descubrimientos, sin repetición grindosa |
| Servidor | No en la primera versión |

## Próximo paso

Realizar una prueba técnica breve con dos opciones:

1. **Godot 4.x**, para comprobar rapidez y facilidad de exportación.
2. **libGDX + Kotlin**, para comprobar cuánto trabajo exige mantener Kotlin.

La prueba debe incluir movimiento táctil, disparo, dash, una animación de títer, guardado y exportación a Android y escritorio. Después se elige una herramienta y se empieza el vertical slice; no se produce arte final antes de validar el juego.
