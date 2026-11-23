acertijo(casas, "Tres casas").
entidades([a, b, c]).
atributo(tipo, [caballero, truhan]).
atributo(color, [rojo, azul, verde]).
atributo(posicion, [uno, dos, tres]).
restriccion(todos_distintos(color, [a, b, c])).
restriccion(todos_distintos(posicion, [a, b, c])).
restriccion(vecino(a, b, posicion)).
restriccion(antes(b, c, posicion)).
