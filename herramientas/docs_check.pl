:- module(docs_check, [ejecutar/0]).

:- use_module(library(readutil)).

:- dynamic ruta_raiz/1.
:- prolog_load_context(directory, Herramientas),
   directory_file_path(Herramientas, '..', Raiz0),
   absolute_file_name(Raiz0, Raiz, [file_type(directory)]),
   assertz(ruta_raiz(Raiz)).

/** <module> Comprobación ligera de documentación

Verifica que existan los doce documentos numerados, que no queden marcadores
pendientes y que cada módulo Prolog tenga documentación de módulo.
*/

%!  ejecutar is det.
%
%   Imprime un informe y falla si falta algún documento o alguna cabecera.

ejecutar :-
    ruta_raiz(Raiz),
    directory_file_path(Raiz, doc, DocDir),
    findall(Nombre,
            ( between(0, 11, N),
              ( N < 10 -> format(atom(Prefijo), '0~w', [N])
              ; atom_number(Prefijo, N)
              ),
              atom_concat(Prefijo, '-', Base),
              directory_files(DocDir, Entradas),
              member(Entrada, Entradas),
              atom_concat(Base, _, Entrada),
              atom_concat(_, '.md', Entrada),
              Nombre = Entrada
            ),
            Docs0),
    sort(Docs0, Docs),
    ( length(Docs, 12) -> true
    ; format(user_error, 'Faltan documentos: ~w~n', [Docs]), fail
    ),
    forall(member(Documento, Docs), comprobar_documento(DocDir, Documento)),
    findall(Ruta,
            ( member(Carpeta, ['', 'prolog', 'prolog/bloques', 'tests', 'herramientas']),
              directory_file_path(Raiz, Carpeta, Dir0),
              absolute_file_name(Dir0, Dir, [file_type(directory)]),
              directory_files(Dir, EntradasModulo),
              member(Archivo, EntradasModulo),
              atom_concat(_, '.pl', Archivo),
              directory_file_path(Dir, Archivo, Ruta)
            ),
            Modulos0),
    sort(Modulos0, Modulos),
    forall(member(Modulo, Modulos), comprobar_modulo(Modulo)),
    length(Modulos, TotalModulos),
    format('Documentación comprobada: 12 documentos, ~w módulos.~n',
           [TotalModulos]).

comprobar_documento(Dir, Nombre) :-
    directory_file_path(Dir, Nombre, Ruta),
    read_file_to_string(Ruta, Texto, []),
    ( Texto == "" -> format(user_error, 'Documento vacío: ~w~n', [Nombre]), fail ; true ),
    ( sub_atom(Texto, _, _, _, 'TODO') -> format(user_error, 'TODO en ~w~n', [Nombre]), fail ; true ).

comprobar_modulo(Ruta) :-
    read_file_to_string(Ruta, Texto, []),
    (   sub_atom(Texto, _, _, _, '/** <module>')
    ->  true
    ;   format(user_error, 'Sin documentación de módulo: ~w~n', [Ruta]), fail
    ).
