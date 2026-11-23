:- module(cargador,
          [ cargar_codigo/3,
            cargar_archivo/3
          ]).

:- use_module(library(readutil)).
:- use_module(library(lists)).
:- use_module(bloques, [es_bloque/1, es_formula_bloque/1]).

/** <module> Cargador seguro de acertijos

Lee el texto del usuario con read_term/3 y lo trata exclusivamente como datos.
Nunca se consulta ni se ejecuta: se rechazan directivas, cabezas no permitidas,
variables libres en hechos y cuerpos de macro con functors ajenos al registro de
bloques. Las macros se validan y se expanden por sustitución de variables; sus
cuerpos pueden ser una afirmación o varias unidas por comas (equivalente a y/2).
*/

%!  cargar_codigo(+Codigo, -Hechos, -Errores) is det.
%
%   Codigo es un string. Hechos es una lista de hecho(Termino, Linea) ya
%   expandida. Errores es una lista de err(Linea, IdPista, Mensaje, Sugerencia).
%   Si hay errores, Hechos es [] para evitar trabajar con código parcial.

cargar_codigo(Codigo, Hechos, Errores) :-
    setup_call_cleanup(
        open_string(Codigo, Stream),
        leer_terminos(Stream, Crudos, ErroresLectura),
        close(Stream)),
    (   ErroresLectura \= []
    ->  Hechos = [], Errores = ErroresLectura
    ;   separar_terminos(Crudos, Hechos0, DefsMacros, ErroresSeparacion),
        preparar_macros(DefsMacros, Tabla, ErroresMacros),
        expandir_hechos(Hechos0, Tabla, HechosExpandidos, ErroresExpansion),
        append(ErroresSeparacion, ErroresMacros, E1),
        append(E1, ErroresExpansion, Errores),
        (   Errores == []
        ->  Hechos = HechosExpandidos
        ;   Hechos = []
        )
    ).

%!  cargar_archivo(+Ruta, -Hechos, -Errores) is det.
%
%   Igual que cargar_codigo/3 pero leyendo un archivo `.pl` del disco.

cargar_archivo(Ruta, Hechos, Errores) :-
    Errores = [],
    catch(read_file_to_string(Ruta, Codigo, []),
          _,
          ( Mensaje = 'No se pudo leer el archivo indicado.',
            Sugerencia = 'Comprueba que el archivo existe y tiene permisos de lectura.',
            Errores = [err(0, null, Mensaje, Sugerencia)],
            Hechos = [],
            Codigo = ''
          )),
    (   Errores == []
    ->  cargar_codigo(Codigo, Hechos, Errores)
    ;   true
    ).

% ------------------------------ lectura ------------------------------------

leer_terminos(Stream, Terminos, Errores) :-
    catch(read_term(Stream, Term,
                    [ syntax_errors(error),
                      term_position(Pos),
                      variable_names(Nombres)
                    ]),
          Excepcion,
          ( traducir_error_lectura(Excepcion, Err),
            Term = '__error_lectura__'
          )),
    (   Term == end_of_file
    ->  Terminos = [], Errores = []
    ;   Term == '__error_lectura__'
    ->  Terminos = [], Errores = [Err]
    ;   (   nonvar(Pos),
            stream_position_data(line_count, Pos, Linea)
        ->  true
        ;   Linea = 0
        ),
        Terminos = [crudo(Term, Linea, Nombres)|Resto],
        leer_terminos(Stream, Resto, Errores)
    ).

traducir_error_lectura(error(syntax_error(_), stream(_, Linea, _, _)),
                       err(Linea, null,
                           'Error de sintaxis en el código Prolog.',
                           'Revisa paréntesis, comas y el punto final de cada hecho.')) :-
    !.
traducir_error_lectura(_,
                       err(0, null,
                           'No se pudo leer el código Prolog.',
                           'Comprueba que los hechos terminen en punto.')).

% --------------------------- clasificación ---------------------------------

separar_terminos([], [], [], []).
separar_terminos([crudo(T, Linea, Nombres)|Cs], Hechos, Defs, Errores) :-
    separar_uno(T, Linea, Nombres, Hechos0, Defs0, Errores0),
    separar_terminos(Cs, Hechos1, Defs1, Errores1),
    append(Hechos0, Hechos1, Hechos),
    append(Defs0, Defs1, Defs),
    append(Errores0, Errores1, Errores).

separar_uno((:- _), Linea, _, [], [],
            [err(Linea, null,
                 'No se permiten directivas (:- ...) en un acertijo.',
                 'Escribe sólo hechos y definiciones de macros.')]) :-
    !.
