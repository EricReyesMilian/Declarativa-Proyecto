acertijo(conteo_afirmaciones, "Contar afirmaciones").
entidades([a, b, c]).
atributo(tipo, [caballero, truhan]).
pista(1, a, es(b, caballero)).
pista(2, b, es(c, truhan)).
pista(3, c, es(a, truhan)).
restriccion(exactamente(1, [es(b, caballero), es(c, truhan), es(a, truhan)])).
