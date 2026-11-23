:- module(test_all, []).

/** <module> Suite completa de pruebas

Carga todos los módulos plunit y se ejecuta con `swipl -q -g run_tests -t halt tests/test_all.pl`.
*/

:- ensure_loaded(test_bloques).
:- ensure_loaded(test_cargador).
:- ensure_loaded(test_validador).
:- ensure_loaded(test_solver_fd).
:- ensure_loaded(test_analisis).
:- ensure_loaded(test_explicacion).
:- ensure_loaded(test_servidor).
