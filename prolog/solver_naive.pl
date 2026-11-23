:- module(solver_naive,
          [ modelo/3,
            resolver/4
          ]).

:- use_module(library(solution_sequences)).
:- use_module(bloques, [asig_valor/4]).

/** <module> Solver de respaldo por generación y prueba

No usa CLP(FD): enumera todas las asignaciones posibles y evalúa cada bloque con
eval_naive/3 y las reglas de veracidad con regla_hablante_naive/6. Sirve como
oráculo independiente en las pruebas y para comparar el modelo principal.
*/

%!  modelo(+Puzzle, -Ctx, -Espacio) is det.
%
%   Espacio es una lista de E-A-Valores con los dominios por asignar. Ctx contiene
%   attrs, entidades, pistas y, una vez generada, la lista asig.

modelo(Puzzle, Ctx, Espacio) :-
    get_dict(entidades, Puzzle, Entidades),
    get_dict(attrs, Puzzle, Attrs),
    get_dict(pistas, Puzzle, Pistas),
    findall(E-A-Valores,
            ( member(E, Entidades),
              member(att(A, Valores), Attrs)
            ),
            Espacio),
    Ctx = ctx{ attrs:Attrs,
               entidades:Entidades,
               pistas:Pistas,
               asig:[]
             }.

%!  resolver(+Puzzle, +Opciones, -Soluciones, -Estadisticas) is det.
%
%   Misma interfaz que solver_fd:resolver/4. Soluciones es una lista de listas
%   sol(Entidad, [Atributo-Valor, ...]).

resolver(Puzzle, Opciones, Soluciones, Estadisticas) :-
    modelo(Puzzle, Ctx0, Espacio),
    (   get_dict(limite, Opciones, Limite0) -> Limite = Limite0 ; Limite = 100 ),
    findall(Sol,
            limit(Limite,
                  ( generar_asignaciones(Espacio, Asig),
                    put_dict(asig, Ctx0, Asig, Ctx),
                    cumple_puzzle(Puzzle, Ctx),
                    extraer_solucion(Ctx, Sol)
                  )),
            Soluciones),
    length(Soluciones, Total),
    ( Total >= Limite -> Cortado = true ; Cortado = false ),
    Estadisticas = estadisticas{soluciones:Total, cortado:Cortado}.

generar_asignaciones([], []).
generar_asignaciones([E-A-Valores|Resto], [E-A-V|Asig]) :-
    member(V, Valores),
    generar_asignaciones(Resto, Asig).

cumple_puzzle(Puzzle, Ctx) :-
    get_dict(pistas, Puzzle, Pistas),
    get_dict(restricciones, Puzzle, Restricciones),
    cumple_pistas(Pistas, Ctx),
    cumple_restricciones(Restricciones, Ctx).

cumple_pistas([], _).
cumple_pistas([pista(Id, H, F, _)|Ps], Ctx) :-
    bloques:eval_naive(F, Ctx, Truth),
    (   H == ninguno
    ->  Truth == true
    ;   asig_valor(Ctx, H, tipo, Tipo),
        bloques:regla_hablante_naive(Tipo, Id, H, Truth, Ctx, Ok),
        Ok == true
    ),
    cumple_pistas(Ps, Ctx).

cumple_restricciones([], _).
cumple_restricciones([restriccion(F, _)|Rs], Ctx) :-
    bloques:eval_naive(F, Ctx, Truth),
    Truth == true,
    cumple_restricciones(Rs, Ctx).

extraer_solucion(Ctx, Solucion) :-
    get_dict(entidades, Ctx, Entidades),
    get_dict(attrs, Ctx, Attrs),
    findall(sol(E, Pares),
            ( member(E, Entidades),
              findall(A-Valor,
                      ( member(att(A, _), Attrs),
                        asig_valor(Ctx, E, A, Valor)
                      ),
                      Pares)
            ),
            Solucion).