separar_uno((?- _), Linea, _, [], [],
            [err(Linea, null,
                 'No se permiten consultas (?- ...) en un acertijo.',
                 'Escribe sólo hechos y definiciones de macros.')]) :-
    !.
separar_uno((Cabeza :- Cuerpo), Linea, _, [],
            [macro(Spec, Cabeza, Cuerpo, Linea, [])], []) :-
    !,
    functor(Cabeza, N, A),
    Spec = N/A.
separar_uno(T, Linea, Nombres, [hecho(T, Linea)], [], Errores) :-
    head_permitida(T),
    !,
    (   Nombres == []
    ->  Errores = []
    ;   Errores = [err(Linea, null,
                       'No se permiten variables libres en los hechos.',
                       'Sustituye la variable por un átomo concreto (por ejemplo a o caballero).')]
    ).
separar_uno(_, Linea, _, [], [],
            [err(Linea, null,
                 'Cabeza de hecho no permitida.',
                 'Usa acertijo/2, entidades/1, atributo/2, pista/3, restriccion/1 o una macro.')]).

head_permitida(T) :-
    nonvar(T),
    functor(T, N, A),
    memberchk(N/A, [acertijo/2, entidades/1, atributo/2, pista/3, restriccion/1]).

% ------------------------------ macros -------------------------------------

:- multifile macro_biblioteca/4.

%!  macro_biblioteca(+Spec, +Cabeza, +Cuerpo, +Calculos) is nondet.
%
%   Macro predefinida. Calculos son operaciones internas (por ejemplo longitud/2)
%   que se resuelven tras sustituir los argumentos de la llamada.

preparar_macros(Defs, Tabla, Errores) :-
    findall(macro(Spec, Cabeza, Cuerpo, Linea, []),
            member(macro(Spec, Cabeza, Cuerpo, Linea, []), Defs),
            Definidas),
    findall(macro(Spec, Cabeza, Cuerpo, 0, Calculos),
            macro_biblioteca(Spec, Cabeza, Cuerpo, Calculos),
            Biblioteca),
    append(Biblioteca, Definidas, Tablas),
    validar_macros(Tablas, Errores),
    (   Errores == []
    ->  Tabla = Tablas
    ;   Tabla = []
    ).

validar_macros(Tablas, Errores) :-
    findall(E, error_de_macro(Tablas, E), Errores0),
    sort(Errores0, Errores).

error_de_macro(Tablas, E) :-
    error_macro_ciclo(Tablas, E).
error_de_macro(Tablas, E) :-
    member(macro(Spec, Cabeza, _, Linea, _), Tablas),
    error_cabeza_macro(Spec, Cabeza, Linea, E).
error_de_macro(Tablas, E) :-
    error_macro_duplicada(Tablas, E).
error_de_macro(Tablas, E) :-
    member(macro(_, Cabeza, Cuerpo, Linea, Calculos), Tablas),
    Cabeza =.. [_|Vars],
    term_variables(Calculos, Calculadas),
    append(Vars, Calculadas, Permitidas),
    error_cuerpo_macro(Cuerpo, Permitidas, Tablas, Linea, E).

error_cabeza_macro(Spec, _, Linea,
                   err(Linea, null,
                       'El nombre de la macro ya está reservado por un bloque.',
                       'Elige otro nombre; los bloques y las cabezas de hecho no se pueden redefinir.')) :-
    es_bloque(Spec),
    !.
error_cabeza_macro(_/0, _, Linea,
                   err(Linea, null,
                       'Una macro debe tener al menos un argumento.',
                       'Escribe por ejemplo mentiroso(X) :- es(X, truhan).')) :-
    !.
error_cabeza_macro(_, Cabeza, Linea,
                   err(Linea, null,
                       'Los argumentos de una macro deben ser variables distintas.',
                       'Escribe por ejemplo vecino(X, Y, A) :- es(X, A), es(Y, A).')) :-
    Cabeza =.. [_|Args],
    \+ ( maplist(var, Args),
         sort(Args, SinRepetir),
         length(Args, N),
         length(SinRepetir, N)
       ),
    !.

%!  error_macro_ciclo(+Tablas, -Error) is nondet.
%
%   Detecta ciclos entre macros aunque ninguna de ellas llegue a usarse en una
%   pista. La búsqueda lleva una pila de specs visitados, así que termina incluso
%   con definiciones mutuamente recursivas.

