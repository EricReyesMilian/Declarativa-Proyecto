# Proyecto: Plataforma de acertijos lógicos (Caballeros y Truhanes y variantes) en Prolog + interfaz web

Proyecto universitario de **Programación Declarativa**. Construye desde cero, en un directorio nuevo, una aplicación en **SWI-Prolog 9** para **escribir, analizar y resolver** acertijos lógicos de tipo caballeros y truhanes y sus variantes (colores, puertas válidas, etc.), pensados para exámenes de lógica. Prioriza código declarativo, simple y modificable por estudiantes.

## Idea central

Los acertijos **no se generan automáticamente**: el usuario los **escribe como código Prolog**. La facilidad de uso NO viene de un lenguaje casi natural ni de un parser, sino de:

1. una **sintaxis mínima y regular**, que es Prolog plano (hechos y términos compuestos);
2. una **biblioteca de bloques** reutilizables y bien documentados;
3. una **interfaz web** con paleta de plantillas que inserta el código por el usuario.

## Restricciones de diseño sobre la sintaxis (obligatorias)

- **Sin DCG, sin parser propio, sin lenguaje natural.** Un acertijo es un archivo `.pl` cuyos hechos se leen con el propio Prolog (`read_term/3`, o `consult` dentro de un módulo aislado).
- **Sin operadores personalizados** en español. Solo notación funcional estándar de Prolog. Como mucho, se permiten los operadores que Prolog ya trae (`,`, `;`, `->`, `\+`, `=`) si de verdad simplifican; no definas `op/3` nuevos salvo que lo justifiques en `doc/08-decisiones.md`.
- Nombres de functores **cortos, en minúsculas y consistentes**, con pocos conceptos que aprender. Preferir un vocabulario pequeño y componible antes que muchos predicados especializados.
- Una pista = **un hecho** con numeración explícita: `pista(Id, Hablante, Afirmacion).`

Ejemplo del estilo buscado (los nombres son una propuesta; refínalos en el diseño):

```prolog
% isla_1.pl
acertijo(isla_1, "Tres isleños").

entidades([a, b, c]).
atributo(tipo, [caballero, truhan]).

pista(1, a, es(b, truhan)).
pista(2, b, igual_tipo(a, c)).
pista(3, c, al_menos(1, [a, b, c], truhan)).
restriccion(exactamente(2, [a, b, c], caballero)).
```

Otras variantes con el mismo estilo:

```prolog
atributo(color, [rojo, azul, verde]).
pista(1, a, es(b, rojo)).
restriccion(todos_distintos(color, [a, b, c])).

pista(1, guardia1, es(puerta2, valida)).
pista(2, guardia2, o(es(puerta1, valida), es(puerta3, valida))).
```

Las conectivas se escriben como términos: `y(F1, F2)`, `o(F1, F2)`, `no(F)`, `si(F1, F2)`, `sii(F1, F2)`, `xor(F1, F2)`, y los cuantificadores/conteos como `al_menos(N, Lista, Valor)`, `a_lo_sumo`, `exactamente`, `todos`, `alguno`, `ninguno`. (Propuesta, ajustable.) El hablante de una pista puede ser también `ninguno` para un **hecho global** sin regla de veracidad.

## Biblioteca de bloques

Un bloque es simplemente un **functor** con su semántica registrada (cómo se traduce a restricciones del solver). Reglas:

- Registro **declarativo y central** de bloques: un único lugar donde se declara, por bloque, su nombre/aridad, su descripción, su traducción al solver y (en Fase 2) su regla de explicación. Añadir un bloque nuevo debe ser **agregar una entrada/cláusula**, no tocar el núcleo.
- Permitir que el usuario defina **macros** en su propio archivo, como reglas Prolog normales que se expanden a bloques existentes, por ejemplo `vecino(X, Y, F) :- ...` o `mentiroso(X) :- ...`, sin parser adicional.
- Cada bloque documentado con: sintaxis, ejemplo, semántica y cómo se traduce al motor.

## Fase 0: Investigación (antes de diseñar)

Usa búsqueda web para catalogar los tipos de acertijos de este estilo y sus patrones. Cubre al menos:

