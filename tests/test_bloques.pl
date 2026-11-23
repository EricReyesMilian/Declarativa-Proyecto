/** <module> Pruebas del registro central de bloques. */

:- begin_tests(bloques).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').

test(registro_completo) :-
    findall(Spec, bloques:bloque(Spec, _, _, _, _), Specs),
    sort(Specs, Unicos),
    length(Unicos, 28),
    forall(member(Spec, Unicos), bloques:es_bloque(Spec)).

test(categorias) :-
    findall(C, bloques:categoria(_, C), Categorias),
    sort(Categorias, Unicas),
    length(Unicas, 5).

test(tipos_de_hablante) :-
    forall(member(T, [caballero, truhan, normal, alternante, ninguno]),
           bloques:tipo_hablante(T)).

test(registro_extensible) :-
    predicate_property(bloques:bloque(_, _, _, _, _), multifile),
    predicate_property(bloques:trad_fd(_, _, _), multifile),
    predicate_property(bloques:eval_naive(_, _, _), multifile),
    predicate_property(bloques:regla_explicacion(_, _, _), multifile).

:- end_tests(bloques).
