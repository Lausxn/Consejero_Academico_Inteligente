# Manual técnico — Consejero Académico Inteligente

**Universidad Nacional de Costa Rica** · Escuela de Informática
**Curso:** Paradigmas de Programación · **Ciclo:** II 2026
**Profesor:** Juan de Dios Murillo
**Proyecto Programado N.º 2** — Alternativa B: Planificación Académica Universitaria
**Estudiantes:** Lausen Paniagua Arias · Génesis Silesky Araya

---

## 1. Problema

Un estudiante de Ingeniería en Sistemas de Información necesita saber qué cursos puede matricular, qué le falta para llevar un curso, cómo llegar a un curso meta, qué combinaciones de cursos no chocan y cuánto le falta para el Diplomado (88 créditos) o el Bachillerato (140 créditos).

El **Consejero Académico Inteligente** razona sobre el plan de estudios oficial (P.UNA-2498-21) y el historial del estudiante para:

- registrar estudiantes y sus cursos aprobados;
- consultar el plan por nivel, por tipo y los requisitos de cada curso;
- deducir requisitos directos e indirectos y correquisitos;
- determinar los cursos disponibles y explicar por qué;
- detectar requisitos pendientes ("¿qué me falta para llevar X?");
- detectar choques de horario y proponer grupos sin choque;
- recomendar combinaciones sin choque dentro de un tope de créditos (18 por ciclo, 36 por año);
- construir rutas de avance hacia un curso meta;
- calcular el avance de carrera (créditos, %, Diplomado, Bachillerato, optativas);
- generar un reporte de planificación por estudiante.

Ninguna conclusión ("disponible", "pendiente", "choque", "ruta", "recomendación") se guarda como hecho: **todas se deducen con reglas**.

---

## 2. Arquitectura

Tres capas, con dependencias en una sola dirección:

```
Usuario
  │
  ▼
┌──────────────────────────── CAPA 1: presentación (solo C) ───────────────────────────┐
│ main.c        ciclo de vida: iniciar Prolog, cargar datos, menú, guardar, cerrar     │
│ menu.c/h      tablas de opciones {número, texto, manejador} y casos de uso            │
│ interfaz.c/h  títulos, mensajes, tablas con ajuste de texto, lectura de líneas        │
│ validaciones.c/h  formato de carné, código de curso, enteros, texto, selección        │
└───────────────────────────────────────┬──────────────────────────────────────────────┘
                                        │ solo conexion.h
┌───────────────────────────── CAPA 2: integración ────────────────────────────────────┐
│ conexion.c/h  PL_initialise · PL_predicate · PL_open_query · PL_next_solution ·       │
│               PL_exception · PL_close_query · PL_cleanup                              │
└───────────────────────────────────────┬──────────────────────────────────────────────┘
                                        │ solo predicados consulta_*
┌──────────────────────────── CAPA 3: razonamiento (solo Prolog) ──────────────────────┐
│ consultas.pl      API única: un consulta_* por caso de uso                            │
│ explicaciones.pl  el "por qué" de cada conclusión                                     │
│ inferencia.pl     recursivas, backtracking, recomendaciones, avance                   │
│ reglas.pl         disponibilidad, requisitos, correquisitos, choques, créditos        │
│ hechos.pl · datos_ficticios.pl · estudiantes.pl    (datos)                            │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

Dependencias en Prolog: `hechos / datos_ficticios / estudiantes → reglas → inferencia → explicaciones → consultas`. Ningún módulo usa algo de una capa superior. Cada archivo es un módulo de SWI-Prolog (`:- module(...)`) que exporta solo lo que la capa de arriba necesita.

### 2.1 Estructura de carpetas

```
frontend/       main.c, menu.c/h, interfaz.c/h, validaciones.c/h
integracion/    conexion.c/h
backend/        main.pl, hechos.pl, datos_ficticios.pl, estudiantes.pl,
                reglas.pl, inferencia.pl, explicaciones.pl, consultas.pl
