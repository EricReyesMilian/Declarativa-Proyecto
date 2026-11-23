acertijo(alternantes, "Alternancia por Id").
entidades([a, b]).
atributo(tipo, [caballero, truhan, alternante]).
pista(1, a, es(b, caballero)).
pista(2, a, es(b, truhan)).
restriccion(exactamente(1, [a, b], caballero)).
