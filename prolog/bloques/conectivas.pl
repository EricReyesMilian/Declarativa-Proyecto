:- module(bloques_conectivas, []).

:- use_module(library(clpfd)).
:- use_module('../bloques', [bool_de/2]).

/** <module> Conectivas lógicas

Traducción reificada de y/2, o/2, no/1, si/2, sii/2 y xor/2, su evaluación
concreta y su explicación en español.
*/

:- multifile bloques:bloque/5.
:- multifile bloques:trad_fd/3.
:- multifile bloques:eval_naive/3.
:- multifile bloques:regla_explicacion/3.

bloques:bloque(y/2, conectiva, 'y(F1, F2)', 'Conjunción: ambas afirmaciones son verdaderas.', 'y(es(a,caballero), es(b,truhan))').
bloques:bloque(o/2, conectiva, 'o(F1, F2)', 'Disyunción: al menos una es verdadera.', 'o(es(a,caballero), es(b,caballero))').
bloques:bloque(no/1, conectiva, 'no(F)', 'Negación de una afirmación.', 'no(es(a,truhan))').
bloques:bloque(si/2, conectiva, 'si(F1, F2)', 'Implicación: si F1 entonces F2.', 'si(es(a,caballero), es(b,caballero))').
bloques:bloque(sii/2, conectiva, 'sii(F1, F2)', 'Bicondicional: F1 y F2 tienen el mismo valor de verdad.', 'sii(es(a,caballero), es(b,caballero))').
bloques:bloque(xor/2, conectiva, 'xor(F1, F2)', 'O exclusivo: exactamente una es verdadera.', 'xor(es(a,caballero), es(b,caballero))').

bloques:trad_fd(y(F1, F2), Ctx, B) :-
    bloques:trad_fd(F1, Ctx, B1),
    bloques:trad_fd(F2, Ctx, B2),
    B #<==> (B1 #/\ B2).

bloques:trad_fd(o(F1, F2), Ctx, B) :-
    bloques:trad_fd(F1, Ctx, B1),
    bloques:trad_fd(F2, Ctx, B2),
    B #<==> (B1 #\/ B2).

bloques:trad_fd(no(F), Ctx, B) :-
    bloques:trad_fd(F, Ctx, B1),
    B #<==> (#\ B1).

bloques:trad_fd(si(F1, F2), Ctx, B) :-
    bloques:trad_fd(F1, Ctx, B1),
    bloques:trad_fd(F2, Ctx, B2),
    B #<==> (B1 #==> B2).

bloques:trad_fd(sii(F1, F2), Ctx, B) :-
    bloques:trad_fd(F1, Ctx, B1),
    bloques:trad_fd(F2, Ctx, B2),
    B #<==> (B1 #<==> B2).

bloques:trad_fd(xor(F1, F2), Ctx, B) :-
    bloques:trad_fd(F1, Ctx, B1),
    bloques:trad_fd(F2, Ctx, B2),
    B #<==> (B1 #\ B2).

bloques:eval_naive(y(F1, F2), Ctx, Truth) :-
    bloques:eval_naive(F1, Ctx, T1),
    bloques:eval_naive(F2, Ctx, T2),
    bool_de((T1 == true, T2 == true), Truth).

bloques:eval_naive(o(F1, F2), Ctx, Truth) :-
    bloques:eval_naive(F1, Ctx, T1),
    bloques:eval_naive(F2, Ctx, T2),
    bool_de((T1 == true ; T2 == true), Truth).

bloques:eval_naive(no(F), Ctx, Truth) :-
    bloques:eval_naive(F, Ctx, T),
    bool_de(T == false, Truth).

bloques:eval_naive(si(F1, F2), Ctx, Truth) :-
    bloques:eval_naive(F1, Ctx, T1),
    bloques:eval_naive(F2, Ctx, T2),
    bool_de((T1 == false ; T2 == true), Truth).

bloques:eval_naive(sii(F1, F2), Ctx, Truth) :-
    bloques:eval_naive(F1, Ctx, T1),
    bloques:eval_naive(F2, Ctx, T2),
    bool_de(T1 == T2, Truth).

bloques:eval_naive(xor(F1, F2), Ctx, Truth) :-
    bloques:eval_naive(F1, Ctx, T1),
    bloques:eval_naive(F2, Ctx, T2),
    bool_de(T1 \== T2, Truth).

bloques:regla_explicacion(y(F1, F2), Ctx, Texto) :-
    texto_formula(F1, Ctx, T1), texto_formula(F2, Ctx, T2),
    format(atom(Texto), '~w y ~w', [T1, T2]).
bloques:regla_explicacion(o(F1, F2), Ctx, Texto) :-
    texto_formula(F1, Ctx, T1), texto_formula(F2, Ctx, T2),
    format(atom(Texto), '~w o ~w', [T1, T2]).
bloques:regla_explicacion(no(F), Ctx, Texto) :-
    texto_formula(F, Ctx, T),
    format(atom(Texto), 'no (~w)', [T]).
bloques:regla_explicacion(si(F1, F2), Ctx, Texto) :-
    texto_formula(F1, Ctx, T1), texto_formula(F2, Ctx, T2),
    format(atom(Texto), 'si ~w, entonces ~w', [T1, T2]).
bloques:regla_explicacion(sii(F1, F2), Ctx, Texto) :-
    texto_formula(F1, Ctx, T1), texto_formula(F2, Ctx, T2),
    format(atom(Texto), '~w si y sólo si ~w', [T1, T2]).
bloques:regla_explicacion(xor(F1, F2), Ctx, Texto) :-
    texto_formula(F1, Ctx, T1), texto_formula(F2, Ctx, T2),
    format(atom(Texto), 'exactamente uno de (~w, ~w)', [T1, T2]).

texto_formula(F, Ctx, Texto) :-
    (   bloques:regla_explicacion(F, Ctx, Texto)
    ->  true
    ;   term_to_atom(F, Texto)
    ).