datos/          registros.txt, reportes/
pruebas/        pruebas_prolog.pl, prueba_integracion.c, casos_prueba.txt
documentacion/  diseno.md, manual_tecnico.md, manual_usuario.md, guia_defensa.md
Makefile, README.md
```

---

## 3. Base de conocimientos

### 3.1 Datos oficiales (`backend/hechos.pl`)

Se copió **exactamente** el plan del enunciado: 67 cursos, 81 requisitos, reglas de graduación y áreas de Estudios Generales.

| Hecho | Significado | Cantidad |
|---|---|---|
| `curso(Codigo, Nombre, Creditos, Nivel, Ciclo, Tipo)` | cursos (36 de nivel, 23 optativos disciplinarios, 8 libres) | 67 |
| `requisito(Curso, Requerido)` | requisito directo | 81 |
| `creditos_diplomado/1`, `creditos_bachillerato/1` | 88 y 140 | 2 |
| `optativas_requeridas/1`, `min_optativas_disciplinarias/1` | 4 y 2 | 2 |
| `area_general(Curso, Area)` | área de cada Estudios Generales | 4 |

Las pruebas verifican que los datos cuadran: I y II nivel más III nivel I ciclo suman 88 créditos, y los cursos fijos más 4 optativas suman 140.

### 3.2 Datos ficticios (`backend/datos_ficticios.pl`)

Están separados de los oficiales y marcados como **FICTICIOS**:

| Hecho | Detalle |
|---|---|
| `correquisito_base/2` | `eif201–mat002`, `eif209–eif210`, `eif401–eif402`; son simétricos vía `reglas:correquisito/2` |
| `horario(Curso, Grupo, Dia, Inicio, Fin)` | 1 o 2 grupos para los 36 cursos de nivel y 10 optativos ofertados |
| `tope_creditos_ciclo/1`, `tope_creditos_anual/1` | 18 y 36 |
| `dia_semana/2` | orden de los días |

Hay 5 choques intencionales, documentados en el archivo:

| # | Choque | Qué demuestra |
|---|---|---|
| 1 | EIF206-1 y EIF207-1 | se resuelve con EIF207-2 |
| 2 | EIF209-1 y EIF210-1 | son correquisitos, así que deben ir juntos: se resuelve con EIF210-2 |
| 3 | EIF211-1 y EIF212-1 | se resuelve con EIF211-2 |
| 4 | EIF402-1 y EIF412-1 | inevitable: cada uno tiene un solo grupo |
| 5 | EIF207-2 y EIF427o-1 | choque entre un optativo y un obligatorio |

### 3.3 Datos dinámicos (`backend/estudiantes.pl`)

Son `estudiante(Carne, Nombre)` y `aprobado(Carne, Curso)`, declarados `dynamic` y modificados con `assertz/retract`. Se guardan en `datos/registros.txt` como términos Prolog. Al cargar se usa `read_term/3` (no `consult`) y se valida cada término antes del `assert`.

---

## 4. Reglas e inferencia

### 4.1 Reglas base (`reglas.pl`)

| Regla | Lógica |
|---|---|
| `cumple_requisitos(E, C)` | `forall(requisito(C, R), aprobado(E, R))` |
| `requisito_faltante(E, C, R)` | requisito directo no aprobado |
| `puede_cursarse(E, C)` | existe, no aprobado y cumple requisitos |
| `disponible(E, C)` | puede cursarse **y** cada correquisito está aprobado o también puede cursarse (se matricula junto) |
| `correquisito(A, B)` | cierre simétrico de `correquisito_base/2` |
| `choque_grupos(C1, G1, C2, G2)` | mismo día y horas solapadas (`I1 < F2, I2 < F1`) |
| `suma_creditos(Lista, T)` | **recursiva** sobre la lista |

### 4.2 Reglas recursivas (con condición de terminación)

| Predicado | Caso base | Caso recursivo | Terminación |
|---|---|---|---|
| `requiere_indirecto/2` | `requisito(C, R)` | `requisito(C, X), requiere_indirecto(X, R)` | el grafo de requisitos es acíclico y finito |
| `ruta_hacia/3` → `ruta_atras/4` | el curso actual ya puede cursarse | retroceder a un requisito faltante | cada paso baja un nivel en el grafo |
| `cursos_necesarios/3` → `cierre/4` | no queda nada por visitar | encolar requisitos y correquisitos de un curso nuevo | la lista de visitados crece y el plan es finito |
| `plan_por_etapas/3` → `etapas/3` | no quedan pendientes | aprobar en simulación los listos y seguir | cada etapa tiene al menos un curso |
| `ciclos_estimados/3` | lista vacía, 0 ciclos | ciclos de la primera etapa + resto | la lista se acorta |
| `describir_pendiente/3` | el requisito pendiente no tiene faltantes | describir sus faltantes | grafo acíclico |
| `suma_creditos/2` | `[]` suma 0 | cabeza + suma de la cola | la lista se acorta |
| `leer_terminos/1` | `end_of_file` | cargar un término y seguir | el archivo es finito |
| `curso_en_ciclo/1` → `alcanza/3` | el objetivo es requisito directo | seguir por un requisito no visitado | la lista de visitados crece; sirve para detectar ciclos agregados en vivo |

### 4.3 Backtracking

| Escenario | Predicado | Cómo se usa |
|---|---|---|
| Cursos disponibles | `disponible(E, X)` | cada solución liga `X` a otro curso; C las recorre con `PL_next_solution` |
| Combinaciones sin choque | `combinacion_valida/3` → `elegir/4` | por cada candidato prueba **incluirlo** (con cada grupo que no choque) o **excluirlo**; al fallar un tope o un choque retrocede |
| Grupos para una selección | `asignar_grupos/2` | prueba grupos; si chocan, retrocede al grupo anterior |
| Rutas alternativas | `ruta_hacia/3` | cada requisito faltante es una rama distinta: 3 rutas hacia EIF402 |

### 4.4 Reglas de inferencia compuestas

| Regla | Combina |
|---|---|
| `disponible/2` | `puede_cursarse` + correquisitos cubiertos |
| `atrasado/2` | `disponible` + `nivel_de` + `nivel_actual` |
| `cursos_priorizados/2` | `disponible` + `atrasado` + `es_optativo` + `cantidad_desbloquea` + nivel/ciclo |
| `combinacion_maximal/3` | `combinacion_valida` + `se_puede_agregar` |
| `recomendar_anual/4` | `recomendar` + simulación de aprobar el ciclo 1 (`con_simulacion/4`) |
| `cumple_diplomado/1`, `cumple_bachillerato/1` | faltantes + créditos + `optativas_ok` |

**Prioridad de recomendación (RF-12):**
1. cursos atrasados (de un nivel menor al actual);
2. cursos del plan antes que optativos;
3. los que desbloquean más cursos, directa o indirectamente;
4. nivel y ciclo más bajos.

### 4.5 Explicaciones (`explicaciones.pl`)

| Predicado | Ejemplo real |
|---|---|
| `explicar_disponible/3` | "Tiene aprobados todos sus requisitos: EIF204, MAT002." |
| `explicar_no_disponible/3` | "No esta disponible porque falta EIF212, que a su vez requiere EIF205; EIF211, que a su vez requiere EIF206 y EIF207." |
| `explicar_recomendacion/3` | "Esta atrasado: es de nivel 2 y ya cursa nivel 3. Desbloquea 15 curso(s) en total…" |
| `explicar_choque/3` | "EIF206 G1 y EIF207 G1 coinciden el martes de 16:00 a 19:00." |
| `explicar_ruta/3` | "Empiece por EIF205 (ya cumple sus requisitos); …" |
| `explicar_avance/2` | "Diplomado: CUMPLE (88 creditos, minimo 88)." |

---

## 5. Integración C – Prolog

### 5.1 Decisión: Prolog incrustado

Se usa la API de C de SWI-Prolog en lugar de pipes con `swipl`:

- Hay **una sola sesión** de Prolog en memoria, así que los hechos dinámicos (`assert/retract`) se mantienen entre consultas.
- **Backtracking visible desde C:** cada `PL_next_solution` produce la siguiente solución.
- **Errores estructurados:** `PL_exception` entrega el término `error_sipa(Mensaje)`, sin parsear texto.
- No hay que sincronizar dos procesos ni serializar los resultados.

**Compilación:** en Windows, `swipl-ld` 10.1.16 arma `-D_SWIPL_HOME=C:/Program Files/swipl` sin comillas, y gcc falla por el espacio. Por eso el `Makefile` usa gcc con las rutas de `swipl --dump-runtime-variables` (`PLBASE`, `PLLIBDIR`, `-lswipl`), alternativa permitida por el enunciado. En Linux usa `pkg-config swipl`.

### 5.2 Contrato de la API (`consultas.pl`)

```prolog
consulta_<caso>(+Arg1, ..., +ArgN, -Fila)
```

- **Entradas:** texto tal como lo escribió el usuario. Prolog lo normaliza y lo valida.
- **`Fila`:** una lista de textos. Cada **solución es una fila**.
- **Sin resultados:** la consulta falla.
- **Error del dominio:** `throw(error_sipa(Mensaje))`.
- Toda la salida pasa por `responder/2`, que la entrega en texto plano y sin acentos.

Hay 22 consultas: `consulta_existe_estudiante`, `consulta_existe_curso`, `consulta_estudiantes`, `consulta_registrar_estudiante`, `consulta_agregar_aprobado`, `consulta_quitar_aprobado`, `consulta_aprobados`, `consulta_tipos`, `consulta_plan_nivel`, `consulta_plan_tipo`, `consulta_requisitos_curso`, `consulta_disponibles`, `consulta_que_falta`, `consulta_ruta`, `consulta_choques`, `consulta_modalidades`, `consulta_recomendar`, `consulta_avance`, `consulta_reporte`, `consulta_guardar`, `consulta_cargar` y `consulta_recargar_base`.

### 5.3 `conexion.h`

```c
int  conexion_iniciar(const char *programa, char *mensaje, int tam_mensaje);
void conexion_cerrar(void);
int  conexion_consultar(const char *consulta,
                        const char *argumentos[], int cantidad_argumentos,
                        ResultadoConsulta *resultado);   /* OK | SIN_RESULTADOS | ERROR */
