# Tarea: Proyecto Programado N.º 2 – Paradigmas de Programación (UNA) — v2.1
SIPA – Sistema Inteligente de Planificación Académica (Alternativa B: Planificación Académica Universitaria).
Front-end en C, back-end en SWI-Prolog. Entrega: lunes 16 de noviembre de 2026. Valor: 100 pts.

## Qué hace el sistema
A partir del historial de un estudiante (cursos aprobados), el sistema razona sobre el plan de estudios
REAL de Ingeniería en Sistemas de Información de la UNA (incluido abajo) y:
- Registra estudiantes y sus cursos aprobados.
- Consulta el plan de estudios (por nivel, ciclo y tipo de curso).
- Identifica requisitos (directos e indirectos) y correquisitos.
- Determina qué asignaturas puede matricular el estudiante.
- Detecta requisitos pendientes de un curso ("¿qué me falta para llevar X?").
- Identifica conflictos de horario.
- Recomienda combinaciones de cursos sin choque y dentro de un tope de créditos.
- Determina rutas académicas de avance (cadena de cursos hasta llegar a un curso meta).
- Calcula avance: créditos aprobados, % de carrera y si alcanza Diplomado (88) o Bachillerato (140).
- Genera reportes de planificación y explica cada conclusión.

Ejemplo: estudiante con EIF200, MAT030, EIF201, MAT002, EIF204, EIF203 aprobados →
disponibles: EIF206, EIF207, EIF205 (si tiene EIF202), MAT005, MAT006...;
EIF211 NO disponible porque falta EIF206 y EIF207 → explicar cuál falta y la ruta para llegar.

## Reglas inquebrantables
- Front-end SOLO en C (consola). Back-end SOLO en SWI-Prolog.
- Prohibido: C++, Java, Python u otro lenguaje para funciones del sistema; clases/POO; librerías externas de IA.
- TODA la lógica del dominio va en Prolog. En C solo se permiten menús, validaciones y control de flujo. C NUNCA decide si un curso está disponible, si hay choque, etc.
- Nada de respuestas precargadas: "disponible", "pendiente", "choque", "ruta", "recomendación" se DEDUCEN con reglas, nunca se guardan como hechos.
- C y Prolog se comunican de verdad: C arma consultas dinámicas y recibe resultados. Usar la interfaz C de SWI-Prolog (SWI-Prolog.h, PL_initialise, PL_predicate, PL_open_query, PL_next_solution, etc.) o comunicación entre procesos (pipes con swipl). Elegir la más robusta y justificarla.
- El profesor va a modificar hechos/reglas en vivo en la defensa (p. ej. agregar un requisito o un curso): todo debe seguir funcionando sin tocar C.

## Arquitectura
Usuario → Front-end C (menú, entradas, validación, resultados) → Integración (conexion.c) → Prolog (hechos, reglas, inferencia, listas, recursividad, backtracking) → conclusiones + recomendaciones + explicaciones.

## Requisitos funcionales (todos obligatorios)
- RF-01 Menú principal en C
- RF-02 Ingreso de datos (registrar estudiante, agregar/quitar cursos aprobados)
- RF-03 Validación antes de consultar Prolog (formato de código de curso, carné numérico, curso existente, opción de menú válida)
- RF-04 Base de conocimientos (plan de estudios de abajo)
- RF-05 Reglas de inferencia que deducen conclusiones nuevas
- RF-06 Consultas dinámicas lanzadas desde C
- RF-07 Inferencia múltiple (varias soluciones: varios cursos, varias combinaciones, varias rutas)
- RF-08 Backtracking (combinaciones sin choque, rutas, cursos disponibles)
- RF-09 Recursividad (mínimo 2): requisito indirecto (cadena completa de prerrequisitos) y ruta de avance hasta un curso meta; opcional: suma recursiva de créditos
- RF-10 Listas en Prolog (cursos aprobados, combinaciones, filtrado, suma de créditos)
- RF-11 Explicación: "por qué está disponible / no disponible / por qué se recomienda"
- RF-12 Recomendaciones (qué matricular el próximo ciclo, priorizando cursos que desbloquean más cursos y los de niveles inferiores atrasados)
- RF-13 Errores: entradas inválidas, estudiante inexistente, sin resultados
- RF-14 Persistencia: estudiantes y aprobados se guardan y recuperan entre ejecuciones (datos/registros.txt o hechos dinámicos con assert/retract + guardado a archivo)
- RF-15 Reporte textual de planificación por estudiante (archivo .txt)

