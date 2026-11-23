:- module(solver_fd,
          [ modelo/3,
            resolver/4
          ]).

:- use_module(library(clpfd)).
:- use_module(library(solution_sequences)).
:- use_module(bloques,
              [ var_entidad/4,
                tipo_hablante/1
              ]).

/** <module> Solver principal con CLP(FD)

Codifica cada atributo de cada entidad como una variable entera que indexa su
dominio. Las afirmaciones se traducen a booleanos reificados y las reglas de los
hablantes se imponen condicionadas al tipo efectivo de cada entidad. El modelo es
independiente del vocabulario: las traducciones están en el registro de bloques.
*/

%!  modelo(+Puzzle, -Ctx, -Variables) is det.
%
%   Construye el modelo CLP(FD). Ctx es un dict con attrs, vars, entidades,
%   pistas y alt (booleanos de alternancia). Variables son las variables a etiquetar.

modelo(Puzzle, Ctx, Variables) :-
    get_dict(entidades, Puzzle, Entidades),
    get_dict(attrs, Puzzle, Attrs),
    get_dict(pistas, Puzzle, Pistas),
    findall(v(E, A, X),
            ( member(E, Entidades),
              member(att(A, Valores), Attrs),
              length(Valores, N),
              Max is N - 1,
              X in 0..Max
            ),
            Variables),
    findall(H-P,
            ( member(H, Entidades), P in 0..1 ),
            Alt),
    Ctx = ctx{ attrs:Attrs,
               vars:Variables,
               entidades:Entidades,
               pistas:Pistas,
               alt:Alt
             },
    post_pistas(Pistas, Ctx),
    post_restricciones(Puzzle.restricciones, Ctx).

%!  resolver(+Puzzle, +Opciones, -Soluciones, -Estadisticas) is det.
%
%   Opciones es un dict con limite (entero positivo). Soluciones es una lista de
%   sol(Entidad, [Atributo-Valor, ...]). Estadisticas indica cuántas se obtuvieron
%   y si se alcanzó el límite.

resolver(Puzzle, Opciones, Soluciones, Estadisticas) :-
    modelo(Puzzle, Ctx, Variables),
    maplist(variable_de, Variables, Dominio),
    (   get_dict(limite, Opciones, Limite0) -> Limite = Limite0 ; Limite = 100 ),
    findall(Sol,
            limit(Limite,
                  ( labeling([], Dominio),
                    extraer_solucion(Ctx, Sol)
                  )),
            Soluciones),
    length(Soluciones, Total),
    ( Total >= Limite -> Cortado = true ; Cortado = false ),
    Estadisticas = estadisticas{soluciones:Total, cortado:Cortado}.

% ------------------------------ restricciones -------------------------------

post_pistas([], _).
post_pistas([P|Pistas], Ctx) :-
    post_pista(P, Ctx),
    post_pistas(Pistas, Ctx).

post_pista(pista(Id, H, F, _), Ctx) :-
    bloques:trad_fd(F, Ctx, BF),
    BF in 0..1,
    (   H == ninguno
    ->  BF #= 1
    ;   post_reglas_hablante(H, Id, BF, Ctx)
    ).

post_restricciones([], _).
post_restricciones([restriccion(F, _)|Rs], Ctx) :-
    bloques:trad_fd(F, Ctx, BF),
    BF #= 1,
    post_restricciones(Rs, Ctx).

post_reglas_hablante(H, Id, BF, Ctx) :-
    get_dict(attrs, Ctx, Attrs),
    memberchk(att(tipo, Tipos), Attrs),
    var_entidad(Ctx, H, tipo, XH),
    post_tipos(Tipos, 0, XH, Id, H, BF, Ctx).

post_tipos([], _, _, _, _, _, _).
post_tipos([Tipo|Tipos], I, XH, Id, H, BF, Ctx) :-
    (   tipo_hablante(Tipo),
        Tipo \== ninguno
    ->  Activo #<==> (XH #= I),
        bloques:regla_hablante_cond(Tipo, Activo, Id, H, BF, Ctx)
    ;   true
    ),
    I1 is I + 1,
    post_tipos(Tipos, I1, XH, Id, H, BF, Ctx).

% ------------------------------ soluciones ---------------------------------

variable_de(v(_, _, X), X).

extraer_solucion(Ctx, Solucion) :-
    get_dict(entidades, Ctx, Entidades),
    get_dict(attrs, Ctx, Attrs),
    get_dict(vars, Ctx, Vars),
    findall(sol(E, Pares),
            ( member(E, Entidades),
              findall(A-Valor,
                      ( member(att(A, Valores), Attrs),
                        member(v(E2, A, X), Vars),
                        E2 == E,
                        nth0(X, Valores, Valor)
                      ),
                      Pares)
            ),
            Solucion).
