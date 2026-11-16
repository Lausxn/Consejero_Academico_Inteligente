% inferencia.pl - Reglas recursivas y compuestas
%
% Responsabilidad: conclusiones que combinan varias reglas base:
% requisitos indirectos, rutas de avance, combinaciones sin choque
% (backtracking), recomendaciones priorizadas y avance de carrera.
% Depende de: reglas (y la capa de datos).

:- module(inferencia, [
    % --- recursivas sobre el grafo de requisitos
    requiere_indirecto/2,
    curso_en_ciclo/1,
    cadena_requisitos/2,
    pendientes_totales/3,
    ruta_hacia/3,
    cursos_necesarios/3,
    plan_por_etapas/3,
    plan_hacia_bachillerato/2,
    ciclos_estimados/3,
    % --- desbloqueo y prioridad
    cursos_que_desbloquea/2,
    cantidad_desbloquea/2,
    cursos_disponibles/2,
    nivel_actual/2,
    atrasado/2,
    cursos_priorizados/2,
    % --- combinaciones (backtracking)
    candidatos_combinacion/2,
    combinacion_valida/3,
    combinacion_maximal/3,
    recomendar/4,
    recomendar_anual/4,
    asignar_grupos/2,
    choques_en_seleccion/2,
    creditos_combinacion/2,
    % --- avance de carrera
    porcentaje_avance/2,
    curso_de_diplomado/1,
    curso_de_bachillerato/1,
    faltantes_diplomado/2,
    faltantes_bachillerato/2,
    cumple_diplomado/1,
    cumple_bachillerato/1,
    optativas_aprobadas/2,
    optativas_ok/1
]).

:- use_module(hechos).
:- use_module(datos_ficticios).
:- use_module(estudiantes).
:- use_module(reglas).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(solution_sequences)).

% =====================================================================
% 1. Recursividad sobre el grafo de requisitos
% =====================================================================

%!  requiere_indirecto(?Curso, ?Requisito)
%   RECURSIVA. Requisito es necesario para Curso, directa o
%   indirectamente.
%   - Caso base: es requisito directo.
%   - Caso recursivo: es requisito (indirecto) de un requisito directo.
%   Terminacion: el grafo de requisitos es aciclico y finito, asi que
%   cada llamada baja un nivel hasta llegar a cursos sin requisitos.
requiere_indirecto(C, R) :-
    requisito(C, R).
requiere_indirecto(C, R) :-
    requisito(C, X),
    requiere_indirecto(X, R).

%!  curso_en_ciclo(?Curso)
%   Verificacion de integridad: Curso termina requiriendose a si mismo
%   (el plan dejaria de ser aciclico, por ejemplo por un requisito mal
%   agregado en vivo). Usa una lista de visitados, asi que siempre termina.
curso_en_ciclo(C) :-
    existe_curso(C),
    once(alcanza(C, C, [C])).

%   alcanza(+Desde, +Objetivo, +Visitados)
%   - Caso base: Objetivo es requisito directo de Desde.
%   - Caso recursivo: seguir por un requisito no visitado.
%   Terminacion: Visitados crece en cada paso y el plan es finito.
alcanza(Desde, Objetivo, _) :-
    requisito(Desde, Objetivo).
alcanza(Desde, Objetivo, Visitados) :-
    requisito(Desde, X),
    \+ memberchk(X, Visitados),
    alcanza(X, Objetivo, [X|Visitados]).

%!  cadena_requisitos(+Curso, -Lista)
%   Todos los requisitos (directos e indirectos), sin repetir.
cadena_requisitos(C, Lista) :-
    (   setof(R, requiere_indirecto(C, R), Lista)
    ->  true
    ;   Lista = []
    ).

%!  pendientes_totales(+Est, +Curso, -Lista)
%   Requisitos directos e indirectos de Curso que Est no ha aprobado.
pendientes_totales(Est, C, Pendientes) :-
    cadena_requisitos(C, Todos),
    cursos_aprobados(Est, Aprobados),
    subtract(Todos, Aprobados, Pendientes).

