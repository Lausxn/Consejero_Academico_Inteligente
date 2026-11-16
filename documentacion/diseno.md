# Diseño — Consejero Académico Inteligente

Documento de diseño, previo a la implementación. Define los predicados de cada archivo, el contrato entre C y Prolog, la tabla del menú y cómo se aplica SOLID. Los nombres pueden ajustarse durante la implementación; si algo cambia, se actualiza aquí.

---

## 1. Decisiones de diseño

| # | Decisión | Justificación de Diseno | 
|---|---|---|
| D1 | **Prolog incrustado en C** (API `SWI-Prolog.h`) en lugar de pipes. | Hay una sola sesión de Prolog en memoria durante toda la ejecución: los hechos dinámicos (`assert`/`retract`) persisten entre consultas, no hay que interpretar texto, las soluciones se recorren una a una con `PL_next_solution` (backtracking real visible desde C) y los errores llegan como excepciones (`PL_exception`). Con pipes habría que serializar y parsear todo y sincronizar dos procesos. |
| D2 | **gcc con las rutas de `swipl --dump-runtime-variables`** en vez de `swipl-ld`. | Probado: en Windows, `swipl-ld` 10.1.16 arma `-D_SWIPL_HOME=C:/Program Files/swipl` sin comillas y gcc falla por el espacio. El enunciado permite esta alternativa. En Linux se usa `pkg-config swipl`. |
| D3 | **La persistencia la hace Prolog**: `registros.txt` guarda términos Prolog (`estudiante/2`, `aprobado/2`). | C no toca datos del dominio. El archivo se puede leer a mano y se carga con `read_term` (no con `consult`), validando cada término antes del `assert`. |
| D4 | **Las explicaciones las arma Prolog como texto.** | C solo imprime, así que nunca interpreta el resultado. |
| D5 | **El front-end en C no usa acentos.** | Es más portable entre consolas. Los nombres de los cursos se mantienen exactos en `hechos.pl`, como pide el enunciado. |
| D6 | **Correquisitos simétricos.** | Si A es correquisito de B, B también lo es de A. Se cumplen si el otro curso ya está aprobado o si se matricula en la misma combinación. |
| D7 | **Topes de créditos: 18 por ciclo y 36 por año (2 ciclos).** | Lo definió el equipo. Los topes son hechos en Prolog (`datos_ficticios.pl`), no constantes en C. |
| D8 | **La disponibilidad no depende del ciclo en curso** (por ahora). | El enunciado no lo pide. Queda como posible extensión (ver §9). |
| D9 | **Opción extra "Recargar base de conocimientos"** (`make/0`). | En la defensa el profesor edita `hechos.pl` en vivo: con esta opción el cambio se aplica sin recompilar C y sin reiniciar el programa. |
| D10 | **Carné = cédula de 9 dígitos**, guardada como entero en Prolog. | Ejemplo: `208490835`. C valida solo el formato (9 dígitos); Prolog decide si el estudiante existe. |

---

## 2. Predicados por archivo (back-end)

Dependencias en una sola dirección:

```
hechos ─┐
datos_ficticios ─┼─> reglas ─> inferencia ─> explicaciones ─> consultas  <── C
estudiantes ─┘
```

### 2.1 `hechos.pl` — plan oficial (sin cambios respecto al enunciado)
| Predicado | Tipo | Descripción |
|---|---|---|
| `curso/6` | hecho | `curso(Codigo, Nombre, Creditos, Nivel, Ciclo, Tipo)` (67 cursos: 36 de nivel, 23 optativos disciplinarios, 8 libres) |
| `requisito/2` | hecho | `requisito(Curso, CursoRequerido)` |
| `creditos_diplomado/1`, `creditos_bachillerato/1` | hecho | 88 y 140 |
| `optativas_requeridas/1`, `min_optativas_disciplinarias/1` | hecho | 4 y 2 |
| `area_general/2` | hecho | área de cada curso de Estudios Generales |

