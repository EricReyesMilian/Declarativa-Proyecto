# 00 · Visión general

> Estado: implementado. Vocabulario confirmado en Fase 0 y fases 1 y 2 completadas.

## Qué hace

Plataforma para **escribir, validar, analizar y resolver** acertijos lógicos de caballeros y
truhanes y variantes (normales, alternantes, puertas, colores, cuadrículas, conteos y
autorreferencia). El usuario escribe un archivo `.pl` con hechos Prolog planos; no hay parser,
DCG, lenguaje natural ni generación automática de acertijos. La facilidad de uso viene de una
sintaxis mínima y regular, una biblioteca de bloques documentada y una interfaz web con plantillas
y asistente guiado.

## Alcance por fases

| Fase | Contenido | Estado |
|---|---|---|
| 0 | Catálogo de tipos, decisión del vocabulario de bloques | ✅ `doc/10` |
| 1 | Cargador seguro, validador, solver FD + naive, análisis, servidor y web | ✅ completado |
| 2 | Explicación paso a paso (propagación, casos, reducción al absurdo) | ⏳ diseñada, no implementada |

## Principios

- Un acertijo es **datos**: hechos con cabezas de una lista blanca. Nunca se ejecuta código
  arbitrario del usuario.
- Un bloque es un functor con semántica registrada en un **único lugar** (`prolog/bloques.pl`).
  Añadir un bloque = añadir una cláusula + su plantilla + su test.
- Núcleo declarativo y modificable por estudiantes: sin operadores nuevos, sin macros ocultas,
  sin trazas crudas de Prolog en la interfaz.

## Limitaciones conocidas

- No se modela la dimensión epistémica dinámica de los acertijos de inducción (turnos, silencio
  como información, conocimiento común); véase `doc/10`, tipo D.
- El tipo `normal` no restringe sus afirmaciones, por definición.
- El tipo `alternante` necesita un orden: se usa el `Id` numérico de las pistas.
- La explicación automática (Fase 2) es un motor distinto del solver y no sustituye la verificación
  con restricciones.
- SWI-Prolog instalado en el entorno de desarrollo: 10.0.2 (el proyecto apunta a la API de
  SWI-Prolog 9; las librerías usadas son estándar y compatibles).