%!  ruta_hacia(+Est, +Meta, -Ruta)
%   RECURSIVA, VARIAS SOLUCIONES. Ruta = [C1, C2, ..., Meta] es una
%   cadena de cursos no aprobados en la que cada curso es requisito
%   directo del siguiente y C1 ya puede cursarse.
%   El backtracking sobre requisito/2 genera todas las cadenas posibles.
ruta_hacia(Est, Meta, Ruta) :-
    existe_curso(Meta),
    \+ aprobado(Est, Meta),
    ruta_atras(Est, Meta, [Meta], Ruta).

%   - Caso base: el curso actual ya puede cursarse -> la ruta empieza aqui.
%   - Caso recursivo: retroceder a un requisito directo no aprobado.
%   Terminacion: cada paso baja a un requisito (grafo aciclico y finito).
ruta_atras(Est, C, Ruta, Ruta) :-
    puede_cursarse(Est, C).
ruta_atras(Est, C, Acumulado, Ruta) :-
    requisito_faltante(Est, C, R),
    ruta_atras(Est, R, [R|Acumulado], Ruta).

%!  cursos_necesarios(+Est, +Meta, -Lista)
%   RECURSIVA. Cierre de Meta bajo requisitos y correquisitos: todo lo
%   que falta aprobar para poder llevar (y aprobar) Meta.
cursos_necesarios(Est, Meta, Lista) :-
    cierre(Est, [Meta], [], Encontrados),
    sort(Encontrados, Lista).

%   cierre(+Est, +PorVisitar, +Vistos, -Resultado)
%   - Caso base: no queda nada por visitar.
%   - Caso recursivo: si el curso es nuevo y no aprobado, se agrega y se
%     encolan sus requisitos y correquisitos.
%   Terminacion: Vistos crece en cada paso y el plan es finito; un curso
%   ya visto o aprobado no se vuelve a expandir.
cierre(_, [], Vistos, Vistos).
cierre(Est, [C|Cola], Vistos, Resultado) :-
    (   ( memberchk(C, Vistos) ; aprobado(Est, C) )
    ->  cierre(Est, Cola, Vistos, Resultado)
    ;   findall(X, ( requisito(C, X) ; correquisito(C, X) ), Nuevos),
        append(Nuevos, Cola, NuevaCola),
        cierre(Est, NuevaCola, [C|Vistos], Resultado)
    ).

%!  plan_por_etapas(+Est, +Meta, -Etapas)
%   RECURSIVA. Etapas = [E1, E2, ...]: E1 son los cursos necesarios que
%   ya se pueden llevar, E2 los que se desbloquean al aprobar E1, etc.
%   La cantidad de etapas es el MINIMO de ciclos para llegar a la meta
%   (una etapa puede requerir mas de un ciclo si supera el tope).
plan_por_etapas(Est, Meta, Etapas) :-
    cursos_necesarios(Est, Meta, Necesarios),
    cursos_aprobados(Est, Aprobados),
    etapas(Necesarios, Aprobados, Etapas).

%!  plan_hacia_bachillerato(+Est, -Etapas)
%   Igual que plan_por_etapas/3, pero la "meta" son todos los cursos
%   fijos del Bachillerato que faltan (las optativas se informan aparte).
plan_hacia_bachillerato(Est, Etapas) :-
    faltantes_bachillerato(Est, Faltantes),
    cierre(Est, Faltantes, [], Encontrados),
    sort(Encontrados, Necesarios),
    cursos_aprobados(Est, Aprobados),
    etapas(Necesarios, Aprobados, Etapas).

%   - Caso base: no quedan pendientes.
%   - Caso recursivo: la etapa son los pendientes listos; se "aprueban"
%     en simulacion y se sigue con el resto.
%   Terminacion: cada etapa tiene al menos un curso (Etapa \== []), asi
%   que la lista de pendientes se reduce en cada llamada.
etapas([], _, []) :- !.
etapas(Pendientes, Aprobados, [Etapa|Resto]) :-
    include(listo_en_etapa(Aprobados, Pendientes), Pendientes, Etapa),
    Etapa \== [],
    subtract(Pendientes, Etapa, Restantes),
    append(Aprobados, Etapa, NuevosAprobados),
    etapas(Restantes, NuevosAprobados, Resto).