### 2.2 `datos_ficticios.pl` — FICTICIO
| Predicado | Tipo | Descripción |
|---|---|---|
| `correquisito_base/2` | hecho | `eif201–mat002`, `eif209–eif210`, `eif401–eif402` (se escriben en un solo sentido) |
| `horario/5` | hecho | `horario(Curso, Grupo, Dia, HoraInicio, HoraFin)`: días `lunes..viernes`, horas enteras de 7 a 21, 1 o 2 grupos, unos 4 choques intencionales |
| `tope_creditos_ciclo/1`, `tope_creditos_anual/1` | hecho | 18 y 36 |

Los cursos de I a IV nivel tienen horario. Solo algunos optativos tienen horario: el resto se considera "no ofertado este ciclo" y no entra en las combinaciones (sí puede aparecer como disponible).

### 2.3 `estudiantes.pl` — datos dinámicos y persistencia
| Predicado | Descripción |
|---|---|
| `estudiante/2` (dinámico) | `estudiante(Carne, Nombre)` |
| `aprobado/2` (dinámico) | `aprobado(Carne, Curso)` |
| `registrar_estudiante/2` | `assert` si no existe |
| `agregar_aprobado/2`, `quitar_aprobado/2` | `assert`/`retract` |
| `guardar_registros/1`, `cargar_registros/1` | escribe y lee `datos/registros.txt` (`writeq` / `read_term`) |

### 2.4 `reglas.pl` — reglas base
| Predicado | Descripción |
|---|---|
| `existe_curso/1`, `creditos_de/2`, `nivel_de/2` | acceso al plan |
| `es_optativo/1`, `es_disciplinario/1`, `ofertado/1` | clasificación (ofertado = tiene horario) |
| `correquisito/2` | cierre simétrico de `correquisito_base/2` |
| `cumple_requisitos/2` | todos los requisitos directos aprobados (`forall`) |
| `requisito_faltante/3` | `requisito_faltante(Est, Curso, Faltante)`: requisito directo no aprobado |
| `puede_cursarse/2` | no aprobado y cumple requisitos |
| `disponible/2` | `puede_cursarse` y cada correquisito está aprobado o también puede cursarse (se matricula junto) |
| `correquisito_pendiente/3` | correquisito no aprobado que debe ir en la misma matrícula |
| `choque_grupos/4` | `choque_grupos(C1, G1, C2, G2)`: mismo día y horas solapadas |
| `choque/2` | dos cursos con al menos un par de grupos que chocan |
| `suma_creditos/2` | **recursiva propia** sobre una lista de cursos |
| `creditos_aprobados/2` | `findall` de aprobados + `suma_creditos` |

### 2.5 `inferencia.pl` — recursivas y compuestas
| Predicado | Descripción |
|---|---|
| `requiere_indirecto/2` | **RECURSIVA.** Caso base: requisito directo. Caso recursivo: requisito de un requisito. Termina porque el grafo de requisitos es acíclico. |
| `cadena_requisitos/2` | `setof` de todos los requisitos (directos e indirectos) |
| `pendientes_totales/3` | cadena de requisitos menos los aprobados (`subtract`) |
| `ruta_hacia/3` | **RECURSIVA, varias soluciones.** `ruta_hacia(Est, Meta, Ruta)`: cadena `[C1, ..., Meta]` donde C1 está disponible y cada Ci+1 requiere a Ci. El backtracking genera todas las cadenas. |
| `plan_por_ciclos/3` | **RECURSIVA.** Agrupa en etapas (ciclos) todos los cursos que faltan para la meta. Termina cuando la lista de pendientes queda vacía; cada paso aprueba en simulación al menos un curso. |
| `cursos_que_desbloquea/2` | cursos que tienen a X como requisito directo |
| `cantidad_desbloquea/2` | cantidad de cursos que dependen de X (directa o indirectamente) |
| `cursos_disponibles/2` | `findall` de `disponible/2` |
| `nivel_actual/2`, `atrasado/2` | nivel más alto con aprobados; un curso disponible de nivel menor está atrasado |
| `prioridad/3`, `cursos_priorizados/2` | orden: atrasados → los que desbloquean más → nivel/ciclo |
| `combinacion_valida/3` | **BACKTRACKING.** `combinacion_valida(Est, Tope, [Curso-Grupo, ...])`: sin choques, créditos ≤ tope y correquisitos pendientes incluidos |
| `combinacion_maximal/3` | combinación válida a la que no se le puede agregar ningún curso más |
| `asignar_grupos/2` | **BACKTRACKING.** Para una selección del usuario, busca grupos sin choque |
| `recomendar/4` | primeras N combinaciones maximales en orden de prioridad (`limit/2`) |
| `recomendar_anual/3` | ciclo 1 + ciclo 2 (simula aprobar el ciclo 1), tope anual de 36 |
| `porcentaje_avance/2` | créditos aprobados / 140 |
| `cumple_diplomado/1`, `cumple_bachillerato/1` | obligatorios/generales hasta el nivel correspondiente + créditos (+ optativas en el bachillerato) |
| `optativas_ok/1` | 4 optativas aprobadas, de las cuales al menos 2 son disciplinarias |

