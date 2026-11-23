:- module(bloques,
          [ bloque/5,
            trad_fd/3,
            eval_naive/3,
            regla_explicacion/3,
            regla_hablante/5,
            regla_hablante_naive/6,
            es_bloque/1,
            es_formula_bloque/1,
            tipo_hablante/1,
            bloques/1,
            categoria/2,
            sintaxis/2,
            descripcion/2,
            ejemplo/2,
            valor_atributo/4,
            attr_valores/3,
            var_entidad/4,
            asig_valor/4,
            bool_de/2
          ]).

/** <module> Registro central de bloques

Único lugar donde se declara la semántica de cada bloque: nombre/aridad, categoría,
sintaxis, descripción, ejemplo, traducción a CLP(FD), evaluación concreta (solver naive)
y regla de explicación en español (Fase 2).

Para añadir un bloque: añadir una cláusula de bloque/5 en el módulo correspondiente de
bloques/ y sus cláusulas de trad_fd/3, eval_naive/3 y regla_explicacion/3. El núcleo
no se modifica.
*/

:- multifile bloque/5.
:- multifile trad_fd/3.
:- multifile eval_naive/3.
:- multifile regla_explicacion/3.
:- multifile regla_hablante/5.
:- multifile regla_hablante_cond/6.
:- multifile regla_hablante_naive/6.

%!  bloque(+Spec, +Categoria, +Sintaxis, +Descripcion, +Ejemplo) is nondet.
%
%   Registro declarativo de un bloque. Categoria es una de estructura, atributo,
%   conectiva, conteo o hablante. Los bloques de categoría 'estructura' son las
%   cabezas de los hechos del acertijo; el resto son términos de afirmación.

bloque(acertijo/2, estructura,
       'acertijo(Id, Titulo)',
       'Identificador y título legible del acertijo. Debe aparecer una sola vez.',
       'acertijo(isla_1, "Tres isleños").').

bloque(entidades/1, estructura,
       'entidades([E1, E2, ...])',
       'Lista de entidades del acertijo (átomos distintos).',
       'entidades([a, b, c]).').

bloque(atributo/2, estructura,
       'atributo(Nombre, [V1, V2, ...])',
       'Atributo y su dominio ordenado. El orden define vecino/3 y antes/3.',
       'atributo(tipo, [caballero, truhan]).').

bloque(pista/3, estructura,
       'pista(Id, Hablante, Afirmacion)',
       'Afirmación emitida por una entidad (o por ninguno, hecho global). El Id gobierna el orden de los alternantes.',
       'pista(1, a, es(b, truhan)).').

bloque(restriccion/1, estructura,
       'restriccion(Afirmacion)',
       'Afirmación global que siempre debe cumplirse; equivale a una pista de ninguno.',
       'restriccion(exactamente(2, [a,b,c], caballero)).').

%!  bloques(-Specs) is det.
%
%   Todas las especificaciones registradas, ordenadas.

bloques(Specs) :-
    findall(Spec, bloque(Spec, _, _, _, _), SinOrdenar),
    sort(SinOrdenar, Specs).

%!  es_bloque(+Spec) is semidet.
%
%   Cierto si Name/Aridad está registrado.

es_bloque(Spec) :-
    bloque(Spec, _, _, _, _).

%!  es_formula_bloque(+Spec) is semidet.
%
%   Cierto si Spec es un bloque utilizable dentro de una afirmación.

es_formula_bloque(Spec) :-
    bloque(Spec, Categoria, _, _, _),
    memberchk(Categoria, [atributo, conectiva, conteo]).

%!  tipo_hablante(+Tipo) is semidet.
%
%   Cierto si Tipo es un tipo de hablante registrado.

tipo_hablante(Tipo) :-
    bloque(Tipo/0, hablante, _, _, _).

%!  categoria(+Spec, -Categoria) is semidet.
%!  sintaxis(+Spec, -Sintaxis) is semidet.
%!  descripcion(+Spec, -Descripcion) is semidet.
%!  ejemplo(+Spec, -Ejemplo) is semidet.
%
%   Acceso a los metadatos del registro.

categoria(Spec, Categoria) :- bloque(Spec, Categoria, _, _, _).
sintaxis(Spec, Sintaxis) :- bloque(Spec, _, Sintaxis, _, _).
descripcion(Spec, Descripcion) :- bloque(Spec, _, _, Descripcion, _).
ejemplo(Spec, Ejemplo) :- bloque(Spec, _, _, _, Ejemplo).

%!  valor_atributo(+Attrs, +Valor, -Atributo, -Indice) is semidet.
%
%   Localiza el atributo que contiene Valor y su posición (base 0) en el dominio.
%   El validador garantiza que un valor pertenece a un solo atributo.

valor_atributo(Attrs, Valor, Atributo, Indice) :-
    member(att(Atributo, Valores), Attrs),
    nth0(Indice, Valores, Valor),
    !.

%!  attr_valores(+Ctx, +Atributo, -Valores) is semidet.
%
%   Dominio de un atributo del contexto.

attr_valores(Ctx, Atributo, Valores) :-
    get_dict(attrs, Ctx, Attrs),
    memberchk(att(Atributo, Valores), Attrs).

%!  var_entidad(+Ctx, +Entidad, +Atributo, -Var) is semidet.
%
%   Variable CLP(FD) que codifica el valor de Entidad en Atributo.

var_entidad(Ctx, Entidad, Atributo, Var) :-
    get_dict(vars, Ctx, Vars),
    memberchk(v(Entidad, Atributo, Var), Vars).

%!  asig_valor(+Ctx, +Entidad, +Atributo, -Valor) is semidet.
%
%   Valor concreto en el solver naive.

asig_valor(Ctx, Entidad, Atributo, Valor) :-
    get_dict(asig, Ctx, Asig),
    memberchk(Entidad-Atributo-Valor, Asig).

%!  bool_de(+Goal, -Truth) is det.
%
%   Convierte el éxito o fracaso de Goal en los átomos true o false.

bool_de(Goal, Truth) :-
    (   call(Goal)
    ->  Truth = true
    ;   Truth = false
    ).
