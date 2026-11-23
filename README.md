# Plataforma de acertijos lógicos (Prolog + web)

Proyecto de **Programación Declarativa**: escribir, validar, analizar y resolver acertijos de
caballeros y truhanes y variantes, escritos por el usuario como Prolog plano.

> Estado actual: **Fases 0, 1 y 2 completadas**. 30 pruebas plunit, 12 ejemplos y API HTTP verificada.

## Estructura

```
.
├── main.pl         punto de entrada del servidor
├── doc/            12 documentos numerados (índice: doc/00-vision-general.md)
├── prolog/         módulos SWI-Prolog (núcleo, bloques, solvers, análisis, API)
├── web/            HTML + CSS + JS vanilla, sin npm ni build
├── examples/       12 acertijos .pl de ejemplo
├── tests/          pruebas plunit por módulo
├── herramientas/   comprobación de documentación
└── Makefile        make test / make run / make docs-check
```

## Puesta en marcha

```sh
make test         # 30 pruebas plunit
make run          # servidor en http://localhost:8080 (PORT=... para cambiar)
make docs-check   # comprueba los 12 documentos y las cabeceras de módulos
make verificar    # test + docs-check
```

También se puede arrancar directamente:

```sh
swipl main.pl -- --port=8080
```

## Uso rápido

Abre `http://localhost:8080`, elige un ejemplo (por defecto se carga `isla_1`) y pulsa
**Analizar**. El editor permite insertar bloques desde la paleta, ver errores pulsables con
línea y sugerencia, pedir una explicación y guardar o descargar el acertijo.

Ejemplo de API:

```sh
curl -X POST http://localhost:8080/api/analizar \
  -H 'Content-Type: application/json' \
  -d '{"codigo":"acertijo(isla_1, \"Tres isleños\").\nentidades([a,b,c]).\natributo(tipo,[caballero,truhan]).\npista(1,a,es(b,truhan)).\npista(2,b,es(c,truhan)).\npista(3,c,igual_tipo(a,b)).\n"}'
```

## Documentación

Índice: `doc/00-vision-general.md`. Catálogo y fuentes: `doc/10-catalogo-tipos-acertijos.md`.
Sintaxis del usuario: `doc/03-como-escribir-acertijos.md`. Decisiones: `doc/08-decisiones.md`.
Seguridad: `doc/11-seguridad.md`.
