/** <module> Pruebas de utilidades de la API HTTP. */

:- begin_tests(servidor).

:- use_module('../prolog/bloques').
:- use_module('../prolog/bloques/atributos').
:- use_module('../prolog/bloques/conectivas').
:- use_module('../prolog/bloques/conteo').
:- use_module('../prolog/bloques/hablantes').
:- use_module('../prolog/macros_biblioteca').
:- use_module('../prolog/servidor').

test(opciones_api) :-
    servidor:opciones_api(_{codigo:"", limite:5, tiempo:20, minimalidad:true}, O),
    O.limite == 5,
    O.tiempo == 10,
    O.minimalidad == true,
    O.max_clausulas == 12.

test(mapa_errores) :-
    servidor:mapa_errores([err(3, 2, 'Mensaje', 'Sugerencia'), err(0, null, 'Otro', 'Suge')], Json),
    length(Json, 2),
    once((member(E, Json), E.linea == 3, E.id == 2, E.mensaje == 'Mensaje')),
    once((member(E2, Json), E2.linea == 0, E2.id == @(null))).

test(informe_json_soluciones) :-
    Informe = informe{ estado:unico, numero_soluciones:1,
                       soluciones:[[sol(a,[tipo-caballero]), sol(b,[tipo-1])]],
                       unica:true, irreductible:true, pistas_sobrantes:[],
                       minimalidad_fuerte:true, aviso:'' },
    servidor:informe_json(Informe, Json),
    Json.soluciones = [[E1, E2]],
    E1.entidad == a, E1.atributos.tipo == caballero,
    E2.entidad == b, E2.atributos.tipo == 1.

test(ejemplo_valido) :-
    once(servidor:ejemplo_valido(isla_1, Titulo, _)),
    Titulo == "Tres isleños".

test(ejemplo_inexistente) :-
    \+ servidor:ejemplo_valido('no_existe', _, _).

:- end_tests(servidor).