### 2.6 `explicaciones.pl` — el "por qué"
| Predicado | Explica |
|---|---|
| `explicar_disponible/3` | requisitos cumplidos y correquisitos |
| `explicar_no_disponible/3` | ya aprobado, falta X (con la cadena: "falta EIF211, que a su vez requiere EIF207") o correquisito no cursable |
| `explicar_recomendacion/3` | atrasado o cuántos cursos desbloquea |
| `explicar_choque/3` | día y horas en que se solapan dos grupos |
| `explicar_avance/2` | créditos, %, por qué cumple o no el diplomado/bachillerato/optativas |
| `explicar_ruta/3` | por qué la ruta tiene ese orden |

### 2.7 `consultas.pl` — API única para C
| Predicado | Opción del menú |
|---|---|
| `consulta_registrar_estudiante(Carne, Nombre, Fila)` | 1 |
| `consulta_agregar_aprobado(Carne, Curso, Fila)`, `consulta_quitar_aprobado/3`, `consulta_aprobados/2` | 2 |
| `consulta_plan_nivel(Nivel, Fila)`, `consulta_plan_tipo(Tipo, Fila)`, `consulta_requisitos_curso(Curso, Fila)` | 3 |
| `consulta_disponibles(Carne, Fila)` | 4 |
| `consulta_que_falta(Carne, Curso, Fila)` | 5 |
| `consulta_ruta(Carne, Meta, Fila)` | 6 |
| `consulta_choques(Seleccion, Fila)` | 7 |
| `consulta_recomendar(Carne, Modalidad, Tope, Fila)` | 8 |
| `consulta_avance(Carne, Fila)` | 9 |
| `consulta_reporte(Carne, Fila)` | 10 |
| `consulta_guardar(Fila)`, `consulta_cargar(Fila)` | 11 y al iniciar/salir |
| `consulta_recargar_base(Fila)` | 12 |
| `consulta_existe_estudiante(Carne, Fila)`, `consulta_existe_curso(Curso, Fila)` | validación previa (RF-03) |

---

## 3. Contrato de las consultas (igual para todas, principio L)

```
consulta_<caso>(+Arg1, ..., +ArgN, -Fila)
```

- **Entradas:** siempre llegan desde C como *strings*. Prolog las normaliza (pasa el código a minúscula y el carné a número).
- **Salida:** `Fila` es una **lista de textos** (las columnas de una fila). La consulta es **no determinista**: cada solución es una fila y C las recorre una a una con `PL_next_solution`.
- **Sin resultados:** la consulta falla sin errores, y C muestra "sin resultados" (RF-13).
- **Error del dominio:** `throw(error_sipa(Mensaje))`, por ejemplo "El estudiante 208490835 no existe" o "El tope supera 18 creditos por ciclo". C lo atrapa con `PL_exception` y muestra el mensaje.
- **Comandos** (registrar, guardar, etc.): devuelven una sola fila con el mensaje de confirmación.
- Las entradas de lista (opción 7) llegan como un solo string separado por espacios o comas, por ejemplo `"eif206 eif207 eif211"`. Prolog lo separa con `split_string`.