## Mínimos del motor lógico (reales, sin reglas duplicadas artificialmente)
- 40 hechos (el plan de abajo ya da más de 100) · 20 reglas · 15 predicados propios · 10 consultas distintas
- 2 reglas recursivas con condición de terminación clara
- 3 operaciones con listas (findall/setof, member, subtract, sum_list, recorridos recursivos propios)
- 3 escenarios de backtracking demostrables
- 5 reglas de inferencia compuestas
- 5 explicaciones de conclusiones
- 15 casos de prueba

## Predicados sugeridos (adaptables)
- disponible(Est, Curso): no aprobado, todos sus requisitos aprobados, correquisitos aprobados o matriculados juntos.
- requisito_pendiente(Est, Curso, Faltante)
- requiere_indirecto(Curso, Req) — RECURSIVO
- ruta_hacia(Est, CursoMeta, Ruta) — RECURSIVO, lista ordenada de cursos que faltan
- choque(C1, C2): mismos día y horas solapadas (usar horarios ficticios)
- combinacion_valida(Est, MaxCreditos, Lista) — backtracking, sin choques, respeta tope de créditos
- cursos_que_desbloquea(Curso, Lista)
- creditos_aprobados(Est, Total), porcentaje_avance(Est, P), cumple_diplomado(Est), cumple_bachillerato(Est)
- optativas_ok(Est): 4 optativas con al menos 2 disciplinarias
- explicar_disponible(Est, Curso, Explicacion), explicar_no_disponible(Est, Curso, Explicacion)

## BASE DE CONOCIMIENTOS — Plan de estudios oficial (fuente: Escuela de Informática UNA, P.UNA-2498-21)
Ingeniería en Sistemas de Información, bachillerato con salida lateral de Diplomado en Programación de Aplicaciones Informáticas.
Usar EXACTAMENTE estos datos en backend/hechos.pl. Códigos en minúscula como átomos.

