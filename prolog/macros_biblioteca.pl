:- module(macros_biblioteca, []).

:- multifile cargador:macro_biblioteca/4.

/** <module> Macros de biblioteca

Ataques sintácticos predefinidos, registrados en el cargador. No son bloques: se
expanden antes de la validación semántica, por lo que añadir una macro no obliga
a tocar los solvers. El cuarto argumento son cálculos auxiliares que el cargador
resuelve tras sustituir los argumentos de la llamada.
*/

cargador:macro_biblioteca(igual_tipo/2, igual_tipo(X, Y), igual(X, Y, tipo), []).
cargador:macro_biblioteca(distinto_tipo/2, distinto_tipo(X, Y), distinto(X, Y, tipo), []).
cargador:macro_biblioteca(todos/2, todos(L, V), al_menos(N, L, V), [longitud(L, N)]).
cargador:macro_biblioteca(alguno/2, alguno(L, V), al_menos(1, L, V), []).
cargador:macro_biblioteca(ninguno/2, ninguno(L, V), exactamente(0, L, V), []).
cargador:macro_biblioteca(sigue/3, sigue(X, Y, A),
                          y(vecino(X, Y, A), antes(X, Y, A)), []).
