:- module(servidor,
          [ servir/1,
            parar/0
          ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- use_module(library(readutil)).
:- use_module(library(files)).

:- use_module(bloques).
:- use_module(bloques/atributos).
:- use_module(bloques/conectivas).
:- use_module(bloques/conteo).
:- use_module(bloques/hablantes).
:- use_module(macros_biblioteca).
:- use_module(cargador, [cargar_codigo/3, cargar_archivo/3]).
:- use_module(validador, [validar/3]).
:- use_module(analisis, [analizar/3]).
:- use_module(explicacion, [explicar/3]).

/** <module> Servidor HTTP

API JSON y archivos estáticos. El código del usuario nunca se consulta como
programa Prolog: pasa por el cargador y el validador antes de llegar al solver.
*/

:- dynamic web_directorio/1.
:- dynamic ejemplos_directorio/1.

:- prolog_load_context(directory, Dir),
   directory_file_path(Dir, '../web', W0),
   directory_file_path(Dir, '../examples', E0),
   absolute_file_name(W0, Web, [file_type(directory)]),
   absolute_file_name(E0, Ejemplos, [file_type(directory)]),
   assertz(web_directorio(Web)),
   assertz(ejemplos_directorio(Ejemplos)).

:- http_handler(root('api/ejemplos'), api_ejemplos, [methods([get])]).
:- http_handler(root('api/ejemplo'), api_ejemplo, [methods([get])]).
:- http_handler(root('api/plantillas'), api_plantillas, [methods([get])]).
:- http_handler(root('api/analizar'), api_analizar, [methods([post])]).
:- http_handler(root('api/explicacion'), api_explicacion, [methods([post])]).
:- http_handler(root('index.html'), sirve_archivo('index.html'), []).
:- http_handler(root('app.js'), sirve_archivo('app.js'), []).
:- http_handler(root('styles.css'), sirve_archivo('styles.css'), []).
:- http_handler(root('plantillas.json'), sirve_archivo('plantillas.json'), []).
:- http_handler(root(.), sirve_indice, []).

%!  servir(+Puerto) is det.
%
%   Inicia el servidor HTTP en Puerto.

servir(Puerto) :-
    http_server(http_dispatch, [port(Puerto)]).

%!  parar is det.
%
%   Detiene todas las instancias del servidor.

parar :-
    forall(http_server(Http, [port(_)]), http_stop_server(Http, [])),
    !.
parar.

% ------------------------------ estáticos ----------------------------------

sirve_indice(Request) :-
    sirve_archivo('index.html', Request).

sirve_archivo(Nombre, Request) :-
    web_directorio(Dir),
    directory_file_path(Dir, Nombre, Ruta),
    (   exists_file(Ruta)
    ->  http_reply_file(Ruta, [cache(false), unsafe(true)], Request)
    ;   throw(http_reply(not_found(Ruta)))
    ).

% ------------------------------- API ---------------------------------------

api_ejemplos(_Request) :-
    findall(Id-Titulo,
            ejemplo_valido(Id, Titulo, _),
            Pares0),
    sort(Pares0, Pares),
    findall(_{id:Id, titulo:Titulo}, member(Id-Titulo, Pares), Ejemplos),
    reply_json_dict(_{ejemplos:Ejemplos}).

api_ejemplo(Request) :-
    catch(http_parameters(Request,
                          [ id(Id, [atom])
                          ],
                          []),
          _,
          ( Id = '' )),
    (   ejemplo_valido(Id, Titulo, Ruta)
    ->  read_file_to_string(Ruta, Codigo, []),
        reply_json_dict(_{id:Id, titulo:Titulo, codigo:Codigo})
    ;   reply_json_dict(_{error:'Ejemplo no encontrado.'}, [status(404)])
    ).

api_plantillas(_Request) :-
    web_directorio(Dir),
    directory_file_path(Dir, 'plantillas.json', Ruta),
    catch(open_string_file(Ruta, Texto),
          _,
          Texto = '{"categorias":[]}'),
    open_string(Texto, Stream),
    catch(json_read_dict(Stream, Datos),
          _,
          Datos = _{categorias:[]}),
    close(Stream),
    reply_json_dict(Datos).

api_analizar(Request) :-
    (   catch(http_read_json_dict(Request, Datos), _, fail)
    ->  true
    ;   Datos = _{}
    ),
    (   get_dict(codigo, Datos, Codigo), string(Codigo)
    ->  true
    ;   Codigo = ""
    ),
    cargar_codigo(Codigo, Hechos, ErroresCarga),
    (   ErroresCarga == []
    ->  validar(Hechos, Puzzle, ErroresValidacion),
        (   ErroresValidacion == []
        ->  opciones_api(Datos, Opciones),
            catch(analizar(Puzzle, Opciones, Informe),
                  Error,
                  ( Informe = informe{estado:'error',
                                      numero_soluciones:null,
                                      soluciones:[],
                                      unica:false,
                                      irreductible:null,
                                      pistas_sobrantes:[],
                                      minimalidad_fuerte:inconcluso,
                                      aviso:'El análisis no pudo completarse.'},
                    ignore(Error)
                  )),
            informe_json(Informe, InformeJson),
            reply_json_dict(_{ok:true, informe:InformeJson, errores:[]})
        ;   mapa_errores(ErroresValidacion, ErroresJson),
            reply_json_dict(_{ok:false, informe:null, errores:ErroresJson})
        )
    ;   mapa_errores(ErroresCarga, ErroresJson),
        reply_json_dict(_{ok:false, informe:null, errores:ErroresJson})
    ).

api_explicacion(Request) :-
    (   catch(http_read_json_dict(Request, Datos), _, fail)
    ->  true
    ;   Datos = _{}
    ),
    (   get_dict(codigo, Datos, Codigo), string(Codigo) -> true ; Codigo = "" ),
    cargar_codigo(Codigo, Hechos, ErroresCarga),
    (   ErroresCarga == []
    ->  validar(Hechos, Puzzle, ErroresValidacion),
        (   ErroresValidacion == []
        ->  (   catch(explicacion:explicar(Puzzle, _, Texto), _, fail)
            ->  reply_json_dict(_{ok:true, texto:Texto})
            ;   reply_json_dict(_{ok:false,
                                  errores:[_{linea:0, id:null,
                                             mensaje:'La explicación no está disponible para este acertijo.',
                                             sugerencia:'Usa el análisis para ver la solución.'}]})
            )
        ;   mapa_errores(ErroresValidacion, ErroresJson),
            reply_json_dict(_{ok:false, errores:ErroresJson})
        )
    ;   mapa_errores(ErroresCarga, ErroresJson),
        reply_json_dict(_{ok:false, errores:ErroresJson})
    ).

% ------------------------------ utilidades ---------------------------------

opciones_api(Datos, opciones{limite:Limite, tiempo:Tiempo,
                             minimalidad:Minimalidad, max_clausulas:12}) :-
    get_dict_def(limite, Datos, 100, Limite0),
    limitar(Limite0, 1, 100, Limite),
    get_dict_def(tiempo, Datos, 5, Tiempo0),
    limitar(Tiempo0, 1, 10, Tiempo),
    (   get_dict(minimalidad, Datos, true) -> Minimalidad = true ; Minimalidad = false ).

get_dict_def(Clave, Datos, Defecto, Valor) :-
    (   get_dict(Clave, Datos, Valor0), number(Valor0) -> Valor = Valor0 ; Valor = Defecto ).

limitar(Valor0, Min, Max, Valor) :-
    Valor is max(Min, min(Max, round(Valor0))).

informe_json(Informe, Json) :-
    maplist(soluciones_json, Informe.soluciones, SolucionesJson),
    Json = _{ estado:Informe.estado,
              numero_soluciones:Informe.numero_soluciones,
              soluciones:SolucionesJson,
              unica:Informe.unica,
              irreductible:Informe.irreductible,
              pistas_sobrantes:Informe.pistas_sobrantes,
              minimalidad_fuerte:Informe.minimalidad_fuerte,
              aviso:Informe.aviso
            }.

soluciones_json(Solucion, EntidadesJson) :-
    findall(E, (member(sol(Nombre, Pares), Solucion),
                pares_json(Pares, Atributos),
                E = _{entidad:Nombre, atributos:Atributos}),
            EntidadesJson).

pares_json(Pares, Json) :-
    findall(A-V, (member(A-V0, Pares), term_to_atom_safe(V0, V)), ParesJson),
    dict_create(Json, _, ParesJson).

term_to_atom_safe(V, V) :- atom(V), !.
term_to_atom_safe(V, V) :- integer(V), !.
term_to_atom_safe(V, A) :- term_to_atom(V, A).

mapa_errores(Errores, Json) :-
    findall(E, (member(err(L, Id, M, S), Errores),
                id_json(Id, IdJ),
                E = _{linea:L, id:IdJ, mensaje:M, sugerencia:S}), Json).

id_json(null, @(null)) :- !.
id_json(Id, Id).

open_string_file(Ruta, Texto) :-
    read_file_to_string(Ruta, Texto, []).

ejemplo_valido(Id, Titulo, Ruta) :-
    ejemplos_directorio(Dir),
    directory_files(Dir, Entradas),
    member(Entrada, Entradas),
    atom_concat(Id0, '.pl', Entrada),
    atom_concat(Id0, '', Id),
    \+ sub_atom(Id, _, _, _, '/'),
    directory_file_path(Dir, Entrada, Ruta),
    cargar_archivo(Ruta, Hechos, []),
    validar(Hechos, Puzzle, []),
    Titulo = Puzzle.titulo.