```prolog
% curso(Codigo, Nombre, Creditos, Nivel, Ciclo, Tipo).
% Tipo: obligatorio | general | optativo_disciplinario | optativo_libre
% Nivel/Ciclo = 0 para optativos (no tienen ubicación fija).

% ---------- I NIVEL ----------
% I Ciclo (17 créditos)
curso(eif200, 'Fundamentos de Informática',            3, 1, 1, obligatorio).
curso(mat030, 'Matemática para Informática',           4, 1, 1, obligatorio).
curso(eg1,    'Estudios Generales I',                  3, 1, 1, general).
curso(eg2,    'Estudios Generales II',                 3, 1, 1, general).
curso(lix410, 'Inglés Integrado I',                    4, 1, 1, obligatorio).
% II Ciclo (18 créditos)
curso(eif201, 'Programación I',                        4, 1, 2, obligatorio).
curso(mat002, 'Cálculo I',                             4, 1, 2, obligatorio).
curso(eg3,    'Estudios Generales III',                3, 1, 2, general).
curso(eg4,    'Estudios Generales IV',                 3, 1, 2, general).
curso(lix411, 'Inglés Integrado II',                   4, 1, 2, obligatorio).

% ---------- II NIVEL ----------
% I Ciclo (18 créditos)
curso(eif202, 'Soporte Técnico',                       3, 2, 1, obligatorio).
curso(eif203, 'Estructuras Discretas para Informática',3, 2, 1, obligatorio).
curso(eif204, 'Programación II',                       4, 2, 1, obligatorio).
curso(mat005, 'Álgebra Lineal',                        4, 2, 1, obligatorio).
curso(lix412, 'Inglés Integrado III',                  4, 2, 1, obligatorio).
% II Ciclo (17 créditos)
curso(eif205, 'Arquitectura de Computadoras',          3, 2, 2, obligatorio).
curso(eif206, 'Programación III',                      4, 2, 2, obligatorio).
curso(eif207, 'Estructuras de Datos',                  4, 2, 2, obligatorio).
curso(eif404, 'La Organización y su Entorno',          3, 2, 2, obligatorio).
curso(mat006, 'Probabilidad y Estadística para Informática', 3, 2, 2, obligatorio).

% ---------- III NIVEL ----------
% I Ciclo (18 créditos)  -> al completar hasta aquí: DIPLOMADO (88 créditos)
curso(eif208, 'Comunicaciones y Redes de Computadores',3, 3, 1, obligatorio).
curso(eif209, 'Programación IV',                       4, 3, 1, obligatorio).
curso(eif210, 'Ingeniería de Sistemas I',              4, 3, 1, obligatorio).
curso(eif211, 'Diseño e Implementación de Bases de Datos', 4, 3, 1, obligatorio).
curso(eif212, 'Sistemas Operativos',                   3, 3, 1, obligatorio).
% II Ciclo (18 créditos)
curso(eif400, 'Paradigmas de Programación',            4, 3, 2, obligatorio).
curso(eif401, 'Ingeniería de Sistemas II',             4, 3, 2, obligatorio).
curso(eif402, 'Administración de Bases de Datos',      4, 3, 2, obligatorio).
curso(eif407, 'Liderazgo y Organización',              3, 3, 2, obligatorio).
curso(eif412, 'Investigación de Operaciones y sus Aplicaciones', 3, 3, 2, obligatorio).

% ---------- IV NIVEL ----------
% I Ciclo (17 créditos = 11 + 2 optativas de 3)
curso(eif406, 'Ingeniería de Sistemas III',            4, 4, 1, obligatorio).
curso(eif411, 'Diseño y Programación de Plataformas Móviles', 4, 4, 1, obligatorio).
curso(eif413, 'Métodos de Investigación Científica en Informática', 3, 4, 1, obligatorio).
% II Ciclo (17 créditos = 11 + 2 optativas de 3) -> BACHILLERATO (140 créditos)
curso(eif408, 'Proyectos y su Aplicación en la Organización (PPS)', 5, 4, 2, obligatorio).
curso(eif409, 'Aplicaciones Informáticas Globales',    4, 4, 2, obligatorio).
curso(eif410, 'Informática y Sociedad',                2, 4, 2, obligatorio).

% ---------- OPTATIVOS DISCIPLINARIOS ----------
curso(eif100o, 'Dispositivos para Comunicaciones de Datos', 3, 0, 0, optativo_disciplinario).
curso(eif420o, 'Inteligencia Artificial',              3, 0, 0, optativo_disciplinario).
curso(eif421o, 'Análisis de Algoritmos',               3, 0, 0, optativo_disciplinario).
curso(eif422o, 'Diseño de Interfaces de Usuario',      3, 0, 0, optativo_disciplinario).
curso(eif424o, 'Desarrollo de Aplicaciones Educativas',3, 0, 0, optativo_disciplinario).
curso(eif425o, 'Diseño de Ambientes Multimediales',    3, 0, 0, optativo_disciplinario).
curso(eif426o, 'Diseño de Ambientes de Aprendizaje',   3, 0, 0, optativo_disciplinario).
curso(eif427o, 'Robótica',                             3, 0, 0, optativo_disciplinario).
curso(eif428o, 'Fundamentos de Programación Web',      3, 0, 0, optativo_disciplinario).
curso(eif431o, 'Administración de Servidores Basados en Software Libre', 3, 0, 0, optativo_disciplinario).
curso(eif432o, 'Introducción a la Programación Paralela en Arquitecturas Multinúcleo', 3, 0, 0, optativo_disciplinario).
curso(eif433o, 'Contexto, Desarrollo y Aplicación de Software Libre y de Código Abierto', 3, 0, 0, optativo_disciplinario).
curso(eif434o, 'Minería de Datos I',                   3, 0, 0, optativo_disciplinario).
curso(eif435o, 'Minería de Datos II',                  3, 0, 0, optativo_disciplinario).
curso(eig416o, 'Gestión de Tecnología Educativa',      3, 0, 0, optativo_disciplinario).
curso(eif436o, 'Gráficos por Computadora',             3, 0, 0, optativo_disciplinario).
curso(eif440o, 'Seguridad Informática',                3, 0, 0, optativo_disciplinario).
curso(eif441o, 'Soporte Técnico Avanzado',             3, 0, 0, optativo_disciplinario).
curso(eif442o, 'Entornos de Programación para Videojuegos', 3, 0, 0, optativo_disciplinario).
curso(eif443o, 'Diseño y Programación de Videojuegos en 3D', 3, 0, 0, optativo_disciplinario).
curso(eif423o, 'Introducción a la Programación de Dispositivos Móviles', 3, 0, 0, optativo_disciplinario).
curso(eif439o, 'Uso Estratégico del Comercio Electrónico', 3, 0, 0, optativo_disciplinario).
curso(eif101o, 'Redes Avanzadas I',                    3, 0, 0, optativo_disciplinario).

% ---------- OPTATIVOS LIBRES (sin requisitos) ----------
curso(eif429o, 'Introducción a la Creación de Empresas', 3, 0, 0, optativo_libre).
curso(eif430o, 'Las TICs en el Ámbito Jurídico de Costa Rica', 3, 0, 0, optativo_libre).
curso(eif437o, 'Propiedad Intelectual y su Aplicación Práctica', 3, 0, 0, optativo_libre).
curso(eif438o, 'Gobierno Electrónico y su Regulación en Costa Rica', 3, 0, 0, optativo_libre).
curso(eig417o, 'Liderazgo y Organizaciones',           3, 0, 0, optativo_libre).
curso(eig418o, 'La Organización y su Entorno (optativo)', 3, 0, 0, optativo_libre).
curso(eif444o, 'Introducción a la Innovación Tecnológica', 3, 0, 0, optativo_libre).
curso(eif102o, 'Introducción al Análisis de Datos para Otras Carreras', 3, 0, 0, optativo_libre).

% ---------- REQUISITOS: requisito(Curso, CursoRequerido) ----------
% "Ingreso a carrera" = sin requisitos (eif200, mat030, lix410, eg1-eg4, optativos libres).
requisito(eif201, eif200).  requisito(eif201, mat030).
requisito(mat002, mat030).
requisito(lix411, lix410).
requisito(eif202, eif200).
requisito(eif203, eif200).  requisito(eif203, mat030).
requisito(eif204, eif201).
requisito(mat005, mat002).
requisito(lix412, lix411).
requisito(eif205, eif201).  requisito(eif205, eif202).
requisito(eif206, eif204).  requisito(eif206, mat002).
requisito(eif207, eif203).  requisito(eif207, eif204).
requisito(eif404, eif201).
requisito(mat006, mat002).  requisito(mat006, eif203).
requisito(eif208, eif205).
requisito(eif209, eif206).
requisito(eif210, eif206).
requisito(eif211, eif206).  requisito(eif211, eif207).
requisito(eif212, eif204).  requisito(eif212, eif205).
requisito(eif400, eif206).
requisito(eif401, eif210).
requisito(eif402, eif212).  requisito(eif402, eif211).
requisito(eif407, eif404).
requisito(eif412, eif206).  requisito(eif412, mat005).  requisito(eif412, mat006).
requisito(eif406, eif401).
requisito(eif411, eif209).
requisito(eif413, mat006).
requisito(eif408, eif209).  requisito(eif408, eif401).  requisito(eif408, eif402).
requisito(eif409, eif209).  requisito(eif409, eif401).  requisito(eif409, eif402).
requisito(eif410, eif401).
% Optativos disciplinarios
requisito(eif100o, eif208).
requisito(eif420o, eif207).
requisito(eif421o, eif207). requisito(eif421o, mat002).
requisito(eif422o, eif206).
requisito(eif424o, eif204). requisito(eif424o, eif206).
requisito(eif425o, eif204). requisito(eif425o, eif206).
requisito(eif426o, eif204). requisito(eif426o, eif206).
requisito(eif427o, eif204).
requisito(eif428o, eif206). requisito(eif428o, eif211).
requisito(eif431o, eif212). requisito(eif431o, eif402).
requisito(eif432o, eif207). requisito(eif432o, eif212).
requisito(eif433o, eif212). requisito(eif433o, eif211).
requisito(eif434o, eif402). requisito(eif434o, mat006).
requisito(eif435o, eif434o).
requisito(eig416o, eif425o).
requisito(eif436o, eif207). requisito(eif436o, mat005).
requisito(eif440o, eif208). requisito(eif440o, eif212).
requisito(eif441o, eif202).
requisito(eif442o, eif204). requisito(eif442o, mat002).
requisito(eif443o, eif204). requisito(eif443o, mat002).
requisito(eif423o, eif209).
requisito(eif439o, eif209). requisito(eif439o, eif211).
requisito(eif101o, eif208).

% ---------- REGLAS DE GRADUACIÓN DEL PLAN ----------
creditos_diplomado(88).      % I, II nivel completos + III nivel I ciclo
creditos_bachillerato(140).
optativas_requeridas(4).     % 2 en IV nivel I ciclo + 2 en IV nivel II ciclo
min_optativas_disciplinarias(2).
% Estudios generales: 4 cursos, uno por área.
area_general(eg1, ciencia_y_tecnologia).
area_general(eg2, cientifico_social).
area_general(eg3, filosofia_y_letras).
area_general(eg4, arte).
```