void conexion_liberar(ResultadoConsulta *resultado);
```

`conexion_consultar` hace lo siguiente:
1. Valida la petición (solo `consulta_*`, como máximo 8 argumentos).
2. Abre un marco con `PL_open_foreign_frame`.
3. Arma la meta con `PL_predicate(nombre, N+1, "consultas")` y pasa cada argumento con `PL_unify_chars(PL_STRING | REP_MB)`.
4. Abre la consulta con `PL_open_query(..., PL_Q_CATCH_EXCEPTION)` y la recorre con `while (PL_next_solution)`. Cada solución se convierte en una `FilaResultado` usando `PL_skip_list`, `PL_get_list` y `PL_get_chars`, y cada texto se copia a memoria propia.
5. Consulta `PL_exception`: si es `error_sipa(M)`, el mensaje es M; si es otra excepción, se informa como "Error interno de Prolog: …".
6. Cierra con `PL_close_query` y `PL_discard_foreign_frame`.

`conexion_liberar` libera toda la memoria; llamarla dos veces no da error. La prueba de integración hace 1000 consultas seguidas sin problemas.

### 5.4 Flujo de una consulta

```
Usuario elige "4. Cursos disponibles"
 → menu.c: opcion_disponibles() → pedir_carne_registrado()
 → validaciones.c: validar_carne("208490835")             (formato)
 → conexion_consultar("consulta_existe_estudiante", ...)  (existencia, en Prolog)
 → conexion_consultar("consulta_disponibles", {"208490835"}, 1, &r)
      PL_predicate + PL_open_query + while (PL_next_solution) → FilaResultado
 → Prolog: consultas → inferencia:cursos_priorizados → reglas:disponible
           → explicaciones:explicar_disponible   (una fila por curso)
 → interfaz.c: interfaz_mostrar_tabla(...)   [Codigo | Nombre | Cr | Por que]
 → conexion_liberar(&r)
