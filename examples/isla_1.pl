acertijo(isla_1, "Tres isleños").
entidades([a, b, c]).
atributo(tipo, [caballero, truhan]).
pista(1, a, es(b, truhan)).
pista(2, b, es(c, truhan)).
pista(3, c, igual_tipo(a, b)).
