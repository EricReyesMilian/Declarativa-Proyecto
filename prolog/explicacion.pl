:- module(explicacion,
           [ explicar/3
           ]).

:- use_module(bloques, [asig_valor/4, bool_de/2]).
:- use_module(solver_fd, []).

/** <module> Explicaciones en lenguaje natural

Reconstruye, para una solución concreta, por qué cada pista y cada restricción
se cumplen. No introduce lógica nueva: reutiliza eval_naive/3 y
regla_hablante_naive/6 de los bloques registrados, de modo que la explicación
siempre coincide con la semántica usada por el solver.
*/

%!  explicar(+Puzzle, -Solucion, -Texto) is det.
%
%   Texto es un atomo con lineas en español. Solucion es la primera solucion
%   encontrada por solver_fd, con forma [sol(E, [A-V, ...]), ...].

explicar(Puzzle, Solucion, Texto) :-
    solver_fd:resolver(Puzzle, opciones{limite:2}, Soluciones, _),
    (   Soluciones == []
    ->  Texto = 'El acertijo no tiene solución: las pistas se contradicen.'
    ;   Soluciones = [Solucion|_],
        contexto_de(Puzzle, Solucion, Ctx),
        get_dict(pistas, Puzzle, Pistas),
        get_dict(restricciones, Puzzle, Restricciones),
        findall(Linea, linea_pista(Pistas, Ctx, Linea), LineasP),
        findall(Linea, linea_restriccion(Restricciones, Ctx, Linea), LineasR),
        encabezado(Puzzle, Solucion, Cabecera),
        append([Cabecera|LineasP], LineasR, Lineas),
        atomic_list_concat(Lineas, '\n', Texto)
    ).

encabezado(Puzzle, Solucion, Texto) :-
    get_dict(titulo, Puzzle, Titulo),
    (   string(Titulo) -> TituloTexto = Titulo
    ;   atom_string(Titulo, TituloTexto)
    ),
    format(atom(Asignacion), '~q', [Solucion]),
    format(atom(Texto), 'Acertijo ~w. Solución: ~w',
           [TituloTexto, Asignacion]).

contexto_de(Puzzle, Solucion, Ctx) :-
    get_dict(entidades, Puzzle, Entidades),
    get_dict(attrs, Puzzle, Attrs),
    get_dict(pistas, Puzzle, Pistas),
    findall(E-A-V,
            ( member(sol(E, Pares), Solucion),
              member(A-V, Pares)
            ),
            Asig),
    Ctx = ctx{attrs:Attrs, entidades:Entidades, pistas:Pistas, asig:Asig}.

linea_pista([], _, _) :- !, fail.
linea_pista(Pistas, Ctx, Linea) :-
    member(pista(Id, H, F, _), Pistas),
    bloques:eval_naive(F, Ctx, Truth),
    (   H == ninguno
    ->  Tipo = ninguno, Ok = Truth
    ;   asig_valor(Ctx, H, tipo, Tipo),
        bloques:regla_hablante_naive(Tipo, Id, H, Truth, Ctx, Ok)
    ),
    (   bloques:regla_explicacion(F, Ctx, TextoF) -> true
    ;   term_to_atom(F, TextoF)
    ),
    valor_texto(Truth, Verdad),
    valor_texto(Ok, Cumple),
    format(atom(Linea),
           'Pista ~w (~w): afirma que ~w. Es ~w, coherente con un ~w: ~w.',
           [Id, H, TextoF, Verdad, Tipo, Cumple]).

linea_restriccion(Restricciones, Ctx, Linea) :-
    member(restriccion(F, _), Restricciones),
    bloques:eval_naive(F, Ctx, Truth),
    (   bloques:regla_explicacion(F, Ctx, TextoF) -> true
    ;   term_to_atom(F, TextoF)
    ),
    valor_texto(Truth, Verdad),
    format(atom(Linea), 'Restricción global: ~w. Es ~w.', [TextoF, Verdad]).

valor_texto(true, 'verdadero') :- !.
valor_texto(false, 'falso').
