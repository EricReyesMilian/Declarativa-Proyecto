:- module(validador,
          [ validar/3,
            validar_formula/5
          ]).

:- use_module(library(lists)).
:- use_module(bloques, [es_formula_bloque/1, tipo_hablante/1]).

:- discontiguous validar_argumentos/7.

/** <module> Validación semántica de acertijos

Recibe la lista de hechos producida por el cargador (ya expandida) y comprueba
estructura, dominios, referencias y formas de las afirmaciones. No ejecuta código
del usuario: sólo inspecciona términos. Los errores tienen forma
err(Linea, IdPista, Mensaje, Sugerencia) para que la interfaz pueda señalarlos.
*/

%!  validar(+Hechos, -Puzzle, -Errores) is det.
%
%   Hechos es una lista de hecho(Termino, Linea). Si no hay errores, Puzzle es
%   puzzle{id,titulo,entidades,attrs,pistas,restricciones}; en caso contrario es
%   el átomo error y Errores contiene todos los problemas encontrados.

validar(Hechos, Puzzle, Errores) :-
    validar_acertijo(Hechos, Id, Titulo, EId),
    validar_entidades(Hechos, Entidades, EEnt),
    validar_atributos(Hechos, AttrsLinea, EAttrs),
    findall(att(A, Vs), member(att(A, Vs, _), AttrsLinea), Attrs),
    Ctx = ctx{entidades:Entidades, attrs:Attrs, valores:Valores},
    findall(V, (member(att(_, Vs0), Attrs), member(V, Vs0)), Valores),
    validar_pistas(Hechos, Ctx, Pistas, EPistas),
    validar_restricciones(Hechos, Ctx, Restricciones, ERestricciones),
    validar_atributo_tipo(AttrsLinea, ETipo),
    append(EId, EEnt, E1),
    append(E1, EAttrs, E2),
    append(E2, EPistas, E3),
    append(E3, ERestricciones, E4),
    append(E4, ETipo, Errores),
    (   Errores == []
    ->  Puzzle = puzzle{ id:Id,
                         titulo:Titulo,
                         entidades:Entidades,
                         attrs:Attrs,
                         pistas:Pistas,
                         restricciones:Restricciones
                       }
    ;   Puzzle = error
    ).

% --------------------------- estructura ------------------------------------

validar_acertijo(Hechos, Id, Titulo, Errores) :-
    findall(hecho(T, L),
            ( member(hecho(T, L), Hechos), T = acertijo(_, _) ),
            Encontrados),
    (   Encontrados == []
    ->  Id = '', Titulo = '',
        Errores = [err(0, null,
                       'Falta el hecho acertijo/2.',
                       'Añade por ejemplo acertijo(isla_1, "Tres isleños").')]
    ;   Encontrados = [hecho(acertijo(Id, Titulo), _)]
    ->  validar_id_acertijo(Id, Titulo, Errores)
    ;   Encontrados = [_, Segundo|_],
        Segundo = hecho(_, Linea),
        Id = '', Titulo = '',
        Errores = [err(Linea, null,
                       'Hay más de un hecho acertijo/2.',
                       'Define un solo acertijo por archivo.')]
    ).

validar_id_acertijo(Id, Titulo, []) :-
    atom(Id),
    ( string(Titulo) -> true ; atom(Titulo) ),
    !.
validar_id_acertijo(_, _, 
                    [err(0, null,
                         'El identificador o el título no son válidos.',
                         'El Id debe ser un átomo y el título un texto entre comillas dobles.')]).

validar_entidades(Hechos, Entidades, Errores) :-
    findall(hecho(T, L),
            ( member(hecho(T, L), Hechos), T = entidades(_) ),
            Encontrados),
    (   Encontrados == []
    ->  Entidades = [],
        Errores = [err(0, null,
                       'Falta el hecho entidades/1.',
                       'Añade por ejemplo entidades([a, b, c]).')]
    ;   Encontrados = [hecho(entidades(Lista), Linea)]
    ->  validar_lista_entidades(Lista, Linea, Entidades, Errores1),
        (   memberchk(ninguno, Entidades)
        ->  append(Errores1,
                   [err(Linea, null,
                        'ninguno está reservado como hablante global.',
                        'Usa otro nombre para la entidad.')],
                   Errores)
        ;   Errores = Errores1
        )
    ;   Encontrados = [_, hecho(_, Linea)|_],
        Entidades = [],
        Errores = [err(Linea, null,
                       'Hay más de un hecho entidades/1.',
                       'Define una sola lista de entidades.')]
    ).

