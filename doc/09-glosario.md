# 09 · Glosario

> Estado: completo; incluye los términos usados por el código y la interfaz.

| Término | Definición |
|---|---|
| **Acertijo** | Conjunto de hechos Prolog con cabecera, entidades, atributos, pistas y restricciones. |
| **Atributo** | Dimensión finita de las entidades (`tipo`, `color`, `estado`, `posicion`…). |
| **Bloque** | Functor con semántica registrada centralmente y traducción al solver. |
| **Dominio** | Lista ordenada de valores posibles de un atributo. |
| **Hablante** | Entidad que emite una pista, o `ninguno` si es un hecho global. |
| **Pista** | Hecho `pista(Id, Hablante, Afirmacion)` con regla de veracidad. |
| **Restricción** | Hecho `restriccion(Afirmacion)` equivalente a una pista global. |
| **Afirmación** | Término booleano construido con bloques atómicos y conectivas. |
| **Reificación** | Representar el valor de verdad de una restricción como variable 0/1 (`#<==>`). |
| **Etiquetado** | `labeling/2`: asignar valores concretos a las variables con dominio finito. |
| **Solución** | Asignación completa que satisface todas las restricciones. |
| **Unicidad** | Existe exactamente una solución. |
| **Irredundancia** | Ninguna pista puede eliminarse sin perder la unicidad. |
| **Minimalidad fuerte** | El menor subconjunto de pistas que conserva la solución única. |
| **Macro** | Regla Prolog del usuario que se expande a bloques existentes. |
| **Lista blanca** | Conjunto de cabezas de cláusulas que el cargador acepta. |
| **CLP(FD)** | Constraint Logic Programming sobre dominios finitos; motor principal. |
| **CLP(B)** | Constraint Logic Programming sobre variables booleanas; alternativa evaluada. |
| **Normal** | Tipo de hablante sin regla de veracidad: sus afirmaciones no restringen. |
| **Alternante** | Tipo de hablante que alterna verdadero/falso en el orden de sus pistas. |
