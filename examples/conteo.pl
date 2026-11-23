acertijo(conteo, "Conteo de tipos").
entidades([a, b, c, d]).
atributo(tipo, [caballero, truhan]).
pista(1, a, es(d, truhan)).
restriccion(exactamente(2, [a, b, c, d], caballero)).
restriccion(al_menos(1, [a, b, c, d], truhan)).