%!  ciclos_estimados(+Etapas, +Tope, -Ciclos)
%   RECURSIVA sobre la lista de etapas. Cada etapa necesita
%   ceil(creditos / Tope) ciclos para no superar el tope por ciclo.
%   - Caso base: sin etapas, 0 ciclos.
%   - Caso recursivo: ciclos de la primera etapa + los del resto.
ciclos_estimados([], _, 0).
ciclos_estimados([Etapa|Resto], Tope, Ciclos) :-
    suma_creditos(Etapa, Cr),
    CiclosEtapa is max(1, ceiling(Cr / Tope)),
    ciclos_estimados(Resto, Tope, CiclosResto),
    Ciclos is CiclosEtapa + CiclosResto.

% Un curso esta listo si tiene sus requisitos aprobados y sus
% correquisitos pendientes tambien estan listos (van juntos).
listo_en_etapa(Aprobados, Pendientes, C) :-
    requisitos_en(Aprobados, C),
    forall(( correquisito(C, K), memberchk(K, Pendientes) ),
           requisitos_en(Aprobados, K)).

requisitos_en(Aprobados, C) :-
    forall(requisito(C, R), memberchk(R, Aprobados)).

% =====================================================================
% 2. Desbloqueo y prioridad
% =====================================================================

%!  cursos_que_desbloquea(+Curso, -Lista)
%   Cursos que tienen a Curso como requisito directo.
cursos_que_desbloquea(C, Lista) :-
    findall(X, requisito(X, C), Lista).

%!  cantidad_desbloquea(+Curso, -N)
%   Cantidad de cursos que dependen de Curso directa o indirectamente.
cantidad_desbloquea(C, N) :-
    (   setof(X, requiere_indirecto(X, C), Dependientes)
    ->  length(Dependientes, N)
    ;   N = 0
    ).

cursos_disponibles(Est, Lista) :-
    findall(C, disponible(Est, C), Lista).

%!  nivel_actual(+Est, -Nivel)
%   Nivel mas alto en el que el estudiante tiene cursos aprobados
%   (1 si no tiene ninguno).
nivel_actual(Est, Nivel) :-
    (   aggregate_all(max(N), ( aprobado(Est, C), nivel_de(C, N), N > 0 ), Max)
    ->  Nivel = Max
    ;   Nivel = 1
    ).

%!  atrasado(+Est, ?Curso)
%   Curso disponible de un nivel inferior al nivel actual del estudiante.
atrasado(Est, C) :-
    disponible(Est, C),
    nivel_de(C, N),
    N > 0,
    nivel_actual(Est, Actual),
    N < Actual.

%!  cursos_priorizados(+Est, -Lista)
%   Disponibles ordenados por prioridad (RF-12):
%     1) atrasados primero,
%     2) cursos del plan (obligatorios y generales) antes que optativos,
%     3) los que desbloquean mas cursos,
%     4) nivel y ciclo mas bajos.
cursos_priorizados(Est, Lista) :-
    findall(Clave-C,
            ( disponible(Est, C), clave_prioridad(Est, C, Clave) ),
            Pares),
    keysort(Pares, Ordenados),
    pairs_values(Ordenados, Lista).

clave_prioridad(Est, C, clave(Atraso, Optativo, MenosDesbloquea, Nivel, Ciclo, C)) :-
    ( atrasado(Est, C) -> Atraso = 0 ; Atraso = 1 ),
    ( es_optativo(C)   -> Optativo = 1 ; Optativo = 0 ),
    cantidad_desbloquea(C, D),
    MenosDesbloquea is -D,
    nivel_de(C, Nivel),
    ciclo_de(C, Ciclo).

% =====================================================================
% 3. Combinaciones de matricula (BACKTRACKING)
% =====================================================================

%!  candidatos_combinacion(+Est, -Lista)
%   Disponibles ofertados (con horario), en orden de prioridad.
candidatos_combinacion(Est, Lista) :-
    cursos_priorizados(Est, Priorizados),
    include(ofertado, Priorizados, Lista).

