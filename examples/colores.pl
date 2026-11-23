acertijo(colores, "Colores y tipos").
entidades([a, b, c]).
atributo(color, [rojo, azul]).
atributo(tipo, [caballero, truhan]).
restriccion(exactamente(2, [a, b, c], rojo)).
restriccion(no(igual(a, b, color))).
restriccion(si(es(a, caballero), es(c, azul))).
pista(1, a, es(b, rojo)).
