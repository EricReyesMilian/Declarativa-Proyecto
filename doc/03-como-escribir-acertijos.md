# 03 · Cómo escribir acertijos (manual del usuario)

> Estado: **confirmado e implementado**. Vocabulario y ejemplo aprobados por el usuario en Fase 0.

## 1. Estructura de un archivo

Es Prolog plano: comentarios con `%`, hechos terminados en `.` y nada más. Sin directivas, sin
operadores nuevos, sin consultas.

```prolog
% mi_acertijo.pl
acertijo(mi_acertijo, "Título legible").

entidades([a, b, c]).
atributo(tipo, [caballero, truhan]).

pista(1, a, es(b, truhan)).
pista(2, b, es(c, truhan)).
pista(3, c, igual_tipo(a, b)).
```

## 2. Vocabulario registrado (nombre/aridad)

### Cabecera

| Bloque | Ejemplo | Significado |
|---|---|---|
| `acertijo/2` | `acertijo(isla_1, "Tres isleños").` | Id y título |
| `entidades/1` | `entidades([a,b,c]).` | Entidades del acertijo |
| `atributo/2` | `atributo(color, [rojo,azul,verde]).` | Atributo y su dominio ordenado |
| `pista/3` | `pista(1, a, es(b,truhan)).` | Id, hablante, afirmación |
| `restriccion/1` | `restriccion(exactamente(2,[a,b,c],caballero)).` | Hecho global (sin hablante) |

### Afirmaciones atómicas

| Bloque | Ejemplo | Significado |
|---|---|---|
| `es/2` | `es(b, truhan)` | `b` tiene ese valor en el atributo que lo contiene |
| `igual/3` | `igual(a, c, tipo)` | mismo valor del atributo |
| `distinto/3` | `distinto(a, c, tipo)` | distinto valor del atributo |
| `vecino/3` | `vecino(casa1, casa2, posicion)` | posiciones consecutivas |
| `antes/3` | `antes(casa1, casa2, posicion)` | posición estrictamente menor |
| `todos_distintos/2` | `todos_distintos(color, [a,b,c])` | los valores son distintos dos a dos |

### Conectivas

`y(F1,F2)`, `o(F1,F2)`, `no(F)`, `si(F1,F2)`, `sii(F1,F2)`, `xor(F1,F2)`.

### Conteo (dos aridades con el mismo nombre)

| Forma | Ejemplo | Cuenta |
|---|---|---|
| `/3` | `al_menos(1, [a,b,c], truhan)` | entidades con ese valor |
| `/2` | `al_menos(2, [F1,F2,F3])` | afirmaciones verdaderas |

Igual para `a_lo_sumo` y `exactamente`.

### Macros de biblioteca (disponibles por defecto)

`igual_tipo(X,Y)` = `igual(X,Y,tipo)`; `distinto_tipo(X,Y)`;
`todos(L,V)` = `al_menos(N,L,V)` con `N = longitud(L)`; `alguno(L,V)` = `al_menos(1,L,V)`;
`ninguno(L,V)` = `exactamente(0,L,V)`; `sigue(X,Y,A)` = `vecino(X,Y,A)` y `antes(X,Y,A)`.

### Hablantes

El hablante de `pista/3` es una entidad, o `ninguno` para un hecho global sin regla de veracidad.
Los valores previstos para el atributo `tipo` son `caballero`, `truhan`, `normal` y `alternante`
(su semántica en `doc/02`). Otros atributos de tipo pueden declararse con otro nombre.

### Macros del usuario

Se pueden definir reglas propias como abreviaturas de bloques ya existentes:

```prolog
mentiroso(X) :- es(X, truhan).
```

El cargador las expande por sustitución y rechaza cualquier cuerpo que use un functor no
registrado, además de detectar ciclos aunque la macro no se llegue a usar. No se ejecutan como
código Prolog arbitrario.

## 3. Acertijo de ejemplo completo (canónico verificado)

```prolog
% isla_1.pl
acertijo(isla_1, "Tres isleños").

entidades([a, b, c]).
atributo(tipo, [caballero, truhan]).

pista(1, a, es(b, truhan)).
pista(2, b, es(c, truhan)).
pista(3, c, igual_tipo(a, b)).
```

**Resultado esperado**: solución única `a = truhan`, `b = caballero`, `c = truhan`.
Comprobación rápida:

- Pista 1: `a` es truhán, luego «b es truhán» es falso ⇒ `b = caballero`. ✔
- Pista 2: `b` es caballero, luego «c es truhán» es verdadero ⇒ `c = truhán`. ✔
- Pista 3: `c` es truhán, luego «a y b son del mismo tipo» es falso; en efecto son distintos. ✔

Las tres pistas son **irredundantes**: si se quita cualquiera, aparecen dos soluciones.
Este acertijo servirá como caso de prueba de extremo a extremo.

## 4. Plantilla completa para un acertijo de puertas

```prolog
acertijo(puertas_1, "Los dos guardias").

entidades([guardia1, guardia2, puerta1, puerta2]).
atributo(tipo, [caballero, truhan]).
atributo(estado, [valida, invalida]).

pista(1, guardia1, es(puerta2, valida)).
pista(2, guardia2, es(puerta1, valida)).

restriccion(exactamente(1, [puerta1, puerta2], valida)).
restriccion(es(guardia1, caballero)).
restriccion(distinto(guardia1, guardia2, tipo)).
```

## 5. Decisiones confirmadas

1. Vocabulario registrado: 28 entradas, incluidas las dos aridades de conteo.
2. Cuatro tipos de hablante (`caballero`, `truhan`, `normal`, `alternante`) más `ninguno`
   como hablante global; alternancia ordenada por `Id`.
3. Ejemplo canónico `examples/isla_1.pl`, con solución única y tres pistas irredundantes.
4. Proyecto creado en la raíz del repositorio.
