# 10 · Catálogo de tipos de acertijos (resultado de la Fase 0)

> Estado: **completo**. Esta fase decide el conjunto final de bloques de la biblioteca.
> No hay enunciados de exámenes anteriores en `examples/`, así que se priorizan las
> fuentes clásicas citadas al final.

## 1. Principio de diseño derivado de la investigación

Todos los tipos estudiados se reducen a la misma estructura:

1. un conjunto finito de **entidades**;
2. uno o varios **atributos** con dominio finito (el `tipo` de hablante es sólo un atributo más);
3. **afirmaciones** con valor de verdad booleano, unas ligadas a un hablante (regla de veracidad) y otras globales;
4. conectivas y **conteos** sobre entidades o sobre afirmaciones.

Eso permite un único motor (restricciones sobre dominios finitos + booleanos reificados) y una
biblioteca pequeña y ortogonal. Lo que distingue a un "tipo" de acertijo de otro es únicamente
qué atributos y qué bloques se usan, no el motor.

## 2. Catálogo

### Tipo A · Caballeros y truhanes clásicos (Smullyan)

- **Ejemplo** (Wikipedia, *Knights and Knaves*, "Both knaves"): Alice dice «los dos somos truhanes».
  Como ningún truhán puede admitir que lo es, Alice es truhán y Bob caballero.
- **Estructura lógica**: dominio `tipo = {caballero, truhan}`; para cada pista
  `pista(I, H, F)`: `tipo(H)=caballero ↔ F` y `tipo(H)=truhan ↔ ¬F`.
- **Bloques**: `entidades/1`, `atributo/2`, `pista/3`, `es/2`, `igual/3`, `distinto/3`,
  `y/2`, `o/2`, `no/1`, `si/2`, `sii/2`, `xor/2`.
- **Observación**: la autorreferencia («soy truhán») no necesita un bloque especial; `es(H, truhan)`
  ya se evalúa sobre la asignación completa, incluido el propio hablante.

### Tipo B · Normales y alternantes (variantes de Smullyan)

- **Ejemplo**: en la variante documentada por Wikipedia, además de caballeros y truhanes hay
  *alternantes* (alternan entre mentir y decir la verdad) y *normales* (pueden decir cualquier cosa).
  Rosenhouse estudia además los *neutros*.
- **Estructura lógica**: se añaden valores al mismo atributo `tipo`.
  - `normal`: la pista **no impone ninguna restricción** (no hay regla de veracidad).
  - `alternante`: sea `P_H` un booleano fresco que indica si su **primera** afirmación es verdadera.
    La enésima afirmación de `H` (ordenada por `Id` de pista) es verdadera iff
    `P_H XOR paridad(n)`; es decir `F_n ↔ (P_H ⊕ (n mod 2 = 0))`.
- **Bloques**: los mismos del tipo A; la regla de veracidad vive en el **registro de hablantes**,
  no en el núcleo. Añadir un tipo nuevo = añadir una cláusula.
- **Decisión derivada**: el orden de alternancia se deduce del `Id` de las pistas (no se añade un
  argumento extra), para mantener `pista/3` con aridad fija. Queda documentado en `doc/02`.

### Tipo C · Puertas y guardias (Laberinto / "la dama o el tigre")

- **Ejemplo** (Wikipedia, *Knights and Knaves* → "Fork in the road"; *The hardest logic puzzle ever*):
  dos guardias, uno miente y otro dice la verdad; una puerta lleva al castillo y otra a la muerte.
  La pregunta-clásico «¿qué diría el otro guardia...?» es una composición de `si`/`sii`/`no`.
- **Estructura lógica**: entidades `guardia1, guardia2, puerta1, puerta2`; atributos
  `tipo = {caballero, truhan}` y `estado = {valida, invalida}`; se pide que exactamente una
  puerta sea válida.
- **Bloques**: `es/2`, `exactamente/3` (sobre entidades+valor), `restriccion/1`, más las
  conectivas. No hace falta ningún bloque específico de "puertas".

### Tipo D · Colores, sombreros y casas

- **Ejemplo** (Wikipedia, *Induction puzzles*, "Basic hat puzzle"): tres jugadores con sombrero
  rojo o azul; todos levantan la mano si ven un sombrero rojo; nadie acierta de inmediato y
  alguien deduce que los tres son rojos. En su versión estática (la que soporta este proyecto)
  se modela como restricciones de conteo sobre colores.
- **Estructura lógica**: `atributo(color, [rojo, azul])`; pistas del tipo `es(a, rojo)` y
  conteos `al_menos/3`, `exactamente/3`; si los colores son únicos, `todos_distintos/2`.
- **Bloques**: `es/2`, `al_menos/3`, `a_lo_sumo/3`, `exactamente/3`, `todos_distintos/2`,
  `igual/3`, `distinto/3`.
- **Límite**: la componente epistémica dinámica («nadie respondió en el turno 1») queda fuera
  del alcance de Fase 1; se registra como limitación en `doc/00`.

