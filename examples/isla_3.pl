acertijo(isla_3, "Un normal entre nosotros").
entidades([a, b]).
atributo(tipo, [caballero, truhan, normal]).
pista(1, a, es(b, truhan)).
pista(2, b, es(a, caballero)).
restriccion(exactamente(1, [a, b], truhan)).
