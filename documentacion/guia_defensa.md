# Guía de defensa — Consejero Académico Inteligente

**Universidad Nacional de Costa Rica** · Paradigmas de Programación · Ciclo II 2026
**Profesor:** Juan de Dios Murillo
**Estudiantes:** Lausen Paniagua Arias · Génesis Silesky Araya

Todos los ejemplos son del código real del proyecto y las salidas se obtuvieron ejecutándolo.

---

## 1. Hechos y reglas

Un **hecho** es una afirmación que se da por cierta, sin condiciones. Está en `backend/hechos.pl`:

```prolog
curso(eif206, 'Programación III', 4, 2, 2, obligatorio).
requisito(eif206, eif204).
requisito(eif206, mat002).
```

Una **regla** deduce algo nuevo a partir de otros hechos o reglas: la cabeza es cierta **si** el cuerpo es cierto. Está en `backend/reglas.pl`:

```prolog
cumple_requisitos(Est, C) :-
    forall(requisito(C, R), aprobado(Est, R)).

puede_cursarse(Est, C) :-
    existe_curso(C),
    \+ aprobado(Est, C),
    cumple_requisitos(Est, C).

disponible(Est, C) :-
    puede_cursarse(Est, C),
    forall(correquisito(C, K), correquisito_cubierto(Est, K)).
```

**Diferencia clave:** "EIF206 requiere EIF204" está escrito (hecho). "EIF206 está disponible para José" **no está escrito en ningún lado**: Prolog lo deduce cada vez con la regla `disponible/2`. Si cambian los aprobados o los requisitos, la conclusión cambia sola.

---

## 2. Variables y unificación

```prolog
?- disponible(111110004, X).
X = eg1 ;
X = eg2 ;
X = lix410 ;
X = eg3 ;
X = eg4 ;
X = eif202 ;
...
```

- `111110004` es una constante, así que la consulta queda fija a José.
- `X` es una **variable libre**. Para responder, Prolog **unifica** `X` con cada curso que hace verdadera la regla: primero `X = eg1`, después deshace esa ligadura y prueba `X = eg2`, y así sucesivamente.
- Dentro de la regla, `Est` se unifica con `111110004` y `C` con `X`.

La unificación también explica el contrato con C. Cuando C llama `consulta_disponibles("111110004", Fila)`, `Fila` es una variable que Prolog unifica con una lista distinta en cada solución:

```prolog
Fila = ["EIF206", "Programacion III", "4", "Tiene aprobados todos sus requisitos: EIF204, MAT002."]
```

---

## 3. Regla recursiva y su condición de terminación

Está en `backend/inferencia.pl`:

```prolog
requiere_indirecto(C, R) :-          % CASO BASE: requisito directo
    requisito(C, R).
requiere_indirecto(C, R) :-          % CASO RECURSIVO: requisito de un requisito
    requisito(C, X),
    requiere_indirecto(X, R).
```

**Ejemplo:** `requiere_indirecto(eif402, eif207)` es verdadero, aunque EIF207 **no** es requisito directo de EIF402:

```
requiere_indirecto(eif402, eif207)
 ├─ caso base: requisito(eif402, eif207)?                   no
 └─ caso recursivo: requisito(eif402, X) → X = eif212
      requiere_indirecto(eif212, eif207) → ... no
    backtracking → X = eif211
      requiere_indirecto(eif211, eif207)
       └─ caso base: requisito(eif211, eif207)?              SÍ
```

**¿Por qué termina?** Cada llamada recursiva baja un nivel en el grafo de requisitos (de un curso a uno de sus requisitos). El grafo es **acíclico** (ningún curso es requisito de sí mismo) y **finito** (67 cursos). Tarde o temprano se llega a cursos sin requisitos, como EIF200 o MAT030, donde ninguna cláusula aplica y la rama falla. Por eso no hay ciclo infinito.

El proyecto tiene 8 reglas recursivas. La tabla está en `manual_tecnico.md` §4.2. Otras dos buenas para mostrar son `ruta_hacia/3` (varias soluciones) y `describir_pendiente/3`, que arma el texto "que a su vez requiere…".

---

## 4. Cómo el backtracking genera varias soluciones

### 4.1 Grupos sin choque (`asignar_grupos/2`) con traza real

```prolog
asignar_grupos([], []).
asignar_grupos([C|Cs], [C-G|Resto]) :-
    asignar_grupos(Cs, Resto),
    grupo_de(C, G),                 % punto de elección: G1, G2, ...
    \+ choca_con(C, G, Resto).
```