%!  combinacion_valida(+Est, +Tope, -Combinacion)
%   BACKTRACKING. Combinacion = [Curso-Grupo, ...] no vacia, sin choques
%   de horario, con creditos =< Tope y con los correquisitos pendientes
%   incluidos. Cada solucion es una combinacion distinta.
combinacion_valida(Est, Tope, Combinacion) :-
    candidatos_combinacion(Est, Candidatos),
    elegir(Candidatos, Tope, [], Elegidos),
    Elegidos \== [],
    correquisitos_incluidos(Est, Elegidos),
    reverse(Elegidos, Combinacion).

%   elegir(+Candidatos, +CreditosRestantes, +Acumulado, -Elegidos)
%   Por cada candidato hay dos ramas: incluirlo (con algun grupo que no
%   choque) o excluirlo. Incluir va primero, asi la primera solucion
%   respeta el orden de prioridad.
elegir([], _, Elegidos, Elegidos).
elegir([C|Cs], Restante, Acumulado, Elegidos) :-
    creditos_de(C, Cr),
    Cr =< Restante,
    grupo_de(C, G),
    \+ choca_con(C, G, Acumulado),
    NuevoRestante is Restante - Cr,
    elegir(Cs, NuevoRestante, [C-G|Acumulado], Elegidos).
elegir([_|Cs], Restante, Acumulado, Elegidos) :-
    elegir(Cs, Restante, Acumulado, Elegidos).

choca_con(C, G, Elegidos) :-
    member(C2-G2, Elegidos),
    choque_grupos(C, G, C2, G2), !.

% Cada correquisito no aprobado de un curso elegido tambien fue elegido.
correquisitos_incluidos(Est, Elegidos) :-
    forall(( member(C-_, Elegidos), correquisito_pendiente(Est, C, K) ),
           memberchk(K-_, Elegidos)).

%!  combinacion_maximal(+Est, +Tope, -Combinacion)
%   Combinacion valida a la que no se le puede agregar ningun otro
%   candidato (por creditos, choque o correquisito).
combinacion_maximal(Est, Tope, Combinacion) :-
    combinacion_valida(Est, Tope, Combinacion),
    \+ se_puede_agregar(Est, Tope, Combinacion).

se_puede_agregar(Est, Tope, Combinacion) :-
    candidatos_combinacion(Est, Candidatos),
    member(C, Candidatos),
    \+ memberchk(C-_, Combinacion),
    creditos_combinacion(Combinacion, Usados),
    creditos_de(C, Cr),
    Usados + Cr =< Tope,
    \+ ( correquisito_pendiente(Est, C, K), \+ memberchk(K-_, Combinacion) ),
    grupo_de(C, G),
    \+ choca_con(C, G, Combinacion), !.

creditos_combinacion(Combinacion, Total) :-
    pairs_keys(Combinacion, Cursos),
    suma_creditos(Cursos, Total).

%!  recomendar(+Est, +Tope, +N, -Combinaciones)
%   Hasta N combinaciones maximales con distintos cursos, en orden de
%   prioridad (la primera es la recomendada).
recomendar(Est, Tope, N, Combinaciones) :-
    findall(Comb,
            limit(N, distinct(Cursos,
                ( combinacion_maximal(Est, Tope, Comb),
                  pairs_keys(Comb, Cursos0), msort(Cursos0, Cursos) ))),
            Combinaciones).

%!  recomendar_anual(+Est, +TopeCiclo, +TopeAnual, -[Ciclo1, Ciclo2])
%   Recomienda el ciclo 1 y, simulando que lo aprueba, el ciclo 2.
%   La simulacion usa un carne temporal sim(Est) que se borra al final.
recomendar_anual(Est, TopeCiclo, TopeAnual, [Ciclo1, Ciclo2]) :-
    Tope1 is min(TopeCiclo, TopeAnual),
    recomendar(Est, Tope1, 1, [Ciclo1]),
    creditos_combinacion(Ciclo1, Usados),
    Tope2 is min(TopeCiclo, TopeAnual - Usados),
    pairs_keys(Ciclo1, Cursos1),
    con_simulacion(Est, Cursos1, Sim,
                   segundo_ciclo(Sim, Tope2, Ciclo2)).