error_macro_ciclo(Tablas,
                  err(Linea, null,
                      'Macro circular: no puede llamarse a sí misma.',
                      'Revisa las reglas de tus macros.')) :-
    member(macro(Spec, _, Cuerpo, Linea, _), Tablas),
    llamadas_macro(Cuerpo, Tablas, Llamados),
    member(Llamada, Llamados),
    alcanza_macro(Llamada, Tablas, [Spec]).

alcanza_macro(Spec, _, Visitados) :-
    memberchk(Spec, Visitados),
    !.
alcanza_macro(Spec, Tablas, Visitados) :-
    memberchk(macro(Spec, _, Cuerpo, _, _), Tablas),
    llamadas_macro(Cuerpo, Tablas, Llamados),
    member(Llamada, Llamados),
    alcanza_macro(Llamada, Tablas, [Spec|Visitados]).

llamadas_macro(T, _, []) :-
    var(T),
    !.
llamadas_macro(T, _, []) :-
    atomic(T),
    !.
llamadas_macro(T, Tablas, Specs) :-
    is_list(T),
    !,
    findall(S, (member(X, T), llamadas_macro(X, Tablas, Ss), member(S, Ss)), Specs).
llamadas_macro(T, Tablas, Specs) :-
    functor(T, Nombre, Aridad),
    Spec = Nombre/Aridad,
    T =.. [_|Args],
    findall(S, (member(A, Args), llamadas_macro(A, Tablas, Ss), member(S, Ss)), Resto),
    ( memberchk(macro(Spec, _, _, _, _), Tablas) -> Specs = [Spec|Resto] ; Specs = Resto ).

error_macro_duplicada(Tablas,
                      err(Linea, null,
                          'Macro duplicada.',
                          'Define cada macro una sola vez.')) :-
    findall(Spec, member(macro(Spec, _, _, _, _), Tablas), Specs),
    sort(Specs, Unicas),
    member(Spec, Unicas),
    findall(L, member(macro(Spec, _, _, L, _), Tablas), [_Linea1, Linea|_]).

error_cuerpo_macro((A, B), Vars, Tablas, Linea, E) :-
    !,
    (   error_cuerpo_macro(A, Vars, Tablas, Linea, E)
    ;   error_cuerpo_macro(B, Vars, Tablas, Linea, E)
    ).
error_cuerpo_macro(T, Vars, Tablas, Linea, E) :-
    error_termino(T, Vars, Tablas, Linea, E).

%!  error_termino(+Termino, +VarsCabeza, +Tablas, +Linea, -Error) is nondet.
%
%   Comprueba recursivamente que cada término del cuerpo de una macro sea un
%   bloque registrado, una llamada a macro válida, una lista o una variable de
%   la cabeza. Cualquier otro functor se rechaza (listas blancas).

error_termino(T, Vars, _, Linea,
              err(Linea, null,
                  'La macro usa una variable que no aparece en su cabeza.',
                  'Añade la variable como argumento de la macro.')) :-
    var(T),
    \+ memberchk(T, Vars),
    !.
error_termino(T, _, _, _, _) :-
    var(T),
    !,
    fail.
error_termino(T, _, _, _, _) :-
    atomic(T),
    !,
    fail.
error_termino((A, B), Vars, Tablas, Linea, E) :-
    !,
    (   error_termino(A, Vars, Tablas, Linea, E)
    ;   error_termino(B, Vars, Tablas, Linea, E)
    ).
error_termino(T, Vars, Tablas, Linea, E) :-
    is_list(T),
    !,
    member(X, T),
    error_termino(X, Vars, Tablas, Linea, E).
error_termino(T, Vars, Tablas, Linea, E) :-
    functor(T, N, A),
    es_formula_bloque(N/A),
    !,
    T =.. [_|Args],
    member(Arg, Args),
    error_termino(Arg, Vars, Tablas, Linea, E).
error_termino(T, Vars, Tablas, Linea, E) :-
    functor(T, N, A),
    memberchk(macro(N/A, Cabeza, _, _, _), Tablas),
    Cabeza =.. [_|VarsMacro],
    length(VarsMacro, A),
    !,
    T =.. [_|Args],
    member(Arg, Args),
    error_termino(Arg, Vars, Tablas, Linea, E).
error_termino(T, _, Tablas, Linea,
              err(Linea, null,
                  'Número incorrecto de argumentos en una llamada a macro.',
                  'Revisa los argumentos de la llamada.')) :-
    functor(T, N, A),
    memberchk(macro(N/Aridad, _, _, _, _), Tablas),
    !,
    A =\= Aridad.
