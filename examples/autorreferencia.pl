acertijo(autorreferencia, "Autorreferencia").
entidades([a, b]).
atributo(tipo, [caballero, truhan]).
pista(1, a, si(es(a, caballero), es(b, truhan))).
pista(2, b, es(a, truhan)).
