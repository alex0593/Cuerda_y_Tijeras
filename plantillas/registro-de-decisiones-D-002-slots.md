# D-002 — Slots provisionales de mecanismo y amuleto

- **ID:** D-002
- **Fecha:** 2026-09-25
- **Estado:** anulada por D-005 (2026-09-26)
- **Área:** diseño / balance

> **Anulada.** D-005 («sin límite de huecos») deja obsoleto el reparto de espacios: todo lo que
> aparece se puede llevar, así que el problema que motivó esta decisión ya no existe. Se conserva
> el registro porque explica por qué el inventario pasó a ser de huecos libres.

## Problema
El inventario de un espacio por mecanismo y amuleto hace imposibles varias sinergias documentadas: imán + tornillos, música + hilo y otras combinaciones de objetos del mismo slot.

## Opción elegida
Mantener un espacio de arma, dos espacios provisionales de mecanismo, dos de amuleto y hasta cuatro consumibles durante el vertical slice H2.

## Motivo
Permite probar las sinergias sin cambiar sus identidades ni eliminar reglas de diseño. La ampliación queda limitada al prototipo y se revisará con el playtest.

## Consecuencias
- Ventajas: las combinaciones del contenido son alcanzables y el HUD puede mostrar dos elementos por slot.
- Desventajas: aumenta ligeramente la complejidad visual del inventario móvil.
- Riesgo: aceptar dos objetos donde la documentación inicial pedía uno; revisar antes de producción.

## Revisión
- **Fecha de revisión:** después del playtest H2
- **Resultado:**
- **Nueva decisión relacionada:** D-001
