:- module(bloques_hablantes, []).

:- use_module(library(clpfd)).
:- use_module('../bloques', [bool_de/2]).

/** <module> Reglas de veracidad de los hablantes

Cada tipo de hablante es una entrada del registro central y una cláusula de
regla_hablante/5 (solver FD) y regla_hablante_naive/6 (solver de respaldo).
Añadir un tipo nuevo no requiere tocar el núcleo.
*/

:- multifile bloques:bloque/5.
:- multifile bloques:regla_hablante/5.
:- multifile bloques:regla_hablante_cond/6.
:- multifile bloques:regla_hablante_naive/6.

bloques:bloque(caballero/0, hablante,
               'caballero',
               'Siempre dice la verdad: su afirmación es verdadera.',
               'atributo(tipo, [caballero, truhan]).').

bloques:bloque(truhan/0, hablante,
               'truhan',
               'Siempre miente: su afirmación es falsa.',
               'atributo(tipo, [caballero, truhan]).').

bloques:bloque(normal/0, hablante,
               'normal',
               'Puede decir verdad o mentira: su afirmación no impone restricción.',
               'atributo(tipo, [caballero, truhan, normal]).').

bloques:bloque(alternante/0, hablante,
               'alternante',
               'Alterna entre verdad y mentira en el orden de sus pistas (por Id).',
               'atributo(tipo, [caballero, truhan, alternante]).').

bloques:bloque(ninguno/0, hablante,
               'ninguno',
               'Hablante especial: la afirmación es un hecho global verdadero.',
               'pista(4, ninguno, es(b, caballero)).').

% ------------------------------ solver FD ----------------------------------

bloques:regla_hablante(caballero, _, _, BF, _) :-
    BF #= 1.

bloques:regla_hablante(truhan, _, _, BF, _) :-
    BF #= 0.

bloques:regla_hablante(normal, _, _, _, _) :-
    1 #= 1.

bloques:regla_hablante(ninguno, _, _, BF, _) :-
    BF #= 1.

bloques:regla_hablante(alternante, Id, H, BF, Ctx) :-
    get_dict(alt, Ctx, Alt),
    memberchk(H-P, Alt),
    get_dict(pistas, Ctx, Pistas),
    paridad_de(Id, Pistas, H, Par),
    BF #<==> (P #= Par).

% --------------------------- solver FD condicionado -------------------------
% Activo es el booleano que indica si la entidad tiene este tipo. Así el núcleo
% puede imponer cada regla sólo cuando corresponde sin conocer los tipos.

bloques:regla_hablante_cond(caballero, Activo, _, _, BF, _) :-
    Activo #==> (BF #= 1).

bloques:regla_hablante_cond(truhan, Activo, _, _, BF, _) :-
    Activo #==> (BF #= 0).

bloques:regla_hablante_cond(normal, _, _, _, _, _) :-
    true.

bloques:regla_hablante_cond(alternante, Activo, Id, H, BF, Ctx) :-
    get_dict(alt, Ctx, Alt),
    memberchk(H-P, Alt),
    get_dict(pistas, Ctx, Pistas),
    paridad_de(Id, Pistas, H, Par),
    Activo #==> (BF #<==> (P #= Par)).

%!  paridad_de(+Id, +Pistas, +Hablante, -Par) is det.
%
%   0 si es la 1.ª, 3.ª, 5.ª… afirmación del hablante (en orden de Id); 1 si es la 2.ª, 4.ª…

paridad_de(Id, Pistas, Hablante, Par) :-
    findall(I, (member(pista(I, Hh, _, _), Pistas), Hh == Hablante), Ids0),
    sort(Ids0, Ids),
    nth0(Pos, Ids, Id),
    Par is Pos mod 2.

% ----------------------------- solver naive --------------------------------

bloques:regla_hablante_naive(caballero, _, _, Truth, _, Ok) :-
    bool_de(Truth == true, Ok).

bloques:regla_hablante_naive(truhan, _, _, Truth, _, Ok) :-
    bool_de(Truth == false, Ok).

bloques:regla_hablante_naive(normal, _, _, _, _, true).

bloques:regla_hablante_naive(ninguno, _, _, Truth, _, Ok) :-
    bool_de(Truth == true, Ok).

bloques:regla_hablante_naive(alternante, _Id, H, _Truth, Ctx, Ok) :-
    get_dict(pistas, Ctx, Pistas),
    findall(Par-T,
            ( member(pista(I, Hh, F, _), Pistas),
              Hh == H,
              paridad_de(I, Pistas, H, Par),
              bloques:eval_naive(F, Ctx, T)
            ),
            Pares),
    (   Pares == []
    ->  Ok = true
    ;   findall(P,
                ( member(Par-T, Pares),
                  ( T == true -> Bit = 1 ; Bit = 0 ),
                  P is (Bit + Par) mod 2
                ),
                Ps0),
        sort(Ps0, Ps),
        length(Ps, 1),
        Ok = true
    ).
