:- module(analisis,
          [ analizar/3
          ]).

:- use_module(library(time)).
:- use_module(solver_fd, []).

/** <module> Análisis de existencia, unicidad y minimidad

Envuelve el solver con call_with_time_limit/2. Calcula primero existencia y
unicidad; sólo si hay una solución única estudia la irredundancia de cada pista
y, si se pide, la minimalidad fuerte por subconjuntos crecientes. La búsqueda
fuerte se desactiva por defecto para evitar coste exponencial.
*/

%!  analizar(+Puzzle, +Opciones, -Informe) is det.
%
%   Opciones admite limite, tiempo, minimalidad y max_clausulas. Informe es un
%   dict con estado, numero_soluciones, soluciones, unica, irreductible,
%   pistas_sobrantes y minimalidad_fuerte.

analizar(Puzzle, Opciones, Informe) :-
    opcion(limite, Opciones, 100, Limite0),
    Limite is max(Limite0, 2),
    opcion(tiempo, Opciones, 5, Tiempo),
    opcion(minimalidad, Opciones, false, Minimalidad),
    opcion(max_clausulas, Opciones, 12, MaxClausulas),
    catch(call_with_time_limit(Tiempo,
                               analizar_core(Puzzle, Limite, Minimalidad,
                                             MaxClausulas, Informe)),
          time_limit_exceeded,
          informe_timeout(Informe)),
    !.
analizar(_, _, Informe) :-
    Informe = informe{ estado:'error',
                       numero_soluciones:null,
                       soluciones:[],
                       unica:false,
                       irreductible:null,
                       pistas_sobrantes:[],
                       minimalidad_fuerte:inconcluso,
                       aviso:'El análisis no pudo completarse; revisa el acertijo.'
                     }.

opcion(Clave, Opciones, Defecto, Valor) :-
    (   get_dict(Clave, Opciones, Valor0) -> Valor = Valor0 ; Valor = Defecto ).

informe_timeout(Informe) :-
    Informe = informe{ estado:'timeout',
                       numero_soluciones:null,
                       soluciones:[],
                       unica:false,
                       irreductible:null,
                       pistas_sobrantes:[],
                       minimalidad_fuerte:inconcluso,
                       aviso:'El análisis superó el tiempo permitido; reduce entidades o pistas.'
                     }.

analizar_core(Puzzle, Limite, Minimalidad, MaxClausulas, Informe) :-
    solver_fd:resolver(Puzzle, opciones{limite:Limite}, Soluciones, Estadisticas),
    length(Soluciones, N),
    (   N =:= 0
    ->  Informe = informe{ estado:inconsistente,
                           numero_soluciones:0,
                           soluciones:[],
                           unica:false,
                           irreductible:null,
                           pistas_sobrantes:[],
                           minimalidad_fuerte:inconcluso,
                           aviso:'El acertijo no tiene solución con las pistas dadas.'
                         }
    ;   N =:= 1
    ->  Soluciones = [Sol],
        clausulas(Puzzle, Cls),
        comprobar_irredundancia(Puzzle, Sol, Cls, Sobrantes),
        (   Minimalidad == true
        ->  comprobar_minimalidad(Puzzle, Sol, Cls, MaxClausulas, Minimal)
        ;   Minimal = inconcluso
        ),
        ( Sobrantes == [] -> Irreductible = true ; Irreductible = false ),
        Informe = informe{ estado:'unico',
                           numero_soluciones:1,
                           soluciones:Soluciones,
                           unica:true,
                           irreductible:Irreductible,
                           pistas_sobrantes:Sobrantes,
                           minimalidad_fuerte:Minimal,
                           aviso:'',
                           cortado:Estadisticas.cortado
                         }
    ;   Informe = informe{ estado:multiple,
                           numero_soluciones:null,
                           soluciones:Soluciones,
                           unica:false,
                           irreductible:null,
                           pistas_sobrantes:[],
                           minimalidad_fuerte:inconcluso,
                           aviso:'Hay varias soluciones; se muestran las primeras.',
                           cortado:Estadisticas.cortado
                         }
    ).

% ---------------------------- cláusulas ------------------------------------

clausulas(Puzzle, Cls) :-
    get_dict(pistas, Puzzle, Pistas),
    get_dict(restricciones, Puzzle, Restricciones),
    findall(cl(Id, pista, T, 0),
            ( member(T, Pistas), T = pista(Id, _, _, _) ),
            Cp),
    findall(cl(res(I), restriccion, T, I),
            ( nth0(I0, Restricciones, T), I is I0 + 1 ),
            Cr),
    append(Cp, Cr, Cls).

aplicar_subconjunto(Puzzle, Sub, Puzzle2) :-
    findall(Id, member(cl(Id, _, _, _), Sub), Ids),
    get_dict(pistas, Puzzle, Pistas),
    get_dict(restricciones, Puzzle, Restricciones),
    findall(T, (member(T, Pistas), T = pista(Id, _, _, _), memberchk(Id, Ids)), Ps2),
    findall(T, (nth0(I0, Restricciones, T), I is I0 + 1, memberchk(res(I), Ids)), Rs2),
    put_dict(pistas, Puzzle, Ps2, Puzzle1),
    put_dict(restricciones, Puzzle1, Rs2, Puzzle2).

quitar_clausula(Puzzle, Cls, Objetivo, Puzzle2) :-
    findall(C, (member(C, Cls), C \== Objetivo), Resto),
    aplicar_subconjunto(Puzzle, Resto, Puzzle2).

% -------------------------- irredundancia ----------------------------------

comprobar_irredundancia(Puzzle, Sol, Cls, Sobrantes) :-
    findall(Id,
            ( member(C, Cls),
              C = cl(Id, _, _, _),
              quitar_clausula(Puzzle, Cls, C, Puzzle2),
              resolver_unico(Puzzle2, Sol)
            ),
            Sobrantes).

resolver_unico(Puzzle, Sol) :-
    solver_fd:resolver(Puzzle, opciones{limite:2}, Soluciones, _),
    Soluciones == [Sol].

% ------------------------ minimalidad fuerte --------------------------------

comprobar_minimalidad(Puzzle, Sol, Cls, MaxClausulas, Resultado) :-
    length(Cls, N),
    (   N > MaxClausulas
    ->  Resultado = inconcluso
    ;   N1 is N - 1,
        N1 >= 1,
        findall(Ids,
                ( between(1, N1, K),
                  combinacion(K, Cls, Sub),
                  aplicar_subconjunto(Puzzle, Sub, Puzzle2),
                  resolver_unico(Puzzle2, Sol),
                  findall(Id, member(cl(Id, _, _, _), Sub), Ids)
                ),
                Encontrados0),
        sort_by_length(Encontrados0, Encontrados),
        (   Encontrados == []
        ->  Resultado = verdadera
        ;   Encontrados = [MasCorto|_],
            Resultado = falsa(MasCorto)
        )
    ).
comprobar_minimalidad(_, _, _, _, inconcluso) :-
    !.

combinacion(0, _, []).
combinacion(K, [X|Xs], [X|Ys]) :-
    K > 0,
    K1 is K - 1,
    combinacion(K1, Xs, Ys).
combinacion(K, [_|Xs], Ys) :-
    K > 0,
    combinacion(K, Xs, Ys).

sort_by_length(Lista, Ordenada) :-
    maplist(par, Lista, Pares),
    keysort(Pares, Ordenados),
    findall(Ids, member(_-Ids, Ordenados), Ordenada).

par(Ids, Longitud-Ids) :-
    length(Ids, Longitud).