segundo_ciclo(Sim, Tope, Ciclo2) :-
    (   Tope > 0, recomendar(Sim, Tope, 1, [C2])
    ->  Ciclo2 = C2
    ;   Ciclo2 = []
    ).

%   con_simulacion(+Est, +Extra, -Sim, :Meta)
%   Ejecuta Meta con un estudiante simulado que tiene los aprobados de
%   Est mas Extra. Siempre limpia los hechos temporales.
:- meta_predicate con_simulacion(+, +, -, 0).
con_simulacion(Est, Extra, Sim, Meta) :-
    Sim = sim(Est),
    setup_call_cleanup(
        crear_simulado(Est, Extra, Sim),
        once(Meta),
        retractall(estudiantes:aprobado(Sim, _))).

crear_simulado(Est, Extra, Sim) :-
    retractall(estudiantes:aprobado(Sim, _)),
    cursos_aprobados(Est, Aprobados),
    append(Aprobados, Extra, Todos),
    forall(member(C, Todos), assertz(estudiantes:aprobado(Sim, C))).

%!  asignar_grupos(+Cursos, -Asignacion)
%   BACKTRACKING. Asigna un grupo a cada curso de la seleccion del
%   usuario de modo que ningun par choque. Falla si es imposible.
asignar_grupos([], []).
asignar_grupos([C|Cs], [C-G|Resto]) :-
    asignar_grupos(Cs, Resto),
    grupo_de(C, G),
    \+ choca_con(C, G, Resto).

%!  choques_en_seleccion(+Cursos, -Pares)
%   Pares C1-C2 (cada par una vez) de la seleccion que tienen algun choque.
choques_en_seleccion(Cursos, Pares) :-
    findall(C1-C2,
            ( append(_, [C1|Resto], Cursos), member(C2, Resto),
              choque(C1, C2) ),
            Pares).

% =====================================================================
% 4. Avance de carrera
% =====================================================================

%!  porcentaje_avance(+Est, -Porcentaje)
%   Creditos aprobados sobre los del bachillerato (1 decimal, tope 100).
porcentaje_avance(Est, P) :-
    creditos_aprobados(Est, Cr),
    creditos_bachillerato(Total),
    P is min(100.0, round(Cr * 1000 / Total) / 10).

% Cursos fijos (no optativos) de cada titulo.
curso_de_diplomado(C) :-
    curso(C, _, _, N, Ci, _),
    N > 0,
    ( N < 3 ; N =:= 3, Ci =:= 1 ).

curso_de_bachillerato(C) :-
    curso(C, _, _, N, _, _),
    N > 0.

faltantes_diplomado(Est, Faltantes) :-
    findall(C, ( curso_de_diplomado(C), \+ aprobado(Est, C) ), Faltantes).

faltantes_bachillerato(Est, Faltantes) :-
    findall(C, ( curso_de_bachillerato(C), \+ aprobado(Est, C) ), Faltantes).

%!  cumple_diplomado(+Est)
%   Aprobo todos los cursos hasta III nivel I ciclo y alcanza los
%   creditos del Diplomado.
cumple_diplomado(Est) :-
    faltantes_diplomado(Est, []),
    creditos_aprobados(Est, Cr),
    creditos_diplomado(Min),
    Cr >= Min.

%!  cumple_bachillerato(+Est)
%   Aprobo todos los cursos fijos, cumple las optativas y alcanza los
%   creditos del Bachillerato.
cumple_bachillerato(Est) :-
    faltantes_bachillerato(Est, []),
    optativas_ok(Est),
    creditos_aprobados(Est, Cr),
    creditos_bachillerato(Min),
    Cr >= Min.

optativas_aprobadas(Est, Lista) :-
    findall(C, ( aprobado(Est, C), es_optativo(C) ), Lista).

%!  optativas_ok(+Est)
%   Al menos 4 optativas aprobadas y al menos 2 de ellas disciplinarias.
optativas_ok(Est) :-
    optativas_aprobadas(Est, Optativas),
    length(Optativas, N),
    optativas_requeridas(Requeridas),
    N >= Requeridas,
    include(es_disciplinario, Optativas, Disciplinarias),
    length(Disciplinarias, ND),
    min_optativas_disciplinarias(MinD),
    ND >= MinD.