---

## 4. Contrato de `integracion/conexion.h`

El front-end **solo** incluye este header y nunca incluye `SWI-Prolog.h` (principios D e I).

```c
#define CONEXION_OK              0
#define CONEXION_SIN_RESULTADOS  1
#define CONEXION_ERROR           2
#define CONEXION_TAM_MENSAJE     512

typedef struct {
    int    cantidad;      /* columnas de la fila */
    char **columnas;      /* textos (memoria propia, se libera con conexion_liberar) */
} FilaResultado;

typedef struct {
    int            cantidad;   /* filas = soluciones de Prolog */
    FilaResultado *filas;
    char           mensaje_error[CONEXION_TAM_MENSAJE];
} ResultadoConsulta;

int  conexion_iniciar(const char *programa);   /* PL_initialise + consult backend/main.pl */
void conexion_cerrar(void);                     /* PL_cleanup */

/* Arma la meta dinamicamente: consulta(arg1, ..., argN, Fila).
   Rechaza cualquier predicado que no empiece con "consulta_". */
int  conexion_consultar(const char *consulta,
                        const char *argumentos[], int cantidad_argumentos,
                        ResultadoConsulta *resultado);

void conexion_liberar(ResultadoConsulta *resultado);
```

Internamente, `conexion_consultar` hace lo siguiente: `PL_predicate(consulta, n+1, "consultas")` → `PL_new_term_refs` → `PL_put_string_chars` por cada argumento → `PL_open_query(..., PL_Q_CATCH_EXCEPTION)` → un ciclo `PL_next_solution` que convierte la lista Prolog a `FilaResultado` (`PL_get_list` / `PL_get_chars`) → `PL_exception` si hubo error → `PL_close_query`.

---

## 5. Front-end en C

| Archivo | Responsabilidad |
|---|---|
| `main.c` | `conexion_iniciar` → `consulta_cargar` → `menu_ejecutar` → `consulta_guardar` → `conexion_cerrar` |
| `menu.c/h` | tabla de opciones y los manejadores de cada caso de uso (piden datos, validan, llaman a conexión, mandan a imprimir) |
| `interfaz.c/h` | títulos, tablas con columnas alineadas, mensajes de error y éxito, pausa |
| `validaciones.c/h` | carné (9 dígitos), formato de código de curso, enteros en rango, opción de menú, texto no vacío |

### 5.1 Tabla del menú (principio O)

```c
typedef void (*ManejadorOpcion)(void);

typedef struct {
    int             numero;
    const char     *texto;
    ManejadorOpcion manejador;
} OpcionMenu;

static const OpcionMenu OPCIONES[] = {
    { 1,  "Registrar estudiante",                     opcion_registrar_estudiante },
    { 2,  "Registrar / quitar cursos aprobados",      opcion_cursos_aprobados },
    { 3,  "Consultar plan de estudios",               opcion_plan_estudios },
    { 4,  "Cursos disponibles para matricular",       opcion_disponibles },
    { 5,  "Que me falta para llevar un curso",        opcion_que_falta },
    { 6,  "Ruta de avance hacia un curso meta",       opcion_ruta },
    { 7,  "Detectar choques de horario",              opcion_choques },
    { 8,  "Recomendar combinaciones de cursos",       opcion_recomendar },
    { 9,  "Avance de carrera",                        opcion_avance },
    { 10, "Generar reporte de planificacion",         opcion_reporte },
    { 11, "Guardar / cargar sesion",                  opcion_sesion },
    { 12, "Recargar base de conocimientos",           opcion_recargar },
    { 0,  "Salir",                                    NULL }
};
```

Agregar una opción es agregar una fila. El ciclo del menú busca el número elegido en la tabla y llama al manejador.

