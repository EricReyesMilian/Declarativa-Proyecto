:- module(main, [main/0]).

:- use_module(prolog/servidor, [servir/1, parar/0]).

/** <module> Punto de entrada de la aplicación

Uso: swipl main.pl -- --port=8080
     make run PORT=8080
*/

%!  main is det.
%
%   Lee --port=N (o la variable de entorno PORT) y arranca el servidor HTTP.
%   El puerto por defecto es 8080.

main :-
    current_prolog_flag(argv, Argv),
    (   member(Arg, Argv),
        atom_concat('--port=', PuertoAtom, Arg),
        atom_number(PuertoAtom, Puerto0)
    ->  Puerto = Puerto0
    ;   getenv('PORT', PuertoTexto)
    ->  atom_number(PuertoTexto, Puerto)
    ;   Puerto = 8080
    ),
    format('Taller de acertijos lógicos: http://localhost:~w/~n', [Puerto]),
    servir(Puerto),
    repeat,
    sleep(3600),
    fail.

:- initialization(main, main).