```

---

## 6. Persistencia y reportes

- **RF-14:** cada alta o baja se guarda al instante. El programa carga los registros al iniciar y los guarda al salir; la opción 11 permite guardar y cargar a mano.
- **RF-15:** `consulta_reporte` escribe `datos/reportes/reporte_<carne>.txt` con 6 secciones: avance, aprobados, disponibles con explicación, recomendación por ciclo, recomendación anual y plan hacia el Bachillerato. **Cada sección reutiliza la consulta del menú**, así que el reporte muestra lo mismo que la pantalla.
- **Cambio en vivo:** `consulta_recargar_base` ejecuta `make/0`, que recarga los `.pl` modificados sin reiniciar el programa ni recompilar C. `hechos.pl` declara `curso/6` y `requisito/2` como `discontiguous`, así que se pueden agregar hechos en cualquier parte del archivo.

---

## 7. Decisiones de diseño

| # | Decisión | Motivo |
|---|---|---|
| D1 | Prolog incrustado | ver §5.1 |
| D2 | gcc + `--dump-runtime-variables` | `swipl-ld` falla en Windows por el espacio en la ruta |
| D3 | Persistencia en Prolog | C no toca datos del dominio |
| D4 | Explicaciones como texto armado en Prolog | C solo imprime |
| D5 | Salida sin acentos | consola portable; los nombres se mantienen exactos en `hechos.pl` |
| D6 | Correquisitos simétricos | así funciona un correquisito real |
| D7 | Topes 18/36 como hechos en Prolog | el máximo lo decide el dominio, no C |
| D8 | La disponibilidad no depende del ciclo en curso | fuera del alcance (posible extensión) |
| D9 | Opción 12, "Recargar base" | demo en vivo sin reiniciar |
| D10 | Carné = cédula de 9 dígitos | formato en C, existencia en Prolog |
| D11 | Optativos sin horario = "no ofertado" | pueden estar disponibles, pero no entran en combinaciones |
| D12 | "Mínimo de etapas" y "ciclos estimados" | las etapas no respetan el tope; los ciclos estimados sí |
| D13 | Tipos de curso, modalidades y topes los entrega Prolog | C arma los submenús sin conocer el dominio (`consulta_tipos`, `consulta_modalidades`) |
| D14 | Formato de código de curso amplio (2–4 letras, 1–4 dígitos) | acepta cursos nuevos agregados en vivo; la existencia la decide Prolog |
| D15 | Detección de ciclos al recargar | las recursivas suponen un grafo acíclico; un requisito mal agregado se advierte en lugar de colgar el sistema |

El detalle está en `documentacion/diseno.md`.

---

## 8. Pruebas

| Tipo | Archivo | Resultado |
|---|---|---|
| Unitarias del back-end (plunit) | `pruebas/pruebas_prolog.pl` | **63/63** |
| Integración C ↔ Prolog | `pruebas/prueba_integracion.c` | **17/17** |
| Casos documentados | `pruebas/casos_prueba.txt` | **31** casos con entrada, esperado, obtenido y evidencia |

Comandos: `mingw32-make test`, `mingw32-make test-c` y `mingw32-make test-todo`. Las pruebas usan copias temporales de `registros.txt` y una carpeta temporal para los reportes, así que no modifican `datos/`.

---

## 9. Conteo de los mínimos del motor lógico

Los números de cantidad se obtuvieron recorriendo los módulos cargados con `current_predicate/1` y `clause/2`.

| Mínimo exigido | Requerido | Obtenido | Dónde (predicados) |
|---|---|---|---|
| Hechos | 40 | **224** estáticos (+65 dinámicos) | `hechos.pl`: 156 (`curso/6` ×67, `requisito/2` ×81, graduación y áreas ×8); `datos_ficticios.pl`: 68 (`horario/5` ×58, `correquisito_base/2` ×3, `dia_semana/2` ×5, topes ×2); `registros.txt`: 5 `estudiante/2` + 60 `aprobado/2` |
| Reglas | 20 | **189** cláusulas con cuerpo | `reglas` 25 · `inferencia` 51 · `explicaciones` 27 · `consultas` 72 · `estudiantes` 14 |
| Predicados propios | 15 | **180** | `hechos` 7 · `datos_ficticios` 5 · `estudiantes` 11 · `reglas` 23 · `inferencia` 46 · `explicaciones` 23 · `consultas` 65 |
| Consultas distintas | 10 | **22** | los `consulta_*` de §5.2 |
| Reglas recursivas | 2 | **9** | `requiere_indirecto/2`, `alcanza/3`, `ruta_atras/4`, `cierre/4`, `etapas/3`, `ciclos_estimados/3`, `describir_pendiente/3`, `suma_creditos/2`, `leer_terminos/1` |
| Operaciones con listas | 3 | **10+** | `findall/3` (`cursos_disponibles`), `setof/3` (`cadena_requisitos`), `member/2` y `memberchk/2` (`choca_con`), `subtract/3` (`pendientes_totales`), `suma_creditos/2` (recorrido propio), `include/3` (`candidatos_combinacion`), `keysort/2` + `pairs_values/2` (`cursos_priorizados`), `append/3` (`cierre`), `list_to_set/2` (`seleccion_valida`) |
| Escenarios de backtracking | 3 | **4** | `disponible/2`, `combinacion_valida/3`, `asignar_grupos/2`, `ruta_hacia/3` |
| Reglas de inferencia compuestas | 5 | **7** | `disponible/2`, `atrasado/2`, `cursos_priorizados/2`, `combinacion_maximal/3`, `recomendar_anual/4`, `cumple_diplomado/1`, `cumple_bachillerato/1` |
| Explicaciones | 5 | **6** | `explicar_disponible/3`, `explicar_no_disponible/3`, `explicar_recomendacion/3`, `explicar_choque/3`, `explicar_ruta/3`, `explicar_avance/2` |
| Casos de prueba | 15 | **31** documentados (63 plunit + 17 de integración) | `pruebas/casos_prueba.txt` |

---

## 10. Aplicación de SOLID

El enunciado prohíbe clases, así que SOLID se aplica a nivel de **módulos, archivos, funciones y predicados**.

| Principio | Archivo / función que lo demuestra |
|---|---|
| **S** Responsabilidad única | `interfaz.c` (solo imprime y lee), `validaciones.c` (solo formato), `conexion.c` (solo habla con Prolog), `explicaciones.pl` (solo explica) |
| **O** Abierto/cerrado | `MENU_PRINCIPAL[]` en `menu.c`; `hechos.pl` + `consulta_recargar_base/1` |
| **L** Sustitución | contrato común de `consulta_*`; firma `void (*)(void)` de todos los manejadores |
| **I** Segregación de interfaces | `menu.h` (solo `menu_ejecutar`), `conexion.h` (sin tipos de SWI-Prolog), listas de exportación de cada módulo |
| **D** Inversión de dependencias | `menu.c` e `interfaz.c` incluyen `conexion.h`, nunca `SWI-Prolog.h` |

### S — Responsabilidad única
Cada archivo hace una sola cosa. Por ejemplo, `validaciones.c` solo decide formatos y no sabe si un curso existe:

```c
int validar_codigo_curso(const char *texto)   /* eif200, EG1, eif420o */
{
    ...
    letras = contar_mientras(texto, isalpha);
    digitos = contar_mientras(texto + letras, isdigit);
    ...
}
```

La existencia se le pregunta a Prolog (`consulta_existe_curso`) desde `menu.c`. Del mismo modo, `explicaciones.pl` no decide nada: solo convierte en texto lo que deducen `reglas.pl` e `inferencia.pl`. Todas las funciones en C tienen menos de 40 líneas; la más larga es `pedir_carne_registrado`, con 31.

### O — Abierto/cerrado
El menú es una tabla. Agregar la opción 10 (reporte) fue **agregar una fila**, sin tocar el motor del menú:

```c
static const OpcionMenu MENU_PRINCIPAL[] = {
    ...
    { 9,  "Avance de carrera",                  opcion_avance },
    { 10, "Generar reporte de planificacion",   opcion_reporte },   /* fila nueva */
    ...
};
```

En Prolog, agregar un curso o un requisito en `hechos.pl` cambia las respuestas **sin modificar C** (demo de la opción 12).

### L — Sustitución (adaptado)
Todas las `consulta_*` cumplen el mismo contrato, así que `conexion_consultar` trata cualquiera de ellas igual:

```prolog
consulta_disponibles(CarneT, Fila)          % misma forma
consulta_que_falta(CarneT, CursoT, Fila)    % misma forma
consulta_recomendar(CarneT, Modalidad, Tope, Fila)
```

Además, todos los manejadores del menú tienen la firma `typedef void (*ManejadorOpcion)(void);`, de modo que son intercambiables en cualquier tabla (`MENU_PRINCIPAL`, `MENU_APROBADOS`, `MENU_PLAN`, `MENU_SESION`).

### I — Segregación de interfaces
`menu.h` expone una sola función:

```c
void menu_ejecutar(void);
```

`conexion.h` expone solo `FilaResultado`, `ResultadoConsulta` y 4 funciones, sin ningún tipo de SWI-Prolog. En Prolog, cada módulo tiene su lista de exportación; por ejemplo, `reglas.pl` no exporta `correquisito_cubierto/2` ni `horas_solapadas/4`, que son internos.

### D — Inversión de dependencias
El front-end depende de la abstracción `conexion.h`:

```c
/* menu.c */
#include "conexion.h"      /* nunca <SWI-Prolog.h> */
...
estado = conexion_consultar(consulta, argumentos, cantidad, &resultado);
```

Solo `conexion.c` incluye `SWI-Prolog.h`. Para cambiar a pipes con `swipl` bastaría con reescribir `conexion.c`; `menu.c`, `interfaz.c` y `main.c` no cambian.

### Otros principios
- **DRY:** un único `ejecutar_y_mostrar()` para todas las consultas del menú, un único `ejecutar_menu()` para el menú y los submenús, una única función de tablas en `interfaz.c`, y el reporte reutiliza las consultas del menú.
- **Sin números mágicos:** las constantes son `#define` (`LARGO_CARNE`, `ANCHO_TOTAL`, `MAX_ARGUMENTOS`…) y los topes de créditos son hechos en Prolog.
- **Memoria:** todo lo reservado se libera en `conexion_liberar`.
- **Compilación:** `-Wall -Wextra` sin warnings.

---

## 11. Limitaciones y extensiones posibles

- La disponibilidad no depende del ciclo en curso (D8).
- Los horarios, los correquisitos y los topes son ficticios.
- Las etapas del plan ignoran el tope; los "ciclos estimados" lo aproximan por etapa.
- Solo se probó en Windows 11. El `Makefile` tiene la rama de Linux (`pkg-config swipl`), pero no se ejecutó en Linux.
