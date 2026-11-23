:- module(bloques_atributos, []).

:- use_module(library(clpfd)).
:- use_module('../bloques',
              [ valor_atributo/4,
                attr_valores/3,
                var_entidad/4,
                asig_valor/4,
                bool_de/2
              ]).

/** <module> Bloques atómicos sobre atributos

Semántica registrada de es/2, igual/3, distinto/3, vecino/3, antes/3 y
todos_distintos/2. Cada bloque aporta su traducción a CLP(FD), su evaluación
concreta para el solver naive y su regla de explicación.
*/

:- multifile bloques:bloque/5.
:- multifile bloques:trad_fd/3.
:- multifile bloques:eval_naive/3.
:- multifile bloques:regla_explicacion/3.

bloques:bloque(es/2, atributo,
               'es(E, Valor)',
               'La entidad E tiene ese valor en el atributo que lo contiene.',
               'es(b, truhan)').

bloques:bloque(igual/3, atributo,
               'igual(E1, E2, Atributo)',
               'E1 y E2 tienen el mismo valor en el atributo.',
               'igual(a, c, tipo)').

bloques:bloque(distinto/3, atributo,
               'distinto(E1, E2, Atributo)',
               'E1 y E2 tienen distinto valor en el atributo.',
               'distinto(a, c, tipo)').

bloques:bloque(vecino/3, atributo,
               'vecino(E1, E2, Atributo)',
               'Las posiciones de E1 y E2 en el atributo ordenado son consecutivas.',
               'vecino(casa1, casa2, posicion)').

bloques:bloque(antes/3, atributo,
               'antes(E1, E2, Atributo)',
               'E1 precede estrictamente a E2 en el atributo ordenado.',
               'antes(casa1, casa2, posicion)').

bloques:bloque(todos_distintos/2, atributo,
               'todos_distintos(Atributo, [E1, ...])',
               'Las entidades tienen valores distintos dos a dos en el atributo.',
               'todos_distintos(color, [a,b,c])').

% ---------------------------- traducción CLP(FD) ----------------------------

bloques:trad_fd(es(E, Valor), Ctx, B) :-
    get_dict(attrs, Ctx, Attrs),
    valor_atributo(Attrs, Valor, A, I),
    var_entidad(Ctx, E, A, X),
    B #<==> (X #= I).

bloques:trad_fd(igual(E1, E2, A), Ctx, B) :-
    var_entidad(Ctx, E1, A, X1),
    var_entidad(Ctx, E2, A, X2),
    B #<==> (X1 #= X2).

bloques:trad_fd(distinto(E1, E2, A), Ctx, B) :-
    var_entidad(Ctx, E1, A, X1),
    var_entidad(Ctx, E2, A, X2),
    B #<==> (X1 #\= X2).

bloques:trad_fd(vecino(E1, E2, A), Ctx, B) :-
    var_entidad(Ctx, E1, A, X1),
    var_entidad(Ctx, E2, A, X2),
    B #<==> (abs(X1 - X2) #= 1).

bloques:trad_fd(antes(E1, E2, A), Ctx, B) :-
    var_entidad(Ctx, E1, A, X1),
    var_entidad(Ctx, E2, A, X2),
    B #<==> (X1 #< X2).

bloques:trad_fd(todos_distintos(A, Es), Ctx, B) :-
    maplist(var_de(Ctx, A), Es, Xs),
    pares_distintos(Xs, Bs),
    y_booleana(Bs, B).

var_de(Ctx, A, E, X) :-
    var_entidad(Ctx, E, A, X).

pares_distintos([], []).
pares_distintos([X|Xs], Bs) :-
    pares_con(X, Xs, Bs1),
    pares_distintos(Xs, Bs2),
    append(Bs1, Bs2, Bs).

pares_con(_, [], []).
pares_con(X, [Y|Ys], [B|Bs]) :-
    B #<==> (X #\= Y),
    pares_con(X, Ys, Bs).

y_booleana([], 1).
y_booleana([B0|Bs], B) :-
    y_booleana(Bs, B1),
    B #<==> (B0 #/\ B1).

% -------------------------- evaluación concreta -----------------------------

bloques:eval_naive(es(E, Valor), Ctx, Truth) :-
    get_dict(attrs, Ctx, Attrs),
    valor_atributo(Attrs, Valor, A, _),
    asig_valor(Ctx, E, A, Val),
    bool_de(Val == Valor, Truth).

bloques:eval_naive(igual(E1, E2, A), Ctx, Truth) :-
    asig_valor(Ctx, E1, A, V1),
    asig_valor(Ctx, E2, A, V2),
    bool_de(V1 == V2, Truth).

bloques:eval_naive(distinto(E1, E2, A), Ctx, Truth) :-
    asig_valor(Ctx, E1, A, V1),
    asig_valor(Ctx, E2, A, V2),
    bool_de(V1 \== V2, Truth).

bloques:eval_naive(vecino(E1, E2, A), Ctx, Truth) :-
    attr_valores(Ctx, A, Valores),
    asig_valor(Ctx, E1, A, V1),
    asig_valor(Ctx, E2, A, V2),
    nth0(I1, Valores, V1),
    nth0(I2, Valores, V2),
    D is abs(I1 - I2),
    bool_de(D =:= 1, Truth).

bloques:eval_naive(antes(E1, E2, A), Ctx, Truth) :-
    attr_valores(Ctx, A, Valores),
    asig_valor(Ctx, E1, A, V1),
    asig_valor(Ctx, E2, A, V2),
    nth0(I1, Valores, V1),
    nth0(I2, Valores, V2),
    bool_de(I1 < I2, Truth).

bloques:eval_naive(todos_distintos(A, Es), Ctx, Truth) :-
    findall(V, (member(E, Es), asig_valor(Ctx, E, A, V)), Vs),
    sort(Vs, Unicos),
    length(Vs, N),
    length(Unicos, N),
    bool_de(Unicos == Vs, Truth),
    !.
bloques:eval_naive(todos_distintos(_, _), _, false).

% ----------------------------- explicación ---------------------------------

bloques:regla_explicacion(es(E, V), _, Texto) :-
    format(atom(Texto), '~w tiene el valor ~w', [E, V]).
bloques:regla_explicacion(igual(E1, E2, A), _, Texto) :-
    format(atom(Texto), '~w y ~w tienen el mismo ~w', [E1, E2, A]).
bloques:regla_explicacion(distinto(E1, E2, A), _, Texto) :-
    format(atom(Texto), '~w y ~w tienen distinto ~w', [E1, E2, A]).
bloques:regla_explicacion(vecino(E1, E2, A), _, Texto) :-
    format(atom(Texto), '~w y ~w son consecutivos en ~w', [E1, E2, A]).
bloques:regla_explicacion(antes(E1, E2, A), _, Texto) :-
    format(atom(Texto), '~w va antes que ~w en ~w', [E1, E2, A]).
bloques:regla_explicacion(todos_distintos(A, Es), _, Texto) :-
    atomic_list_concat(Es, ', ', Lista),
    format(atom(Texto), 'todos_distintos(~w, [~w])', [A, Lista]).