- Caballeros y truhanes clásicos (Smullyan) y variantes con **normales** y **alternantes**.
- **Puertas** (válida/inválida, guardias que mienten o dicen verdad, "la dama o el tigre").
- **Colores** (sombreros, casas, objetos).
- **Asignación tipo cuadrícula** (cebra/Einstein) si encaja en el mismo motor.
- Afirmaciones de **conteo** y **autorreferentes**.
  Entrega `doc/10-catalogo-tipos-acertijos.md` con cada tipo, un ejemplo, su estructura lógica y qué bloques de la biblioteca lo cubren, citando las fuentes. Si el usuario deja enunciados de exámenes anteriores en `examples/`, tómalos como prioridad. **El resultado de esta fase decide el conjunto final de bloques** (pocos, ortogonales, composables).

## Objetivos funcionales

### Fase 1 (obligatoria)

1. **Cargar y validar** un acertijo escrito en Prolog plano. La validación debe dar mensajes **en español, con Id de pista y sugerencia** (entidad no declarada, valor fuera del dominio, aridad incorrecta de un bloque, Id duplicado, etc.). Nunca mostrar trazas crudas de Prolog al usuario final. Los errores de sintaxis de Prolog también se capturan y se traducen a un mensaje legible con línea.
2. **Analizar** y reportar:
   - ¿Tiene solución?
   - ¿Es única? Si no, listar soluciones (con tope).
   - ¿El conjunto de pistas es **minimal**? Dos niveles:
     - **Irredundancia**: quitar cualquier pista rompe la unicidad (N análisis, rápido). Indicar qué pistas sobran.
     - **Minimalidad fuerte** (opcional, con límite configurable, por defecto ~20 pistas): subconjunto de tamaño mínimo con solución única. Es exponencial; avisar al superar el límite.
3. **Resolver**: mostrar la asignación completa.
4. **Motor**: evalúa `library(clpb)` frente a `library(clpfd)` con reificación (`#<==>`). Como hay atributos multivaluados, el motor unificado probablemente sea **CLP(FD) con 0/1 para los booleanos**. Decide, justifica en `doc/08-decisiones.md` y deja un **solver de respaldo generar-y-probar** para validar resultados en los tests.
5. **Interfaz web** (servidor HTTP en Prolog con `library(http/thread_httpd)`, `http_dispatch`, `http_json`; frontend en HTML + CSS + JS vanilla, sin npm ni build):
   - **Editor de código Prolog** (textarea con numeración de líneas y resaltado muy simple de los functores del proyecto, sin librerías externas).
   - **Paleta de bloques/plantillas**: botones que **insertan fragmentos de código** en el editor ("Pista: A dice que B es truhán", "Conteo: al menos N", "Todos distintos", "Nuevo acertijo de caballeros", "Nuevo acertijo de colores", "Nuevo acertijo de puertas"). Cada plantilla con marcadores editables y una breve explicación. Las plantillas viven en un archivo de datos (`web/plantillas.json`) generado o sincronizado con el registro de bloques, para que añadir un bloque lo exponga también en la paleta.
   - **Asistente guiado (deseable)**: formulario donde se elige hablante, bloque y argumentos, y que **genera la línea de código Prolog** y la inserta en el editor. Esto es lo que hace el proyecto fácil de usar sin necesidad de un parser.
   - Panel de **errores clicables** que llevan a la línea.
   - Botón **Analizar** con resultados legibles.
   - Galería de **ejemplos** cargables (de `examples/`) y botones guardar/descargar el `.pl`.
   - Interfaz simple y responsive.
6. **Seguridad**: el servidor no ejecuta código arbitrario. Lee el archivo con `read_term`, acepta solo cláusulas con cabezas en una **lista blanca** (`acertijo/2`, `entidades/1`, `atributo/2`, `pista/3`, `restriccion/1`, macros validadas) y evalúa solo en un módulo aislado, con límite de tiempo y memoria. Documenta el modelo en `doc/11-seguridad.md`.

### Fase 2 (diseñada desde el inicio, implementada después)

**Explicación paso a paso de las deducciones.** Motor de inferencia explícito, distinto del solver de restricciones, que registre una traza:

