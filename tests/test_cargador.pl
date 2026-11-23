/** <module> Pruebas del cargador seguro y de la expansión de macros. */

:- begin_tests(cargador).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').
:- use_module('../prolog/macros_biblioteca').
:- use_module('../prolog/cargador', [cargar_codigo/3]).
:- use_module('../prolog/validador', [validar/3]).

codigo_canonical("\c
acertijo(isla_1, \"Tres isleños\").\n\c
entidades([a, b, c]).\n\c
atributo(tipo, [caballero, truhan]).\n\c
pista(1, a, es(b, truhan)).\n\c
pista(2, b, es(c, truhan)).\n\c
pista(3, c, igual_tipo(a, b)).\n").

test(carga_correcta) :-
    codigo_canonical(Codigo),
    cargar_codigo(Codigo, Hechos, []),
    length(Hechos, 6),
    member(hecho(pista(3, c, igual(a, b, tipo)), _), Hechos).

test(directiva_rechazada) :-
    cargar_codigo(":- initialization(halt).", [], [err(1, _, _, _)]).

test(consulta_rechazada) :-
    cargar_codigo("?- halt.", [], [err(1, _, _, _)]).

test(variable_rechazada) :-
    cargar_codigo("acertijo(X, \"x\").", [], [err(1, _, _, _)]).

test(bloque_desconocido_rechazado) :-
    cargar_codigo("\c
    acertijo(x, \"X\").\n\c
    entidades([a]).\n\c
    atributo(tipo, [caballero, truhan]).\n\c
    pista(1, a, shell(whoami)).", Hechos, []),
    validador:validar(Hechos, _, Errores),
    memberchk(err(4, 1, 'Bloque no registrado en una afirmación.', _), Errores).

test(macro_circular_rechazada) :-
    cargar_codigo("\c
    acertijo(x, \"X\").\n\c
    foo(X) :- bar(X).\n\c
    bar(X) :- foo(X).", [], Errores),
    memberchk(err(_, _, 'Macro circular: no puede llamarse a sí misma.', _), Errores).

test(macro_de_biblioteca_expandida) :-
    cargar_codigo("pista(1, a, todos([a,b], caballero)).", Hechos, []),
    Hechos = [hecho(pista(1, a, al_menos(2, [a,b], caballero)), 1)].

:- end_tests(cargador).