validar_lista_entidades(Lista, Linea, Entidades, Errores) :-
    (   is_list(Lista),
        Lista \== [],
        ground(Lista),
        maplist(atom, Lista),
        sort(Lista, Ordenadas),
        length(Lista, N),
        length(Ordenadas, N)
    ->  Entidades = Lista,
        Errores = []
    ;   Entidades = [],
        Errores = [err(Linea, null,
                       'La lista de entidades no es válida.',
                       'Usa átomos distintos, por ejemplo [a, b, c].')]
    ).

validar_atributos(Hechos, AttrsLinea, Errores) :-
    findall(att(A, Vs, L),
            member(hecho(atributo(A, Vs), L), Hechos),
            Brutos),
    (   Brutos == []
    ->  AttrsLinea = [],
        Errores = [err(0, null,
                       'Falta al menos un hecho atributo/2.',
                       'Añade por ejemplo atributo(tipo, [caballero, truhan]).')]
    ;   validar_cada_atributo(Brutos, AttrsLinea, EFormas),
        validar_nombres_atributo(AttrsLinea, ENombres),
        validar_valores_globales(AttrsLinea, EValores),
        append(EFormas, ENombres, E1),
        append(E1, EValores, Errores)
    ).

validar_cada_atributo([], [], []).
validar_cada_atributo([att(A, Vs, L)|Resto], [att(A, Vs2, L)|Attrs], Errores) :-
    (   atom(A),
        is_list(Vs),
        Vs \== [],
        ground(Vs),
        maplist(atom, Vs),
        sort(Vs, Ordenados),
        length(Vs, N),
        length(Ordenados, N)
    ->  Vs2 = Vs, Errores1 = []
    ;   Vs2 = [],
        Errores1 = [err(L, null,
                        'El atributo no tiene un dominio válido.',
                        'Usa una lista no vacía de valores átomo distintos, por ejemplo [caballero, truhan].')]
    ),
    validar_cada_atributo(Resto, Attrs, Errores2),
    append(Errores1, Errores2, Errores).

validar_nombres_atributo(Attrs, Errores) :-
    findall(A-L, member(att(A, _, L), Attrs), Pares),
    findall(A, member(A-_, Pares), Nombres),
    sort(Nombres, Unicos),
    findall(err(L, null,
                'Nombre de atributo repetido.',
                'Define cada atributo una sola vez.'),
            ( member(A, Unicos),
              findall(L0, member(A-L0, Pares), [_L1, L|_])
            ),
            Errores).

validar_valores_globales(Attrs, Errores) :-
    findall(V-L, (member(att(_, Vs, L), Attrs), member(V, Vs)), Pares),
    findall(V, member(V-_, Pares), Valores),
    sort(Valores, Unicos),
    findall(err(L, null,
                'Valor de atributo repetido en otro atributo.',
                'Cada valor debe pertenecer a un solo atributo para que es/2 sea inequívoco.'),
            ( member(V, Unicos),
              findall(L0, member(V-L0, Pares), [_L1, L|_])
            ),
            Errores).

validar_atributo_tipo(Attrs, Errores) :-
    findall(Vs, member(att(tipo, Vs, _), Attrs), Dominios),
    (   Dominios == []
    ->  Errores = [err(0, null,
                       'Falta el atributo tipo.',
                       'Añade atributo(tipo, [caballero, truhan]) u otro dominio de hablantes.')]
    ;   Dominios = [Vs],
        findall(E, (member(V, Vs), \+ tipo_valido(V), E = V), Invalidos),
        (   Invalidos == []
        ->  Errores = []
        ;   Errores = [err(0, null,
                           'El atributo tipo contiene valores que no son hablantes registrados.',
                           'Usa sólo caballero, truhan, normal o alternante (ninguno no es un tipo de entidad).')]
        )
    ).