## Datos que el plan oficial NO trae (crearlos como FICTICIOS y marcarlos así en comentarios)
- Correquisitos: el plan no tiene. Definir 3–4 ficticios razonables, p. ej.:
  correquisito(eif201, mat002). correquisito(eif209, eif210). correquisito(eif401, eif402).
  (Un correquisito se cumple si ya está aprobado o si se matricula en la misma combinación.)
- Horarios: crear horario(Curso, Grupo, Dia, HoraInicio, HoraFin) ficticio para al menos los cursos
  de III y IV nivel y algunos de II nivel, con 1–2 grupos por curso y algunos choques intencionales
  para poder demostrar la detección de conflictos.
- Estudiantes de prueba (en datos/registros.txt), al menos 4 perfiles:
  1) Primer ingreso (0 aprobados) → solo I nivel I ciclo disponible.
  2) Mitad de II nivel (ej. EIF200, MAT030, LIX410, EIF201, MAT002, LIX411, EIF202, EIF203, EIF204, MAT005).
  3) Diplomado completo (todos los cursos hasta III nivel I ciclo = 88 créditos).
  4) Estudiante atrasado: le faltan cursos de niveles inferiores (ej. sin LIX411 ni EIF202) aunque lleva cursos de III nivel.

## Estructura de carpetas (OBLIGATORIA — arquitectura en 3 capas)
```
SIPA/
├── frontend/                 ← CAPA 1: presentación (solo C)
│   ├── main.c                inicia Prolog (vía conexion.h), carga datos, lanza el menú, cierra todo
│   ├── menu.c / menu.h       muestra opciones y despacha cada caso de uso (tabla de punteros a función)
│   ├── interfaz.c / .h       imprime tablas, títulos, mensajes, pausas (nada de lógica)
│   └── validaciones.c / .h   carné, código de curso, números, opciones de menú
│
├── integracion/              ← CAPA 2: puente C ↔ Prolog
│   └── conexion.c / .h       iniciar/cerrar Prolog, ejecutar consultas, recorrer soluciones,
│                             convertir listas/términos Prolog → estructuras C, manejar errores
│
├── backend/                  ← CAPA 3: razonamiento (solo Prolog)
│   ├── main.pl               carga todos los módulos en orden
│   ├── hechos.pl             plan de estudios oficial (cursos, requisitos, reglas de graduación)
│   ├── datos_ficticios.pl    horarios y correquisitos inventados (marcados como ficticios)
│   ├── estudiantes.pl        hechos dinámicos (estudiante/2, aprobado/2) + guardar/cargar
│   ├── reglas.pl             reglas base: aprobado, cumple_requisitos, choque, créditos
│   ├── inferencia.pl         recursivas y compuestas: rutas, combinaciones, recomendaciones, avance
│   ├── explicaciones.pl      arma el "por qué" de cada conclusión
│   └── consultas.pl          ÚNICA "API" que llama C: un predicado consulta_* por opción del menú
│
├── datos/
│   ├── registros.txt         estudiantes y cursos aprobados guardados
│   └── reportes/             reportes .txt generados
│
├── pruebas/
│   ├── pruebas_prolog.pl     pruebas automáticas con plunit
│   └── casos_prueba.txt      15+ casos documentados (entrada, esperado, obtenido, evidencia)
│
├── documentacion/            manual_tecnico.md, manual_usuario.md, guia_defensa.md (exportables a PDF)
├── Makefile                  compila con swipl-ld (o gcc + flags de `swipl --dump-runtime-variables`)
└── README.md
```

