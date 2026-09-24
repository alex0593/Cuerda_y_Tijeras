# D-001 — Motor

- **ID:** D-001
- **Fecha:** 2026-09-24
- **Estado:** confirmada
- **Área:** tecnología

## Problema
Elegir motor para vertical slice (doc 09/13): Godot 4.x + GDScript vs libGDX + Kotlin.

## Opciones consideradas
1. Godot 4.x — editor visual, ruta rápida Android+escritorio, GDScript.
2. libGDX + Kotlin — mantiene Kotlin, más infraestructura manual.
3. Prototipo lógica en Python — solo reglas, luego portar.

## Opción elegida
Godot 4.x (4.3 estable verificado) para producción del slice.

## Motivo
Prioridad terminar y publicar con menos infraestructura (doc 09.4). Equipo pequeño, juego 2D, necesidad de editor, partículas, UI y exportación rápida.

## Consecuencias
- Ventajas: iteración rápida, export desktop como prueba de portabilidad, GL Compatibility para Android gama media.
- Desventajas: no se usa Kotlin; núcleo en GDScript separado por autoloads/interfaces para no atar a Android.
- Riesgos: requisitos de firma/paquetes por plataforma; web al final.
- Plataformas afectadas: Android primero, desktop validación, iOS/web después.

## Revisión
- **Fecha de revisión:** tras H0 (export escritorio + prueba táctil)
- **Resultado:**
- **Nueva decisión relacionada:**