tipo_valido(V) :-
    tipo_hablante(V),
    V \== ninguno.

% ------------------------------ pistas -------------------------------------

validar_pistas(Hechos, Ctx, Pistas, Errores) :-
    findall(pista(Id, H, F, L),
            member(hecho(pista(Id, H, F), L), Hechos),
            Crudas),
    findall(E,
            ( member(P, Crudas),
              \+ validar_pista(Ctx, P, []),
              validar_pista(Ctx, P, Es),
              member(E, Es)
            ),
            Errores1),
    validar_ids_pistas(Crudas, Errores2),
    append(Errores1, Errores2, Errores),
    findall(Id-pista(Id, H, F, L),
            member(pista(Id, H, F, L), Crudas),
            ConClave),
    keysort(ConClave, Ordenadas),
    findall(pista(Id, H, F, L), member(_-pista(Id, H, F, L), Ordenadas), Pistas).

validar_pista(Ctx, pista(Id, H, F, L), Errores) :-
    validar_id_pista(Id, L, EId),
    validar_hablante(H, Ctx, L, EH),
    validar_formula(F, L, Id, Ctx, EF),
    append(EId, EH, E1),
    append(E1, EF, Errores).

validar_id_pista(Id, _, []) :-
    ( integer(Id) -> Id >= 0 ; atom(Id) ),
    !.
validar_id_pista(_, L,
                 [err(L, null,
                      'El identificador de pista debe ser un número o un átomo.',
                      'Usa por ejemplo pista(1, a, ...).')]).

validar_hablante(H, Ctx, _, []) :-
    ( H == ninguno -> true
    ; get_dict(entidades, Ctx, Es), memberchk(H, Es)
    ),
    !.
validar_hablante(_, _, L,
                 [err(L, null,
                      'El hablante de la pista no es una entidad conocida.',
                      'Usa el nombre de una entidad o ninguno para un hecho global.')]).

validar_ids_pistas(Crudas, Errores) :-
    findall(Id-L, member(pista(Id, _, _, L), Crudas), Pares),
    findall(Id, member(Id-_, Pares), Ids),
    sort(Ids, Unicos),
    findall(err(L, null,
                'Identificador de pista repetido.',
                'Los Id de las pistas deben ser distintos; determinan el orden de los alternantes.'),
            ( member(Id, Unicos),
              findall(L0, member(Id-L0, Pares), [_L1, L|_])
            ),
            Errores).

validar_restricciones(Hechos, Ctx, Restricciones, Errores) :-
    findall(restriccion(F, L),
            member(hecho(restriccion(F), L), Hechos),
            Crudas),
    findall(E,
            ( member(restriccion(F, L), Crudas),
              \+ validar_formula(F, L, null, Ctx, []),
              validar_formula(F, L, null, Ctx, Es),
              member(E, Es)
            ),
            Errores),
    findall(restriccion(F, L), member(restriccion(F, L), Crudas), Restricciones).

% ------------------------------ fórmulas -----------------------------------

%!  validar_formula(+Formula, +Linea, +Id, +Ctx, -Errores) is det.
%
%   Valida recursivamente una afirmación. Ctx contiene entidades, attrs y valores.

validar_formula(F, L, Id, _, 
                [err(L, Id,
                     'Se esperaba una afirmación.',
                     'Escribe un bloque como es(a, caballero), y(...), al_menos(...) etc.')]) :-
    var(F),
    !.
validar_formula(F, L, Id, _, 
                [err(L, Id,
                     'Se esperaba una afirmación.',
                     'Las afirmaciones deben ser términos con nombre y argumentos.')]) :-
    \+ compound(F),
    !.