### Tipo E · Asignación tipo cuadrícula (cebra / Einstein)

- **Ejemplo** (Wikipedia, *Zebra Puzzle*, edición *Life International*, 17-12-1962): cinco casas,
  cinco nacionalidades, cinco colores, cinco bebidas, cinco mascotas; pistas como «el noruego vive
  en la primera casa» o «la casa verde está inmediatamente a la derecha de la marfileña».
- **Estructura lógica**: variables `X_{entidad,atributo}` con dominio indexado por el orden en que
  se escriben los valores; `todos_distintos/2` por atributo; relaciones de posición
  (`vecino/3`, `antes/3`) sobre el atributo posición. Es un CSP estándar y de hecho el acertijo
  de la cebra se usa como *benchmark* de solvers CSP.
- **Bloques**: `atributo/2`, `todos_distintos/2`, `vecino/3`, `antes/3`, `es/2`, `igual/3`,
  `distinto/3`, `restriccion/1`.
- **Decisión derivada**: el orden de un atributo se define por el orden de su lista de valores,
  no por comparación de átomos; así `atributo(posicion, [uno,dos,tres,cuatro,cinco])` funciona
  sin operadores numéricos en la sintaxis del usuario.

### Tipo F · Afirmaciones de conteo y autorreferentes

- **Ejemplo** (Wikipedia, *Self-reference puzzle*): «hay ___ e's en esta frase»; en el estilo
  caballeros/truhanes: «exactamente dos de estas tres afirmaciones son falsas».
- **Estructura lógica**: hace falta contar **fórmulas verdaderas**, además de contar entidades con
  un valor. Por eso el vocabulario incluye dos aridades para los mismos nombres:
  `exactamente(2, [F1,F2,F3])` cuenta fórmulas; `exactamente(2, [a,b,c], truhan)` cuenta
  entidades. La paradoja del mentiroso se modela con `sii(F, no(F))` y da como resultado
  "sin solución", que el analizador debe informar en español.
- **Bloques**: `al_menos/2`, `a_lo_sumo/2`, `exactamente/2`, `no/1`, `sii/2`.

## 3. Conjunto final de bloques decidido

| Categoría | Bloques (functor/aridad) |
|---|---|
| Estructura | `acertijo/2`, `entidades/1`, `atributo/2`, `pista/3`, `restriccion/1` |
| Atómicos | `es/2`, `igual/3`, `distinto/3`, `vecino/3`, `antes/3`, `todos_distintos/2` |
| Conectivas | `y/2`, `o/2`, `no/1`, `si/2`, `sii/2`, `xor/2` |
| Conteo | `al_menos/2`, `a_lo_sumo/2`, `exactamente/2`, `al_menos/3`, `a_lo_sumo/3`, `exactamente/3` |
| Macros de biblioteca (no núcleo) | `igual_tipo/2`, `distinto_tipo/2`, `todos/2`, `alguno/2`, `ninguno/2`, `sigue/3` |

**Por qué estos y no otros**: son composables (toda afirmación es un término del mismo lenguaje),
ortogonales (conteo ≠ conectiva ≠ posición) y insuficientes para escribir código arbitrario.
Los tipos A–F se cubren sin añadir bloques específicos de dominio; por ejemplo "puerta válida"
es simplemente un valor de un atributo.

## 4. Fuentes

1. Wikipedia, *Knights and Knaves* — https://en.wikipedia.org/wiki/Knights_and_Knaves  
   (Smullyan, *What Is the Name of This Book?*, 1978; variantes con normales y alternantes;
   Goodman 1931; "fork in the road"/Laberinto).
2. Wikipedia, *The hardest logic puzzle ever* — https://en.wikipedia.org/wiki/The_Hardest_Logic_Puzzle_Ever  
   (Boolos 1996; True/False/Random; los dos guardias y las dos puertas; trucos con bicondicionales).
3. J. Rosenhouse, *Knights, Knaves, Normals, and Neutrals*, College Mathematics Journal 45(4), 2014
   — citado en la fuente 2.
4. Wikipedia, *Zebra Puzzle* — https://en.wikipedia.org/wiki/Zebra_Puzzle  
   (Life International, 1962; uso como benchmark de CSP; versión estándar de 5 casas).
5. Wikipedia, *Induction puzzles* (incluye *Hat puzzle*) — https://en.wikipedia.org/wiki/Induction_puzzles.
6. Wikipedia, *Self-reference puzzle* — https://en.wikipedia.org/wiki/Self-reference_puzzle.
7. SWI-Prolog manual, *library(clpfd)* — https://www.swi-prolog.org/man/clpfd.html  
   (reificación `#<==>`, `all_distinct/1`, `global_cardinality/2`, `labeling/2`).
8. SWI-Prolog manual, `call_with_time_limit/2` — https://www.swi-prolog.org/pldoc/man?predicate=call_with_time_limit/2.
