# 07 · Pruebas

> Estado: implementado. `make test` ejecuta 30 pruebas plunit.

## Ejecución

```sh
make test          # suite completa
make docs-check    # documentos y cabeceras de módulos
make verificar     # ambas
```

Sin Makefile:

```sh
swipl -q -g run_tests -t halt tests/test_all.pl
```

## Módulos cubiertos

| Archivo | Contenido |
|---|---|
| `tests/test_bloques.pl` | registro central (28 bloques), categorías, tipos de hablante, multifile |
| `tests/test_cargador.pl` | lectura segura, directivas/consultas/variables, bloques desconocidos, ciclos de macros, expansión |
| `tests/test_validador.pl` | acertijo canónico, Id repetido, `ninguno` reservado, dominio de tipo inválido |
| `tests/test_solver_fd.pl` | solución canónica, inconsistencia, ambigüedad y comparación con el oráculo naive |
| `tests/test_analisis.pl` | unicidad, irredundancia, minimalidad fuerte, opciones por defecto |
| `tests/test_explicacion.pl` | explicación en español coherente con la solución |
| `tests/test_servidor.pl` | opciones de la API, mapeo de errores, JSON de soluciones, ejemplos |

## Casos límite verificados con `curl`

- `POST /api/analizar` con `shell(whoami)` en una pista → error
  "Bloque no registrado en una afirmación", sin ejecutar código.
- `GET /api/ejemplo?id=../prompt.md` → 404, sin salir del directorio de ejemplos.
- Acertijo inconsistente → `estado: inconsistente`.
- Acertijo ambiguo → `estado: multiple` con varias soluciones.
