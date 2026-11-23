/** <module> Pruebas de validación semántica y mensajes en español. */

:- begin_tests(validador).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').
:- use_module('../prolog/macros_biblioteca').
:- use_module('../prolog/cargador', [cargar_codigo/3]).
:- use_module('../prolog/validador', [validar/3]).

validar_codigo(Codigo, Puzzle, Errores) :-
    cargar_codigo(Codigo, Hechos, ErroresCarga),
    ( ErroresCarga == [] -> validar(Hechos, Puzzle, Errores)
    ; Puzzle = error, Errores = ErroresCarga
    ).

test(canonical_valido) :-
    validar_codigo("\c
    acertijo(isla_1, \"Tres isleños\").\n\c
    entidades([a, b, c]).\n\c
    atributo(tipo, [caballero, truhan]).\n\c
    pista(1, a, es(b, truhan)).\n\c
    pista(2, b, es(c, truhan)).\n\c
    pista(3, c, igual_tipo(a, b)).", Puzzle, []),
    Puzzle.id == isla_1,
    length(Puzzle.pistas, 3),
    Puzzle.attrs = [att(tipo, [caballero, truhan])].

test(falta_acertijo) :-
    validar_codigo("entidades([a]).", _, Errores),
    memberchk(err(0, null, 'Falta el hecho acertijo/2.', _), Errores).

test(entidad_ninguno_reservada) :-
    validar_codigo("\c
    acertijo(x, \"X\").\n\c
    entidades([a, ninguno]).\n\c
    atributo(tipo, [caballero, truhan]).", _, Errores),
    member(err(_, _, 'ninguno está reservado como hablante global.', _), Errores).

test(pista_id_duplicado) :-
    validar_codigo("\c
    acertijo(x, \"X\").\n\c
    entidades([a, b]).\n\c
    atributo(tipo, [caballero, truhan]).\n\c
    pista(1, a, es(b, truhan)).\n\c
    pista(1, b, es(a, truhan)).", _, Errores),
    memberchk(err(5, null, 'Identificador de pista repetido.', _), Errores).

test(dominio_tipo_invalido) :-
    validar_codigo("\c
    acertijo(x, \"X\").\n\c
    entidades([a]).\n\c
    atributo(tipo, [rojo, azul]).", _, Errores),
    member(err(_, _, 'El atributo tipo contiene valores que no son hablantes registrados.', _), Errores).

:- end_tests(validador).
