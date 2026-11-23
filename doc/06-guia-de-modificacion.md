# 06 · Guía de modificación

> Estado: implementado; recetas comprobadas contra el código.

## Añadir un bloque nuevo

1. Escribir su traducción en el archivo correspondiente de `prolog/bloques/`.
2. Registrar nombre/aridad, descripción, ejemplo y traducción en `prolog/bloques.pl` (una cláusula).
3. Añadir su regla de explicación (Fase 2) en el mismo registro.
4. Añadir una entrada en `web/plantillas.json` (o regenerarla desde el registro).
5. Documentarlo en `doc/03`.
6. Añadir un test en `tests/test_bloques.pl`.

## Añadir un tipo de hablante

Añadir una cláusula en `prolog/bloques/hablantes.pl` con la regla de veracidad; documentar su
semántica en `doc/02` y su valor en el dominio del atributo `tipo` de los ejemplos.

## Añadir un tipo de atributo

No requiere código: basta declarar `atributo(Nombre, Valores)` en el acertijo. Solo si el atributo
necesita una relación nueva (por ejemplo otra relación de orden) se añade un bloque.

## Cambiar el solver

Implementar el mismo interfaz que `solver_fd.pl` (devuelve soluciones como asignaciones) y
cambiar el módulo usado por `analisis.pl`. `solver_naive.pl` sirve de referencia.

## Añadir un endpoint

Registrar la ruta en `prolog/servidor.pl`, validar la entrada, devolver JSON con `http_json` y
documentarlo en `doc/04` con un `curl` de ejemplo.

## Regla de oro

Después de cualquier cambio: `make test` y comprobar que `doc/` sigue describiendo el código real.
