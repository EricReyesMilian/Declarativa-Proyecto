# 08 · Decisiones (ADR cortos)

> Estado: decisiones confirmadas en Fase 0 y aplicadas en la implementación.

## ADR-001 · CLP(FD) con booleanos 0/1 como motor principal

- **Decisión**: usar `library(clpfd)` con reificación (`#<==>`, `#\/`, `#/\`, `#\`, `#==>`) y
  codificar cada atributo multivaluado como un entero (índice en el dominio).
- **Alternativas**: `library(clpb)` (CLP(B)) y un solver propio SAT.
- **Razones**: CLP(B) es excelente para fórmulas puramente booleanas, pero obliga a codificar
  cada atributo de `k` valores como `k` variables one-hot con restricciones de "exactamente uno",
  y no ofrece `all_distinct/1` ni conteos globales. CLP(FD) da `all_distinct/1`,
  `global_cardinality/2` y reificación en la misma librería y mantiene una sola representación
  para atributos y verdad. Se conserva `solver_naive.pl` (generar-y-probar) como oracle en tests.
- **Fuente**: SWI-Prolog manual de CLP(FD) y CLP(B).

## ADR-002 · Sintaxis = Prolog plano, sin parser ni operadores nuevos

- **Decisión**: `read_term/3` sobre el texto, lista blanca de cabezas, términos compuestos para
  las conectivas. No se define `op/3`.
- **Alternativas**: DCG/parser de un lenguaje casi natural; DSL con operadores en español.
- **Razones**: el objetivo es que el estudiante vea exactamente el código que ejecuta; un parser
  añadiría una capa que hay que mantener, documentar y proteger. Los nombres son cortos y se
  componen igual que en Prolog.

## ADR-003 · Alternantes ordenados por Id de pista

- **Decisión**: la afirmación n-ésima de un hablante alternante se decide por la posición de su
  pista en el orden numérico de `Id`, con un booleano fresco para la primera.
- **Alternativas**: añadir un argumento `turno` a `pista/4`; alternar por posición textual.
- **Razones**: mantiene `pista/3` y evita depender del orden de escritura del archivo.

## ADR-004 · Macros expandidas por sustitución, nunca consultadas

- **Decisión**: las macros del usuario son reglas Prolog leídas como datos; el cargador sustituye
  variables y expande el cuerpo sólo si todos sus functors están registrados.
- **Alternativas**: `consult/1` del archivo en un módulo aislado y llamar a las macros como
  predicados.
- **Razones**: `consult/1` ejecutaría directivas y cualquier código del archivo; la expansión por
  sustitución mantiene la lista blanca también dentro de los cuerpos. El módulo aislado se usa
  sólo para evaluar términos del modelo, no para ejecutar el archivo del usuario.

## ADR-005 · Explicación como motor independiente (Fase 2)

- **Decisión**: un encadenamiento de reglas con traza, distinto del solver de restricciones; el
  solver se usa para verificar y para los casos en que la deducción no basta.
- **Alternativas**: extraer la traza del solver (difícil de traducir a lenguaje natural y acoplada
  a la estrategia de `labeling`); generar texto plantilla a partir de las restricciones.
- **Razones**: separar ambos motores permite que cada bloque aporte su propia regla de explicación
  en el registro, sin tocar el núcleo.

## ADR-006 · Documentación como requisito de entrega

- **Decisión**: 12 documentos numerados en `doc/`, uno por módulo o decisión, y `make docs-check`.
- **Razones**: el proyecto debe ser modificable por otros estudiantes sin leer todo el código.