### 5.2 Validaciones en C (solo formato; RF-03)
- **Carné:** exactamente 9 dígitos.
- **Código de curso:** 2 o 3 letras + 1 a 3 dígitos + `o` opcional (cubre `eif200`, `eg1`, `eif420o`, `eig416o`). Se acepta en mayúscula o minúscula.
- **Opción del menú y números:** entero dentro del rango pedido (por ejemplo, nivel 1–4 y tope ≥ 1). El **máximo** del tope lo decide Prolog (D7).
- **Existencia** del curso o del estudiante: se le pregunta a Prolog (`consulta_existe_*`) antes de la consulta principal, porque C no conoce el dominio.

---

## 6. Flujo de una consulta (para la defensa)

```
Usuario elige "4. Cursos disponibles"
 → menu.c: opcion_disponibles() pide el carne (interfaz.c)
 → validaciones.c: validar_carne("208490835") ok
 → conexion.c: conexion_consultar("consulta_existe_estudiante", ...)   ok
 → conexion.c: conexion_consultar("consulta_disponibles", {"208490835"}, 1, &r)
      PL_predicate + PL_open_query + while (PL_next_solution) { lista -> FilaResultado }
 → Prolog: consultas.pl → inferencia:cursos_priorizados → reglas:disponible
           → explicaciones:explicar_disponible  (una fila por curso)
 → interfaz.c: interfaz_mostrar_tabla(&r)   [Codigo | Nombre | Cr | Por que]
 → conexion_liberar(&r)
```

---

## 7. Aplicación de SOLID (sin clases; a nivel de módulos y funciones)

| Principio | Dónde se aplica |
|---|---|
| **S** Responsabilidad única | Cada archivo hace una sola cosa: `interfaz.c` solo imprime, `validaciones.c` solo valida, `conexion.c` solo habla con Prolog, `explicaciones.pl` solo explica, `hechos.pl` solo tiene hechos. Las funciones tienen menos de 40 líneas. |
| **O** Abierto/cerrado | Se agrega un curso o requisito en `hechos.pl` sin tocar C (con recarga en vivo, D9). Se agrega una opción con una fila nueva en `OPCIONES[]`. |
| **L** Sustitución | Todas las `consulta_*` cumplen el contrato de §3, y todos los manejadores tienen la firma `void (*)(void)`, así que son intercambiables en la tabla. |
| **I** Segregación de interfaces | `menu.h` expone solo `menu_ejecutar()`. `conexion.h` no expone tipos de SWI-Prolog. Cada módulo Prolog exporta solo lo que la capa superior usa. |
| **D** Inversión de dependencias | `menu.c` e `interfaz.c` dependen de `conexion.h` (una abstracción), no de `SWI-Prolog.h`. Se podría cambiar a pipes reescribiendo solo `conexion.c`. |
| DRY / otros | Un único `ejecutar_y_mostrar()` en `menu.c` para todas las consultas, constantes con `#define`, `-Wall -Wextra` sin warnings y toda la memoria se libera en `conexion_liberar`. |

---

## 8. Datos de prueba (`datos/registros.txt`)

| Carné | Nombre | Perfil |
|---|---|---|
| 208490835 | Lausen Paniagua Arias | Mitad de II nivel (EIF200, MAT030, LIX410, EIF201, MAT002, LIX411, EIF202, EIF203, EIF204, MAT005) |
| 1xxxxxxxx | (ficticio) | Primer ingreso, sin aprobados |
| 1xxxxxxxx | (ficticio) | Diplomado completo (88 créditos) |
| 1xxxxxxxx | (ficticio) | Atrasado: sin LIX411 ni EIF202, pero con cursos de III nivel que no dependen de ellos (EIF209, EIF210, EIF211) |

Además se agrega el ejemplo del enunciado (EIF200, MAT030, EIF201, MAT002, EIF204, EIF203) como caso de prueba.

---

## 9. Fuera de alcance (posibles extensiones)
- Que la disponibilidad dependa del ciclo en curso (D8).
- Ofertas de horario por ciclo real.
