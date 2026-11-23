# 05 · Algoritmos

> Estado: implementado. Parámetros reales: `limite=100`, `tiempo=5`,
> `minimalidad=false`, `max_clausulas=12`.

## 1. Resolución

1. El cargador lee términos con `read_term/3`, rechaza directivas, variables libres y
   cabezas no permitidas, y expande macros. El validador comprueba dominios, aridades,
   Ids y referencias.
2. `solver_fd.pl` construye el modelo: una variable CLP(FD) por (entidad, atributo),
   booleanos reificados para cada afirmación y restricciones traducidas desde el registro
   de bloques (`trad_fd/3`).
3. `labeling/2` enumera hasta un tope de soluciones. El parámetro `limite` se acota a
   1…100 en la API y `analisis/3` usa al menos 2 para poder detectar multiples.
4. `solver_naive.pl` genera asignaciones completas y evalúa las mismas fórmulas con
   `eval_naive/3`; se usa como oráculo independiente en las pruebas.

## 2. Unicidad

`|Sol(P)| = 1` contando como máximo `limite` soluciones. Si se alcanza el tope se informa
`estado: multiple` y `aviso: "Hay varias soluciones; se muestran las primeras."`.
No hay simetrías por renombrado de variables.

## 3. Irredundancia

Para cada cláusula `c` (pistas y restricciones): resolver `P−c` y comprobar si sigue siendo
única con esa misma solución. Coste: `N` análisis, lineal en el número de cláusulas.
Las que siguen siendo únicas se devuelven en `pistas_sobrantes`.

## 4. Minimalidad fuerte

Búsqueda por tamaños crecientes de subconjuntos de cláusulas con `|Sol(S)| = 1`; se devuelve
`verdadera` o `falsa(IdsMasCorto)`. Es exponencial (`2^N` peor caso). Si el número de
cláusulas supera `max_clausulas` (12 por defecto), se devuelve `inconcluso` sin ejecutar
la búsqueda. Desactivada por defecto; se activa con `minimalidad: true`.

## 5. Límites

`call_with_time_limit/2` (`library(time)`) envuelve cada análisis. `tiempo` se acota a 1…10
segundos (5 por defecto). Si se excede, se captura `time_limit_exceeded` y se devuelve
`estado: timeout` con el aviso "El análisis superó el tiempo permitido; reduce entidades
o pistas". Cualquier otra excepción se traduce a `estado: error`.

## 6. Motor de explicación (Fase 2)

`explicacion.pl` reconstruye la explicación a partir de la primera solución: para cada
pista evalúa la afirmación con `eval_naive/3` y aplica la regla del tipo de hablante con
`regla_hablante_naive/6`; para cada restricción muestra si se cumple. Cada bloque aporta
su texto con `regla_explicacion/3`. Es una explicación *verificadora*, no un motor de
propagación independiente; por eso siempre coincide con la semántica del solver.
Alternativas consideradas en `doc/08`.