### Reglas de la estructura
- C NUNCA conoce el dominio: solo pide ("dame los disponibles del estudiante X") y muestra.
- consultas.pl es la ÚNICA puerta de entrada desde C. C solo llama predicados consulta_*/N. Si cambia algo dentro de Prolog, C no se entera.
- Dependencias en Prolog en una sola dirección: hechos → reglas → inferencia → explicaciones → consultas. Ningún archivo usa algo de una capa superior.
- Usar módulos de SWI-Prolog (`:- module(...)` con lista de exportación) para que cada archivo exponga solo lo necesario.
- Datos ficticios SEPARADOS de los oficiales (datos_ficticios.pl vs hechos.pl).

### Integración elegida: Prolog incrustado en C
- Usar la API de C de SWI-Prolog (PL_initialise, PL_predicate, PL_open_query, PL_next_solution, PL_close_query, PL_cleanup) y compilar con swipl-ld.
- Recorrer las soluciones una a una desde C con PL_next_solution (demuestra backtracking) y detectar fallos/excepciones (PL_exception) para RF-13.
- Plan B solo si la compilación falla en Windows: popen() a `swipl` con un protocolo de texto simple. Documentar la decisión.

### Flujo de una consulta (documentarlo y usarlo en la defensa)
Usuario elige "4. Cursos disponibles" → menu.c pide el carné → validaciones.c lo valida → conexion.c llama consulta_disponibles(Carne, Lista) → Prolog infiere con reglas.pl e inferencia.pl → devuelve lista + explicación → interfaz.c lo muestra en tabla.