validar_formula(F, L, Id, Ctx, Errores) :-
    functor(F, N, A),
    (   \+ es_formula_bloque(N/A)
    ->  Errores = [err(L, Id,
                       'Bloque no registrado en una afirmación.',
                       'Revisa el vocabulario permitido en la documentación.')]
    ;   validar_argumentos(F, N, A, L, Id, Ctx, Errores)
    ).

validar_argumentos(es(E, V), es, 2, L, Id, Ctx, Errores) :-
    !,
    check_entidad(E, L, Id, Ctx, E1),
    check_valor(V, L, Id, Ctx, E2),
    append(E1, E2, Errores).
validar_argumentos(igual(E1, E2, A), igual, 3, L, Id, Ctx, Errores) :-
    !,
    check_dos_entidades_atributo(E1, E2, A, L, Id, Ctx, Errores).
validar_argumentos(distinto(E1, E2, A), distinto, 3, L, Id, Ctx, Errores) :-
    !,
    check_dos_entidades_atributo(E1, E2, A, L, Id, Ctx, Errores).
validar_argumentos(vecino(E1, E2, A), vecino, 3, L, Id, Ctx, Errores) :-
    !,
    check_dos_entidades_atributo(E1, E2, A, L, Id, Ctx, Errores).
validar_argumentos(antes(E1, E2, A), antes, 3, L, Id, Ctx, Errores) :-
    !,
    check_dos_entidades_atributo(E1, E2, A, L, Id, Ctx, Errores).
validar_argumentos(todos_distintos(A, Es), todos_distintos, 2, L, Id, Ctx, Errores) :-
    !,
    check_atributo(A, L, Id, Ctx, E1),
    check_lista_entidades(Es, L, Id, Ctx, E2),
    append(E1, E2, Errores).
validar_argumentos(y(F1, F2), y, 2, L, Id, Ctx, Errores) :-
    !,
    check_dos_formulas(F1, F2, L, Id, Ctx, Errores).
validar_argumentos(o(F1, F2), o, 2, L, Id, Ctx, Errores) :-
    !,
    check_dos_formulas(F1, F2, L, Id, Ctx, Errores).
validar_argumentos(si(F1, F2), si, 2, L, Id, Ctx, Errores) :-
    !,
    check_dos_formulas(F1, F2, L, Id, Ctx, Errores).
validar_argumentos(sii(F1, F2), sii, 2, L, Id, Ctx, Errores) :-
    !,
    check_dos_formulas(F1, F2, L, Id, Ctx, Errores).
validar_argumentos(xor(F1, F2), xor, 2, L, Id, Ctx, Errores) :-
    !,
    check_dos_formulas(F1, F2, L, Id, Ctx, Errores).
validar_argumentos(no(F), no, 1, L, Id, Ctx, Errores) :-
    !,
    validar_formula(F, L, Id, Ctx, Errores).
validar_argumentos(al_menos(N, Es, V), al_menos, 3, L, Id, Ctx, Errores) :-
    !,
    validar_conteo3(N, Es, V, L, Id, Ctx, Errores).
validar_argumentos(a_lo_sumo(N, Es, V), a_lo_sumo, 3, L, Id, Ctx, Errores) :-
    !,
    validar_conteo3(N, Es, V, L, Id, Ctx, Errores).
validar_argumentos(exactamente(N, Es, V), exactamente, 3, L, Id, Ctx, Errores) :-
    !,
    validar_conteo3(N, Es, V, L, Id, Ctx, Errores).
validar_argumentos(al_menos(N, Fs), al_menos, 2, L, Id, Ctx, Errores) :-
    !,
    validar_conteo2(N, Fs, L, Id, Ctx, Errores).
validar_argumentos(a_lo_sumo(N, Fs), a_lo_sumo, 2, L, Id, Ctx, Errores) :-
    !,
    validar_conteo2(N, Fs, L, Id, Ctx, Errores).
validar_argumentos(exactamente(N, Fs), exactamente, 2, L, Id, Ctx, Errores) :-
    !,
    validar_conteo2(N, Fs, L, Id, Ctx, Errores).