EIF209 y EIF210 son correquisitos y **chocan en el grupo 1** (martes de 18:00 a 21:00). Traza real de `asignar_grupos([eif209, eif210], A)`:

```
probar eif210-1 con []:          ok
probar eif209-1 con [eif210-1]:  CHOCA -> backtracking
probar eif210-2 con []:          ok        ← Prolog volvió a cambiar el grupo de EIF210
probar eif209-1 con [eif210-2]:  ok
solucion: [eif209-1, eif210-2]
```

Cuando EIF209 G1 choca, Prolog **retrocede** al último punto de elección (el grupo de EIF210), prueba G2 y sigue. Para EIF402 y EIF412, que tienen un solo grupo cada uno, se agotan todas las opciones y la consulta **falla**: es un choque inevitable.

### 4.2 Combinaciones dentro del tope (`combinacion_valida/3`)

```prolog
elegir([], _, Elegidos, Elegidos).
elegir([C|Cs], Restante, Acumulado, Elegidos) :-       % rama 1: INCLUIR C
    creditos_de(C, Cr), Cr =< Restante,
    grupo_de(C, G), \+ choca_con(C, G, Acumulado),
    NuevoRestante is Restante - Cr,
    elegir(Cs, NuevoRestante, [C-G|Acumulado], Elegidos).
elegir([_|Cs], Restante, Acumulado, Elegidos) :-       % rama 2: EXCLUIR C
    elegir(Cs, Restante, Acumulado, Elegidos).
```

Por cada curso candidato hay dos ramas, incluirlo o excluirlo, y por cada grupo hay otra elección. Cuando se pasa del tope o hay un choque, Prolog retrocede y prueba la siguiente rama. Cada solución es una combinación distinta. Como la rama "incluir" va primero y los candidatos vienen ordenados por prioridad, **la primera solución es la recomendada**.

### 4.3 Rutas alternativas (`ruta_hacia/3`)

```prolog
?- ruta_hacia(208490835, eif402, R).
R = [eif205, eif212, eif402] ;
R = [eif206, eif211, eif402] ;
R = [eif207, eif211, eif402].
```

### 4.4 El backtracking visto desde C

```c
while (PL_next_solution(consulta)) {        /* cada vuelta = una solución */
    agregar_fila(resultado, argumentos + n, &capacidad);
}
```

Cada `PL_next_solution` le pide a Prolog **la siguiente solución** (backtracking). Así C recibe una fila por curso, por ruta o por combinación.

---

## 5. Comunicación C ↔ Prolog: flujo completo de una consulta

Ejemplo: el usuario elige **"5. Qué me falta para llevar un curso"**.

```
1. menu.c        opcion_que_falta()
2. menu.c        pedir_carne_registrado() → lee "208490835"
3. validaciones  validar_carne("208490835")             → formato OK (9 dígitos)
4. conexion.c    conexion_consultar("consulta_existe_estudiante", {"208490835"})
                 → Prolog confirma que existe → "Estudiante: Lausen Paniagua Arias"
5. menu.c        pedir_curso() → "eif402"; validar_codigo_curso(); consulta_existe_curso
6. conexion.c    conexion_consultar("consulta_que_falta", {"208490835","eif402"}, 2, &r)
                   PL_predicate("consulta_que_falta", 3, "consultas")
                   PL_unify_chars(...) para cada argumento
                   PL_open_query(NULL, PL_Q_CATCH_EXCEPTION, pred, args)
                   while (PL_next_solution) → convierte la lista Fila en FilaResultado
                   PL_exception → si hubo error_sipa(Mensaje), lo guarda
                   PL_close_query
7. Prolog        consultas:consulta_que_falta → reglas:disponible (falla)
                 → explicaciones:explicar_no_disponible → inferencia:cursos_necesarios
                 → inferencia:plan_por_etapas → una fila por dato
8. interfaz.c    interfaz_mostrar_resultado → tabla
9. menu.c        conexion_liberar(&r)
```

**Puntos para remarcar:**
- C **nunca** decide si un curso está disponible: solo valida el formato y muestra lo que Prolog responde.
- `menu.c` no incluye `SWI-Prolog.h`, solo `conexion.h` (inversión de dependencias).
- `conexion.c` solo acepta predicados `consulta_*`, que son la única puerta de entrada.

---

## 6. Justificación paso a paso de una conclusión

**Conclusión:** "EIF402 no está disponible para Lausen (208490835)".

Salida real del sistema (opción 5):

