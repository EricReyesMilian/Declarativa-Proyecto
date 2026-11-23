:- module(bloques_conteo, []).

:- use_module(library(clpfd)).
:- use_module('../bloques', [bool_de/2]).

/** <module> Bloques de conteo

Dos aridades para cada nombre: /3 cuenta entidades con un valor; /2 cuenta
afirmaciones verdaderas. Así se cubren tanto los conteos de atributos como las
afirmaciones autorreferentes sin añadir nuevos nombres al vocabulario.
*/

:- multifile bloques:bloque/5.
:- multifile bloques:trad_fd/3.
:- multifile bloques:eval_naive/3.
:- multifile bloques:regla_explicacion/3.

bloques:bloque(al_menos/3, conteo,
               'al_menos(N, [E1,...], Valor)',
               'Al menos N entidades de la lista tienen ese valor.',
               'al_menos(1, [a,b,c], truhan)').
bloques:bloque(a_lo_sumo/3, conteo,
               'a_lo_sumo(N, [E1,...], Valor)',
               'Como mucho N entidades de la lista tienen ese valor.',
               'a_lo_sumo(2, [a,b,c], truhan)').
bloques:bloque(exactamente/3, conteo,
               'exactamente(N, [E1,...], Valor)',
               'Exactamente N entidades de la lista tienen ese valor.',
               'exactamente(2, [a,b,c], caballero)').

bloques:bloque(al_menos/2, conteo,
               'al_menos(N, [F1,...])',
               'Al menos N de las afirmaciones son verdaderas.',
               'al_menos(2, [F1,F2,F3])').
bloques:bloque(a_lo_sumo/2, conteo,
               'a_lo_sumo(N, [F1,...])',
               'Como mucho N de las afirmaciones son verdaderas.',
               'a_lo_sumo(1, [F1,F2,F3])').
bloques:bloque(exactamente/2, conteo,
               'exactamente(N, [F1,...])',
               'Exactamente N de las afirmaciones son verdaderas.',
               'exactamente(2, [F1,F2,F3])').

% ---------------------------- traducción CLP(FD) ----------------------------

bloques:trad_fd(al_menos(N,Es,V), Ctx, B) :- trad_conteo3(al_menos,N,Es,V,Ctx,B).
bloques:trad_fd(a_lo_sumo(N,Es,V), Ctx, B) :- trad_conteo3(a_lo_sumo,N,Es,V,Ctx,B).
bloques:trad_fd(exactamente(N,Es,V), Ctx, B) :- trad_conteo3(exactamente,N,Es,V,Ctx,B).

bloques:trad_fd(al_menos(N,Fs), Ctx, B) :- trad_conteo2(al_menos,N,Fs,Ctx,B).
bloques:trad_fd(a_lo_sumo(N,Fs), Ctx, B) :- trad_conteo2(a_lo_sumo,N,Fs,Ctx,B).
bloques:trad_fd(exactamente(N,Fs), Ctx, B) :- trad_conteo2(exactamente,N,Fs,Ctx,B).

trad_conteo3(Op, N, Es, Valor, Ctx, B) :-
    maplist(trad_es(Ctx, Valor), Es, Bs),
    suma_booleanos(Bs, Sum),
    expr_comparacion(Op, Sum, N, Expr),
    B #<==> Expr.

trad_conteo2(Op, N, Fs, Ctx, B) :-
    maplist(trad_formula(Ctx), Fs, Bs),
    suma_booleanos(Bs, Sum),
    expr_comparacion(Op, Sum, N, Expr),
    B #<==> Expr.

trad_es(Ctx, Valor, E, B) :-
    bloques:trad_fd(es(E, Valor), Ctx, B).

trad_formula(Ctx, F, B) :-
    bloques:trad_fd(F, Ctx, B).

suma_booleanos([], 0).
suma_booleanos(Bs, Sum) :- sum(Bs, #=, Sum).

expr_comparacion(al_menos, Sum, N, Sum #>= N).
expr_comparacion(a_lo_sumo, Sum, N, Sum #=< N).
expr_comparacion(exactamente, Sum, N, Sum #= N).

% -------------------------- evaluación concreta -----------------------------

bloques:eval_naive(al_menos(N,Es,V), Ctx, Truth) :- eval_conteo3(al_menos,N,Es,V,Ctx,Truth).
bloques:eval_naive(a_lo_sumo(N,Es,V), Ctx, Truth) :- eval_conteo3(a_lo_sumo,N,Es,V,Ctx,Truth).
bloques:eval_naive(exactamente(N,Es,V), Ctx, Truth) :- eval_conteo3(exactamente,N,Es,V,Ctx,Truth).

bloques:eval_naive(al_menos(N,Fs), Ctx, Truth) :- eval_conteo2(al_menos,N,Fs,Ctx,Truth).
bloques:eval_naive(a_lo_sumo(N,Fs), Ctx, Truth) :- eval_conteo2(a_lo_sumo,N,Fs,Ctx,Truth).
bloques:eval_naive(exactamente(N,Fs), Ctx, Truth) :- eval_conteo2(exactamente,N,Fs,Ctx,Truth).

eval_conteo3(Op, N, Es, Valor, Ctx, Truth) :-
    findall(T, (member(E, Es), bloques:eval_naive(es(E, Valor), Ctx, T)), Ts),
    cuenta(Ts, Cuenta),
    bool_de(bloques_conteo:cumple_conteo(Op, Cuenta, N), Truth).

eval_conteo2(Op, N, Fs, Ctx, Truth) :-
    findall(T, (member(F, Fs), bloques:eval_naive(F, Ctx, T)), Ts),
    cuenta(Ts, Cuenta),
    bool_de(bloques_conteo:cumple_conteo(Op, Cuenta, N), Truth).

cuenta(Ts, Cuenta) :-
    findall(t, member(true, Ts), Ls),
    length(Ls, Cuenta).

cumple_conteo(al_menos, C, N) :- C >= N.
cumple_conteo(a_lo_sumo, C, N) :- C =< N.
cumple_conteo(exactamente, C, N) :- C =:= N.

% ----------------------------- explicación ---------------------------------

bloques:regla_explicacion(al_menos(N,Es,V), _, T) :- explicacion_conteo3(al_menos,N,Es,V,T).
bloques:regla_explicacion(a_lo_sumo(N,Es,V), _, T) :- explicacion_conteo3(a_lo_sumo,N,Es,V,T).
bloques:regla_explicacion(exactamente(N,Es,V), _, T) :- explicacion_conteo3(exactamente,N,Es,V,T).

bloques:regla_explicacion(al_menos(N,Fs), _, T) :- explicacion_conteo2(al_menos,N,Fs,T).
bloques:regla_explicacion(a_lo_sumo(N,Fs), _, T) :- explicacion_conteo2(a_lo_sumo,N,Fs,T).
bloques:regla_explicacion(exactamente(N,Fs), _, T) :- explicacion_conteo2(exactamente,N,Fs,T).

explicacion_conteo3(Op, N, Es, Valor, Texto) :-
    atomic_list_concat(Es, ', ', Lista),
    nombre_operador(Op, Nombre),
    format(atom(Texto), '~w ~w entidades de [~w] con valor ~w', [Nombre, N, Lista, Valor]).

explicacion_conteo2(Op, N, Fs, Texto) :-
    length(Fs, Total),
    nombre_operador(Op, Nombre),
    format(atom(Texto), '~w ~w de las ~w afirmaciones son verdaderas', [Nombre, N, Total]).

nombre_operador(al_menos, 'al menos').
nombre_operador(a_lo_sumo, 'como mucho').
nombre_operador(exactamente, 'exactamente').
