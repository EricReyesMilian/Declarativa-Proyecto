# 11 · Seguridad

> Estado: implementado y verificado con pruebas de inyección y peticiones `curl`.

## 1. Principio

El servidor **no ejecuta código arbitrario**. El texto que llega a `/api/analizar` se trata como
datos: se lee término a término y se interpreta mediante el registro de bloques. Nunca se llama
a `consult/1`, `assert/1` ni a `call/1` sobre términos del usuario.

## 2. Capas

1. **Lectura**: `read_term/3` con `syntax_errors(error)`, `term_position` y `variable_names`.
   Los errores de sintaxis se capturan y se traducen a un mensaje en español con la línea.
2. **Lista blanca de cabezas**: sólo `acertijo/2`, `entidades/1`, `atributo/2`, `pista/3`,
   `restriccion/1` y definiciones de macros. Se rechazan directivas (` :- ...`), consultas
   (`?- ...`), módulos, `dynamic`, `assert`, `halt`, `shell`, etc.
3. **Variables libres**: cualquier variable en un hecho se rechaza. Los valores son átomos o
   enteros concretos; las afirmaciones se validan contra el registro con aridad exacta.
4. **Macros validadas**: el cuerpo se inspecciona término a término contra el registro de
   bloques y otras macros; se rechazan functors ajenos, número incorrecto de argumentos,
   macros duplicadas y ciclos (detectados aunque la macro no se use). La expansión es por
   sustitución de variables, sin `call/1`.
5. **Rutas acotadas**: `/api/ejemplo?id=...` sólo busca `Id.pl` dentro de `examples/`. Se
   rechazan barras y el Id debe corresponder a un ejemplo que carga y valida sin errores.
6. **Límites**: `call_with_time_limit/2` por análisis (`tiempo` 1…10 s), tope de soluciones
   (`limite` 1…100) y `max_clausulas=12` para la minimalidad fuerte. Las peticiones JSON
   mal formidas se tratan como código vacío, nunca como excepciones sin controlar.
7. **Salida**: esquema JSON cerrado; nunca se devuelve una traza cruda de Prolog. Las
   excepciones del análisis y de la explicación se convierten en mensajes en español.

## 3. Amenazas consideradas

| Amenaza | Mitigación |
|---|---|
| `:- halt.` / `shell('rm -rf ...')` en el código | Directivas y cabezas no permitidas rechazadas en capas 2–3 |
| `pista(1, a, (shell(...), true))` | `,/2` no es un bloque registrado; el validador lo rechaza |
| Macro que llama a `assertz/1` | Cuerpo de macro validado contra el registro |
| Bucle infinito en una macro | Detección de ciclos con pila de specs visitados |
| Acertijo exponencial | Tiempo límite, tope de soluciones y `inconcluso` en minimalidad |
| Fuga de información del sistema | Respuestas JSON con esquema cerrado, sin excepciones crudas |
| Path traversal en `/api/ejemplo` | Id sin barras, unido a `examples/` y comprobado contra ejemplos válidos |

## 4. Verificación

- `tests/test_cargador.pl`: directivas, consultas, variables libres, bloque desconocido,
  ciclo de macros, expansión de `todos/2`.
- `curl -X POST /api/analizar` con `pista(1, a, shell(whoami))` → `ok:false`, error
  "Bloque no registrado en una afirmación.", sin ejecución.
- `curl /api/ejemplo?id=../prompt.md` → 404 con `error: "Ejemplo no encontrado."`.
- 12 ejemplos cargan y validan; los 30 tests de `make test` pasan.

Limitación conocida: no se impone un límite de tamaño de cuerpo HTTP ni un límite global en el
servlet; el servidor está pensado para uso local o aula, no para Internet público.
