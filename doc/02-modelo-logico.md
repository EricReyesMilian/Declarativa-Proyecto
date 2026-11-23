# 02 · Modelo lógico

> Estado: implementado. Definiciones formales verificadas con `make test`.

## 1. Datos de un acertijo

Un acertijo es una colección de hechos:

- `acertijo(Id, Titulo)` — exactamente uno.
- `entidades(Es)` — exactamente uno; `Es` es una lista de átomos distintos.
- `atributo(Nombre, Valores)` — uno o más; `Valores` es una lista ordenada de átomos distintos.
  El orden de la lista define el orden del atributo para `vecino/3` y `antes/3`.
- `pista(Id, Hablante, F)` — cero o más; `Id` entero positivo único; `Hablante` es una entidad
  o el átomo `ninguno`.
- `restriccion(F)` — cero o más; equivale a `pista(Id, ninguno, F)` con un Id interno.

Restricción de bien-formación: un valor de atributo pertenece a **un único** atributo, para que
`es(E, V)` sea inequívoco.

## 2. Variables del modelo

Para cada entidad `e` y atributo `a` con dominio de tamaño `k` se crea una variable CLP(FD)
`X_{e,a} ∈ {0,…,k-1}` que codifica el índice del valor elegido. Cada átomo `es(e, v)` se traduce a
`X_{e,a(v)} = índice(v)`. Las conectivas se traducen a booleanos 0/1 y reificación (`#<==>`,
`#\/`, `#/\`, `#\`, `#==>`, `#<==>`).

## 3. Regla de veracidad

Para una pista `pista(I, H, F)` con `T_H = X_{H,tipo}`:

| `T_H` | Restricción |
|---|---|
| `caballero` | `B_I #<==> F`, con `B_I = 1` |
| `truhan` | `B_I #<==> F`, con `B_I = 0` |
| `normal` | ninguna restricción sobre `F` |
| `alternante` | `B_I #<==> (P_H ⊕ paridad(I))`, donde `P_H ∈ {0,1}` es fresco por hablante y `paridad(I)=0` si es su 1.ª, 3.ª, 5.ª… afirmación en orden de `Id`; `=1` si es la 2.ª, 4.ª… |
| `ninguno` | `F` debe ser verdadero (`B_I = 1`) |

La paridad se calcula ordenando las pistas de `H` por `Id` y contando desde 1. Así se mantiene
`pista/3` con aridad fija y se permite añadir tipos de hablante sin tocar el núcleo: basta una
cláusula nueva en `bloques/hablantes.pl`.

Nota: `normal` y `ninguno` son distintos. `normal` emite una afirmación sin restricción;
`ninguno` es un hecho global que **debe** cumplirse.

## 4. Definiciones formales

Sea `V` el vector de variables del modelo y `C` el conjunto de restricciones resultante.

- **Asignación completa**: valor concreto para cada variable de `V`.
- **Solución**: asignación completa que satisface `C`.
- `Sol(P)` = conjunto de soluciones del acertijo `P`.
- **Tiene solución**: `Sol(P) ≠ ∅`.
- **Solución única**: `|Sol(P)| = 1`. (No hay simetrías por renombrado: las variables están
  indexadas por entidad y atributo.)
- **Irredundancia**: para cada pista/restricción `c`, sea `P−c` el acertijo sin esa cláusula.
  `c` es *sobrante* si `|Sol(P−c)| = 1`. El conjunto es irredundante si ninguna cláusula lo es.
  Quitar una cláusula puede dar 0 soluciones (era necesaria) o varias (era necesaria para la
  unicidad); sólo "sigue siendo única" implica sobrante.
- **Minimalidad fuerte**: un subconjunto `S` de cláusulas es mínimo si `|Sol(S)| = 1` y para todo
  `c ∈ S`, `|Sol(S−c)| ≠ 1`. Se busca el de menor tamaño; es exponencial en el número de pistas
  y se aplica el límite configurable `max_clausulas` (por defecto 12; por encima se informa
  `inconcluso`).

## 5. Traducción de los bloques de conteo

- `al_menos(N, [E1,…,Em], v)`: `Σ_i [X_{Ei,a(v)} = índice(v)] #>= N`.
- `a_lo_sumo(N, …)`: `#=< N`; `exactamente(N, …)`: `#= N`.
- `al_menos(N, [F1,…,Fm])`: `Σ_i B_i #>= N`, donde `B_i` es el booleano reificado de `Fi`.
  Igual para las otras dos aridades.
- `todos_distintos(a, [E1,…,Em])`: `all_distinct([X_{E1,a},…,X_{Em,a}])`.

## 6. Casos límite

- Un acertijo sin pistas tiene `k^(n·a)` soluciones; se informa del número con tope, no se enumeran todas.
- Una afirmación autorreferente paradójica (`sii(F, no(F))`) produce `Sol(P) = ∅`: se informa
  "el acertijo no tiene solución; revisa las pistas autorreferentes".
- Los alternantes con una sola afirmación tienen `P_H` libre pero la restricción sigue siendo
  determinista respecto de la verdad de esa afirmación; no se informa el valor de `P_H` al usuario.
