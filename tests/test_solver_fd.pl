/** <module> Pruebas del solver CLP(FD) frente al oráculo naive. */

:- begin_tests(solver_fd).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').
:- use_module('../prolog/macros_biblioteca').
:- use_module('../prolog/cargador', [cargar_archivo/3]).
:- use_module('../prolog/validador', [validar/3]).
:- use_module('../prolog/solver_fd', []).
:- use_module('../prolog/solver_naive', []).

:- dynamic cargar_ejemplo_puzzle/2.

:- prolog_load_context(directory, Dir),
   directory_file_path(Dir, '../examples', Ejemplos0),
   absolute_file_name(Ejemplos0, Ejemplos, [file_type(directory)]),
   assertz(directorio_cargar_ejemplos(Ejemplos)).

cargar_ejemplo(Nombre, Puzzle) :-
    ( cargar_ejemplo_puzzle(Nombre, Guardado) -> Puzzle = Guardado
    ; directorio_cargar_ejemplos(Dir),
      directory_file_path(Dir, Nombre, Base),
      atom_concat(Base, '.pl', Ruta),
      cargar_archivo(Ruta, Hechos, []),
      validar(Hechos, Puzzle, []),
      assertz(cargar_ejemplo_puzzle(Nombre, Puzzle))
    ).

test(canonical_unico) :-
    cargar_ejemplo(isla_1, Puzzle),
    solver_fd:resolver(Puzzle, opciones{limite:10}, Soluciones, _),
    Soluciones == [[sol(a,[tipo-truhan]), sol(b,[tipo-caballero]), sol(c,[tipo-truhan])]].

test(inconsistente_sin_soluciones) :-
    cargar_ejemplo(inconsistente, Puzzle),
    solver_fd:resolver(Puzzle, opciones{limite:10}, Soluciones, _),
    Soluciones == [].

test(ambiguo_cuatro) :-
    cargar_ejemplo(ambiguo, Puzzle),
    solver_fd:resolver(Puzzle, opciones{limite:10}, Soluciones, _),
    length(Soluciones, 4).

test(oraculo_naive_coincide, [nondet, forall(member(N, [isla_1, isla_2, alternantes, conteo, conteo_afirmaciones, macros]))]) :-
    once(cargar_ejemplo(N, Puzzle)),
    solver_fd:resolver(Puzzle, opciones{limite:100}, FD, _),
    solver_naive:resolver(Puzzle, opciones{limite:100}, Naive, _),
    msort(FD, OrdenadosFD),
    msort(Naive, OrdenadosNaive),
    assertion(OrdenadosFD == OrdenadosNaive).

:- end_tests(solver_fd).