error_termino(T, _, Tablas, Linea,
              err(Linea, null,
                  'La macro usa un bloque no registrado.',
                  'El cuerpo de una macro sólo puede usar bloques de la biblioteca u otras macros.')) :-
    functor(T, N, A),
    \+ es_formula_bloque(N/A),
    \+ memberchk(macro(N/A, _, _, _, _), Tablas),
    compound(T),
    \+ is_list(T).

% ------------------------------ expansión ----------------------------------

expandir_hechos([], _, [], []).
expandir_hechos([hecho(T, Linea)|Hs], Tabla, [hecho(T2, Linea)|Ts], Errores) :-
    expandir_hecho(T, Linea, Tabla, T2, Errores1),
    expandir_hechos(Hs, Tabla, Ts, Errores2),
    append(Errores1, Errores2, Errores).

expandir_hecho(pista(Id, H, F), Linea, Tabla, pista(Id, H, F2), Errores) :-
    !,
    expandir_formula(F, Linea, Id, Tabla, [], F2, Errores).
expandir_hecho(restriccion(F), Linea, Tabla, restriccion(F2), Errores) :-
    !,
    expandir_formula(F, Linea, null, Tabla, [], F2, Errores).
expandir_hecho(T, _, _, T, []).

expandir_formula(F, _, _, _, _, F, []) :-
    var(F),
    !.
expandir_formula(F, Linea, Id, Tabla, _, F,
                 [err(Linea, Id,
                      'Número incorrecto de argumentos en una llamada a macro.',
                      'Revisa los argumentos de la llamada.')]) :-
    compound(F),
    functor(F, N, A),
    memberchk(macro(N/Aridad, _, _, _, _), Tabla),
    A =\= Aridad,
    !.
expandir_formula((A, B), Linea, Id, Tabla, Pila, y(A2, B2), Errores) :-
    !,
    expandir_formula(A, Linea, Id, Tabla, Pila, A2, E1),
    expandir_formula(B, Linea, Id, Tabla, Pila, B2, E2),
    append(E1, E2, Errores).
expandir_formula(F, Linea, Id, Tabla, Pila, F2, Errores) :-
    (   macro_llamada(F, Tabla)
    ->  expandir_llamada_macro(F, Linea, Id, Tabla, Pila, F2, Errores)
    ;   (   compound(F)
        ->  F =.. [N|Args],
            expandir_args(Args, Linea, Id, Tabla, Pila, Args2, Errores),
            F2 =.. [N|Args2]
        ;   F2 = F, Errores = []
        )
    ).

expandir_args([], _, _, _, _, [], []).
expandir_args([A|As], Linea, Id, Tabla, Pila, [A2|As2], Errores) :-
    expandir_formula(A, Linea, Id, Tabla, Pila, A2, E1),
    expandir_args(As, Linea, Id, Tabla, Pila, As2, E2),
    append(E1, E2, Errores).

macro_llamada(F, Tabla) :-
    compound(F),
    functor(F, N, A),
    memberchk(macro(N/A, _, _, _, _), Tabla).

expandir_llamada_macro(F, Linea, Id, Tabla, Pila, F2, Errores) :-
    functor(F, N, A),
    Spec = N/A,
    (   memberchk(Spec, Pila)
    ->  F2 = F,
        Errores = [err(Linea, Id,
                       'Macro circular: no puede llamarse a sí misma.',
                       'Revisa las reglas de tus macros.')]
    ;   memberchk(macro(Spec, Cabeza, Cuerpo, _, Calculos), Tabla),
        Cabeza =.. [_|VarsMacro],
        length(VarsMacro, A)
    ->  copy_term(Cabeza-Cuerpo-Calculos, CabezaC-CuerpoC-CalculosC),
        CabezaC =.. [_|VarsC],
        F =.. [_|Args],
        VarsC = Args,
        apply_calculos(CalculosC),
        expandir_formula(CuerpoC, Linea, Id, Tabla, [Spec|Pila], F2, Errores)
    ;   F2 = F,
        Errores = [err(Linea, Id,
                       'Número incorrecto de argumentos en una llamada a macro.',
                       'Revisa los argumentos de la llamada.')]
    ).

apply_calculos([]).
apply_calculos([C|Cs]) :-
    calcular_macro(C),
    apply_calculos(Cs).

calcular_macro(longitud(Lista, N)) :-
    length(Lista, N).