- **Propagación**: de una pista y valores conocidos se deduce un valor.
- **Casos / reducción al absurdo**: "supongamos que A es caballero → contradicción con la pista 3, luego A es truhán".
- Cada paso guarda pista(s) usada(s), hipótesis activas, conclusión y justificación en español.
- La web lo muestra con botones Siguiente/Anterior.
- Si no basta, indicarlo y verificar con el solver.
- Cada bloque aporta su **regla de explicación** en el registro de bloques, para que bloques nuevos sean explicables sin tocar el motor.
- Documenta en `doc/` alternativas consideradas y razones.

## Arquitectura sugerida (ajústala justificando en doc/)

```
acertijos/
├── README.md
├── doc/                          <- OBLIGATORIO
├── prolog/
│   ├── main.pl
│   ├── bloques.pl                (registro central de bloques)
│   ├── bloques/                  (conectivas.pl, conteo.pl, atributos.pl, hablantes.pl)
│   ├── cargador.pl               (lectura segura, lista blanca, macros)
│   ├── validador.pl              (errores amigables)
│   ├── solver_fd.pl
│   ├── solver_naive.pl
│   ├── analisis.pl
│   ├── explicacion.pl            (Fase 2)
│   └── servidor.pl
├── web/                          (index.html, app.js, style.css, plantillas.json)
├── examples/                     (acertijos .pl y enunciados de examen)
└── tests/                        (plunit, un archivo por módulo)
```

## Carpeta `doc/` (requisito explícito)

Para que otra persona modifique el proyecto sin leer todo el código:

1. `00-vision-general.md`: qué hace, alcance de fases, limitaciones.
2. `01-arquitectura.md`: módulos, responsabilidades, dependencias, diagrama Mermaid.
3. `02-modelo-logico.md`: semántica de los tipos de hablante, traducción pista → restricción, definiciones formales de solución, unicidad, irredundancia, minimalidad.
4. `03-como-escribir-acertijos.md`: **manual del usuario**: estructura de un archivo, referencia de todos los bloques con ejemplos y una plantilla completa. Es el documento principal para quien crea ejercicios.
5. `04-api-web.md`: endpoints, JSON, ejemplos con `curl`.
6. `05-algoritmos.md`: unicidad, irredundancia, minimalidad fuerte (complejidad y causa del límite), motor de la Fase 2.
7. `06-guia-de-modificacion.md`: recetas "añadir un bloque nuevo (registro + traducción + explicación + plantilla web + test)", "añadir un tipo de hablante", "añadir un tipo de atributo", "cambiar el solver", "añadir un endpoint".
8. `07-pruebas.md`: ejecutar y ampliar tests.
9. `08-decisiones.md`: ADR cortos con alternativas descartadas.
10. `09-glosario.md`.
11. `10-catalogo-tipos-acertijos.md`: resultado de la Fase 0.
12. `11-seguridad.md`.
    Al terminar cada fase, verifica que lo documentado coincida con el código real.

## Requisitos de calidad

- PlDoc (`%!`) en cada predicado público.
- Tests `plunit`: cargador (válidos, inválidos, intentos de inyección de código), validador (cada mensaje), semántica de cada bloque, acertijos clásicos con solución única, múltiple y ninguna, coincidencia solver principal vs. naive, irredundancia y minimalidad en casos pequeños.
- `examples/` con al menos 10 acertijos: caballeros/truhanes, normales y alternantes, puertas, colores, conteo, autorreferencia, solución única/múltiple/ninguna y pistas redundantes.
- `Makefile` con `make test`, `make run` y `make docs-check`.
- Límites de tiempo/memoria por análisis (`call_with_time_limit`) con mensaje claro.
- Mensajes siempre en español; sin dependencias fuera de las librerías estándar de SWI-Prolog.

## Forma de trabajo

1. Empieza con la Fase 0 y el esqueleto de `doc/`. Propón el **vocabulario de bloques** (nombres y aridades) y un acertijo de ejemplo completo, y **confírmalo conmigo antes de implementar**. Debe ser pequeño y fácil de recordar.
2. Implementa por módulos con tests: registro de bloques → cargador y validador → solver → análisis → servidor y web (editor, paleta, asistente) → Fase 2.
3. Ejecuta los tests tras cada módulo; no avances con tests en rojo.
4. Termina la Fase 1 de extremo a extremo (escribir un acertijo en el editor, validarlo y analizarlo) antes de la Fase 2.
5. Entrega un resumen final de lo implementado, limitaciones y cómo ejecutar todo.z
