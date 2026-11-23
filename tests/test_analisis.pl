/** <module> Pruebas de existencia, unicidad, irredundancia y minimalidad. */

:- begin_tests(analisis).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').
:- use_module('../prolog/macros_biblioteca').
:- use_module('../prolog/cargador', [cargar_archivo/3]).
:- use_module('../prolog/validador', [validar/3]).
:- use_module('../prolog/analisis', [analizar/3]).

:- prolog_load_context(directory, Dir),
   directory_file_path(Dir, '../examples', Ejemplos0),
   absolute_file_name(Ejemplos0, Ejemplos, [file_type(directory)]),
   assertz(directorio_cargar_ejemplos(Ejemplos)).

cargar_ejemplo(Nombre, Puzzle) :-
    directorio_cargar_ejemplos(Dir),
    directory_file_path(Dir, Nombre, Base),
    atom_concat(Base, '.pl', Ruta),
    cargar_archivo(Ruta, Hechos, []),
    validar(Hechos, Puzzle, []).

test(canonical, [setup(true)]) :-
    once(cargar_ejemplo(isla_1, Puzzle)),
    analizar(Puzzle, opciones{limite:10, tiempo:5, minimalidad:true}, Informe),
    Informe.estado == unico,
    Informe.unica == true,
    Informe.irreductible == true,
    Informe.minimalidad_fuerte == verdadera,
    Informe.soluciones == [[sol(a,[tipo-truhan]), sol(b,[tipo-caballero]), sol(c,[tipo-truhan])]].

test(inconsistente) :-
    once(cargar_ejemplo(inconsistente, Puzzle)),
    analizar(Puzzle, opciones{}, Informe),
    Informe.estado == inconsistente,
    Informe.numero_soluciones =:= 0.

test(ambiguo) :-
    once(cargar_ejemplo(ambiguo, Puzzle)),
    analizar(Puzzle, opciones{}, Informe),
    Informe.estado == multiple,
    Informe.unica == false.

test(opciones_defecto) :-
    once(cargar_ejemplo(isla_3, Puzzle)),
    analizar(Puzzle, opciones{}, Informe),
    memberchk(Informe.estado, [unico, multiple]).

:- end_tests(analisis).