## Principios SOLID (OBLIGATORIOS, adaptados a C estructurado y Prolog — sin clases ni POO)
El enunciado prohíbe clases, así que SOLID se aplica a nivel de módulos, archivos, funciones y predicados:
- S — Responsabilidad única: cada archivo .c/.pl y cada función/predicado hace UNA cosa. interfaz.c solo imprime, validaciones.c solo valida, conexion.c solo habla con Prolog, explicaciones.pl solo explica. Funciones cortas (idealmente < 40 líneas).
- O — Abierto/Cerrado: el sistema se extiende agregando hechos/reglas en Prolog SIN modificar C. En C, el menú usa una tabla de opciones {número, texto, puntero a función}: agregar una opción = agregar una fila, no tocar un switch gigante.
- L — Sustitución de Liskov (adaptado): todos los predicados consulta_* siguen el mismo contrato (entradas ligadas, salida en lista, fallan limpio o devuelven error(Motivo)), y todos los handlers del menú tienen la misma firma `void (*)(void)`, de modo que son intercambiables.
- I — Segregación de interfaces: headers pequeños y específicos. menu.h no expone nada de validaciones; conexion.h expone solo las funciones que el frontend necesita (no los tipos internos de SWI-Prolog). Los módulos Prolog exportan solo lo necesario.
- D — Inversión de dependencias: el frontend depende de la abstracción conexion.h (p. ej. `int sipa_consultar_lista(const char *pred, const char *arg, ResultadoLista *out)`), nunca de SWI-Prolog.h directamente. Así se podría cambiar de API incrustada a pipes sin tocar menu.c ni interfaz.c.
- Además: DRY (nada de código duplicado), nombres descriptivos en español, constantes en lugar de números mágicos, manejo de memoria correcto (liberar todo lo reservado), compilar con `-Wall -Wextra` sin warnings.
- En manual_tecnico.md incluir una sección "Aplicación de SOLID" con un ejemplo concreto del código por cada principio.

