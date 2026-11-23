/** <module> Pruebas de las explicaciones en lenguaje natural. */

:- begin_tests(explicacion).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').
:- use_module('../prolog/macros_biblioteca').
:- use_module('../prolog/cargador', [cargar_archivo/3]).
:- use_module('../prolog/validador', [validar/3]).
:- use_module('../prolog/explicacion', [explicar/3]).

:- prolog_load_context(directory, Dir),
   directory_file_path(Dir, '../examples/isla_1.pl', Ruta0),
   absolute_file_name(Ruta0, Ruta, []),
   assertz(ruta_canonical(Ruta)).

test(explicacion_canonical) :-
    ruta_canonical(Ruta),
    cargar_archivo(Ruta, Hechos, []),
    validar(Hechos, Puzzle, []),
    once(( explicar(Puzzle, Solucion, Texto),
           Solucion == [sol(a,[tipo-truhan]), sol(b,[tipo-caballero]), sol(c,[tipo-truhan])],
           sub_atom(Texto, _, _, _, 'Pista 1 (a)'),
           sub_atom(Texto, _, _, _, 'coherente con un truhan: verdadero'),
           sub_atom(Texto, _, _, _, 'Pista 3 (c)')
         )).

:- end_tests(explicacion).