validar_conteo3(N, Es, V, L, Id, Ctx, Errores) :-
    check_entero(N, L, Id, E1),
    check_lista_entidades(Es, L, Id, Ctx, E2),
    check_valor(V, L, Id, Ctx, E3),
    check_rango(N, Es, L, Id, E4),
    append(E1, E2, A1), append(A1, E3, A2), append(A2, E4, Errores).

validar_conteo2(N, Fs, L, Id, Ctx, Errores) :-
    check_entero(N, L, Id, E1),
    check_lista_formulas(Fs, L, Id, Ctx, E2),
    check_rango(N, Fs, L, Id, E3),
    append(E1, E2, Errores0), append(Errores0, E3, Errores).
validar_argumentos(_, _, _, L, Id, _,
                   [err(L, Id,
                        'Forma de bloque no reconocida.',
                        'Consulta la sintaxis del bloque en la documentación.')]).

check_dos_entidades_atributo(E1, E2, A, L, Id, Ctx, Errores) :-
    check_entidad(E1, L, Id, Ctx, X1),
    check_entidad(E2, L, Id, Ctx, X2),
    check_atributo(A, L, Id, Ctx, X3),
    append(X1, X2, Y1), append(Y1, X3, Errores).

check_dos_formulas(F1, F2, L, Id, Ctx, Errores) :-
    validar_formula(F1, L, Id, Ctx, E1),
    validar_formula(F2, L, Id, Ctx, E2),
    append(E1, E2, Errores).

check_entidad(E, _, _, Ctx, []) :-
    get_dict(entidades, Ctx, Es),
    atom(E), memberchk(E, Es),
    !.
check_entidad(_, L, Id, _,
              [err(L, Id,
                   'Entidad desconocida en la afirmación.',
                   'Usa una de las entidades declaradas en entidades/1.')]).

check_atributo(A, _, _, Ctx, []) :-
    get_dict(attrs, Ctx, Attrs),
    atom(A),
    memberchk(att(A, _), Attrs),
    !.
check_atributo(_, L, Id, _,
               [err(L, Id,
                    'Atributo desconocido en la afirmación.',
                    'Usa un atributo declarado con atributo/2.')]).

check_valor(V, _, _, Ctx, []) :-
    get_dict(valores, Ctx, Valores),
    atom(V), memberchk(V, Valores),
    !.
check_valor(_, L, Id, _,
            [err(L, Id,
                 'Valor desconocido en la afirmación.',
                 'Usa un valor declarado en alguno de los atributos.')]).

check_entero(N, _, _, []) :-
    integer(N), N >= 0,
    !.
check_entero(_, L, Id,
             [err(L, Id,
                  'La cantidad de un bloque de conteo debe ser un entero no negativo.',
                  'Usa por ejemplo exactamente(2, [a,b,c], caballero).')]).

check_rango(N, Lista, _, _, []) :-
    integer(N), is_list(Lista), length(Lista, Len), N =< Len,
    !.
check_rango(_, _, L, Id,
            [err(L, Id,
                 'La cantidad supera el número de elementos contados.',
                 'Ajusta N para que no sea mayor que la longitud de la lista.')]).

check_lista_entidades(Lista, L, Id, Ctx, Errores) :-
    (   \+ is_list(Lista)
    ->  Errores = [err(L, Id,
                       'Se esperaba una lista de entidades.',
                       'Escribe por ejemplo [a, b, c].')]
    ;   findall(E,
                ( member(X, Lista),
                  \+ check_entidad(X, L, Id, Ctx, []),
                  check_entidad(X, L, Id, Ctx, E)
                ),
                Errores)
    ).

check_lista_formulas(Lista, L, Id, Ctx, Errores) :-
    (   \+ is_list(Lista)
    ->  Errores = [err(L, Id,
                       'Se esperaba una lista de afirmaciones.',
                       'Escribe por ejemplo [es(a,caballero), es(b,truhan)].')]
    ;   findall(E,
                ( member(F, Lista),
                  \+ validar_formula(F, L, Id, Ctx, []),
                  validar_formula(F, L, Id, Ctx, E)
                ),
                Errores)
    ).