## Menú sugerido (C)
1. Registrar estudiante
2. Registrar / quitar cursos aprobados
3. Consultar plan de estudios (por nivel o tipo)
4. Ver cursos disponibles para matricular (con explicación)
5. ¿Qué me falta para llevar X? (requisitos pendientes + cadena completa)
6. Ruta de avance hacia un curso meta
7. Detectar choques de horario de una selección
8. Recomendar combinaciones (tope de créditos ingresado por el usuario)
9. Avance de carrera (créditos, %, diplomado/bachillerato, optativas)
10. Generar reporte de planificación
11. Guardar / cargar sesión
0. Salir

## Entregables
1. Código fuente que compile y corra (Makefile + instrucciones). Probado en Linux y, si se puede, en Windows.
2. Manual técnico: problema, arquitectura, base de conocimientos, reglas, integración C–Prolog, decisiones de diseño.
3. Manual de usuario: instalación (SWI-Prolog + gcc), compilación, ejecución, uso y ejemplos.
4. Pruebas: mínimo 15 casos con entrada, resultado esperado, resultado obtenido y evidencia (plunit + integración desde C).
5. guia_defensa.md (ver abajo).

## Rúbrica (para priorizar)
- Reglas de inferencia 15 · Integración C–Prolog 15
- Arquitectura 10 · Front-end C 10 · Base de conocimientos 10 · Recursividad 10 · Listas y backtracking 10
- Explicabilidad 5 · Pruebas 5 · Documentación 5 · Defensa 5

## guia_defensa.md (con ejemplos del propio código)
- Una regla lógica y la diferencia entre hechos (curso/requisito) y reglas (disponible/2)
- Variables y unificación (p. ej. consulta disponible(Est, X))
- Una regla recursiva (requiere_indirecto/2) y su condición de terminación
- Cómo el backtracking genera varias soluciones (combinaciones sin choque, con traza)
- Cómo se comunican C y Prolog (flujo completo de una consulta)
- Justificación paso a paso de una conclusión ("EIF402 no disponible porque falta EIF211, que a su vez requiere EIF207")
- Demo de cambio en vivo: agregar un requisito nuevo en hechos.pl y mostrar que la respuesta cambia sin recompilar C

## Cómo trabajar
1. Primero proponé el diseño: lista de predicados por archivo, contrato de conexion.h, tabla del menú y cómo se aplica cada principio SOLID. Esperá mi aprobación.
2. Implementá en orden: hechos.pl (copiar el plan tal cual) → datos_ficticios.pl → reglas/inferencia/explicaciones probadas en swipl → consultas.pl → conexion.c → front-end C → persistencia y reportes → pruebas → documentación.
3. Al terminar verificá: compila con -Wall -Wextra sin warnings, pasan los 15 casos, respeta la estructura de carpetas exacta, y entregá una tabla de conteo que confirme cada mínimo del motor lógico con nombres de predicados + una tabla SOLID (principio → archivo/función que lo demuestra).
4. Código comentado en español, nombres claros, cero lógica del dominio en C.