```
Por que | No esta disponible porque falta EIF212, que a su vez requiere EIF205;
        | EIF211, que a su vez requiere EIF206 y EIF207.
```

Cómo la deduce Prolog:

1. `disponible(208490835, eif402)` necesita `cumple_requisitos`, y los requisitos de EIF402 son `requisito(eif402, eif212)` y `requisito(eif402, eif211)`.
2. `aprobado(208490835, eif212)` es falso, así que **falta EIF212**.
3. `aprobado(208490835, eif211)` es falso, así que **falta EIF211**.
4. `describir_pendiente/3`, que es recursivo, baja por cada faltante:
   - EIF212 requiere EIF204 (aprobado) y EIF205 (no aprobado): "EIF212, que a su vez requiere EIF205".
   - EIF205 requiere EIF201 y EIF202, ambos aprobados. Es el caso base y la recursión se detiene.
   - EIF211 requiere EIF206 y EIF207, ninguno aprobado: "EIF211, que a su vez requiere EIF206 y EIF207".
   - EIF206 y EIF207 tienen sus requisitos aprobados. Es el caso base.

---

## 7. Demo: cambio en vivo sin recompilar C

Este ensayo ya se probó (caso CP-28 de `pruebas/casos_prueba.txt`).

1. Ejecute `mingw32-make run`.
2. Abra la **opción 5**, carné `111110004` (José), curso `EIF206`:
   ```
   Estado  | DISPONIBLE
   Por que | Tiene aprobados todos sus requisitos: EIF204, MAT002.
   ```
3. **Sin cerrar el programa**, abra `backend/hechos.pl` en un editor y agregue al final:
   ```prolog
   requisito(eif206, eif202).
   ```
   Guarde el archivo.
4. En el programa, elija la **opción 12** (Recargar base de conocimientos):
   ```
   Base de conocimientos recargada: 67 cursos y 82 requisitos.
   ```
5. Repita la **opción 5** con el mismo carné y curso:
   ```
   Estado  | NO DISPONIBLE
   Por que | No esta disponible porque falta EIF202.
   ```
6. **Explicación:** C no se recompiló ni se reinició. La opción 12 ejecuta `make/0` en Prolog, que recarga `hechos.pl`, y como `disponible/2` es una regla, la nueva conclusión se deduce sola.
7. Al terminar, borre la línea agregada y use la opción 12 otra vez.

**Variantes que también funcionan:**
- Agregar un curso nuevo: `curso(eif999, 'Curso Nuevo', 3, 3, 1, obligatorio).`
- Agregar un correquisito en `datos_ficticios.pl`.

`hechos.pl` declara `:- discontiguous curso/6, requisito/2.`, así que se pueden agregar hechos en cualquier lugar del archivo sin advertencias.

---

## 8. Otras preguntas probables

| Pregunta | Respuesta corta |
|---|---|
| ¿Por qué Prolog incrustado y no pipes? | Hay una sola sesión con los hechos dinámicos, el backtracking se ve con `PL_next_solution` y los errores llegan estructurados con `PL_exception`. Ver `manual_tecnico.md` §5.1. |
| ¿Por qué no `swipl-ld`? | En Windows falla por el espacio de `C:\Program Files`. Se usa gcc con las rutas de `swipl --dump-runtime-variables`, que el enunciado permite. |
| ¿Dónde está la lógica en C? | En ningún lado. C valida formatos y muestra; todo lo demás se deduce en Prolog. |
| ¿Qué es lo ficticio? | Los correquisitos, los horarios y los topes, que están en `datos_ficticios.pl`, separados del plan oficial. |
| ¿Cómo se prioriza la recomendación? | Atrasados → cursos del plan antes que optativos → los que desbloquean más → nivel/ciclo (`cursos_priorizados/2`). |
| ¿Cómo funciona el plan anual? | Recomienda el ciclo 1, **simula** que lo aprueba con un carné temporal `sim(Est)` que siempre se borra, y recomienda el ciclo 2. El total no pasa de 36. |
| ¿Cómo se demuestra SOLID? | `manual_tecnico.md` §10 tiene un ejemplo del código por principio. |
| ¿Cuántas pruebas hay? | 63 plunit, 17 de integración en C y 31 casos documentados. |
| ¿Qué pasa si se agrega un requisito que forma un ciclo? | Al recargar (opción 12) el sistema lo detecta con `curso_en_ciclo/1`, que usa una lista de visitados y siempre termina, y muestra una ADVERTENCIA con los cursos del ciclo. Las reglas recursivas suponen un grafo acíclico, así que hay que corregir `hechos.pl` y recargar. |
