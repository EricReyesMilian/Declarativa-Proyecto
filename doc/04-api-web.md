# 04 · API web

> Estado: implementada y verificada con `curl`.

## Base

Servidor `library(http/thread_httpd)` + `http_dispatch` en `prolog/servidor.pl`.
Puerto por defecto 8080 (`make run PORT=8080`, o `swipl main.pl -- --port=8080`).
Todas las respuestas JSON usan `http_json`. Los archivos estáticos se sirven desde
`web/`.

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` e `/index.html` | Editor (`web/index.html`) |
| GET | `/app.js`, `/styles.css`, `/plantillas.json` | Estáticos, sin build |
| GET | `/api/ejemplos` | `{"ejemplos":[{"id":...,"titulo":...}]}` ordenados por Id |
| GET | `/api/ejemplo?id=isla_1` | `{"id":...,"titulo":...,"codigo":"..."}`; 404 si no existe |
| GET | `/api/plantillas` | Contenido de `web/plantillas.json` |
| POST | `/api/analizar` | `{codigo, limite, tiempo, minimalidad}` → `{ok, informe, errores}` |
| POST | `/api/explicacion` | `{codigo}` → `{ok, texto, errores}` |

## Ejemplo

```sh
curl -X POST http://localhost:8080/api/analizar \
  -H 'Content-Type: application/json' \
  -d '{"codigo":"acertijo(t, \"T\").\nentidades([a]).\natributo(tipo,[caballero,truhan]).\npista(1,a,es(a,caballero)).\n"}'
```

Respuesta real para un acertijo único:

```json
{
  "ok": true,
  "errores": [],
  "informe": {
    "estado": "unico",
    "numero_soluciones": 1,
    "unica": true,
    "irreductible": true,
    "pistas_sobrantes": [],
    "minimalidad_fuerte": "inconcluso",
    "aviso": "",
    "soluciones": [
      [{"entidad": "a", "atributos": {"tipo": "caballero"}}]
    ]
  }
}
```

`estado` puede ser `unico`, `multiple`, `inconsistente`, `timeout` o `error`.
Cuando `soluciones` está cortado por el límite, el aviso lo indica.

## Convenciones

- Los errores llevan `linea`, `id` (null si no aplica), `mensaje` y `sugerencia`,
  siempre en español; la interfaz permite pulsarlos para ir a la línea.
- Nunca se devuelve una traza cruda de Prolog.
- Todo análisis corre bajo `call_with_time_limit/2`; si expira se devuelve
  `estado: "timeout"` con un aviso legible.
- `limite` se acota a 1…100 (por defecto 100), `tiempo` a 1…10 segundos (5) y
  `minimalidad` es booleano (false).
