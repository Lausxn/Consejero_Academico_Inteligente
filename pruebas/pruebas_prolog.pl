/*  pruebas_prolog.pl - Pruebas automaticas del back-end (plunit)

    Ejecutar desde la raiz del proyecto:
        swipl -g run_tests -t halt pruebas/pruebas_prolog.pl
    (o: mingw32-make test)
*/

:- use_module(library(plunit)).
:- ensure_loaded('../backend/main').

% Carga los perfiles de prueba antes de las pruebas que los usan.
cargar_perfiles :-
    ruta_registros(Ruta),
    cargar_registros(Ruta).

% ---------------------------------------------------------------------
:- begin_tests(carga).

test(modulos_cargados) :-
    forall(member(M, [hechos, datos_ficticios, estudiantes, reglas,
                      inferencia, explicaciones, consultas]),
           current_module(M)).

:- end_tests(carga).

% ---------------------------------------------------------------------
% Bloque 1: integridad de la base de conocimientos
% ---------------------------------------------------------------------
:- begin_tests(base_conocimientos).

test(cantidad_cursos, [true(N == 67)]) :-
    aggregate_all(count, curso(_, _, _, _, _, _), N).

% Cada requisito apunta a cursos que existen.
test(requisitos_consistentes) :-
    forall(requisito(C, R),
           ( curso(C, _, _, _, _, _), curso(R, _, _, _, _, _) )).

% I y II nivel + III nivel I ciclo suman exactamente los creditos del Diplomado.
test(creditos_diplomado, [true(Total == Esperado)]) :-
    creditos_diplomado(Esperado),
    aggregate_all(sum(Cr),
                  ( curso(_, _, Cr, N, Ci, _), N > 0,
                    ( N < 3 ; N =:= 3, Ci =:= 1 ) ),
                  Total).

% Obligatorios + generales + 4 optativas de 3 creditos = Bachillerato.
test(creditos_bachillerato, [true(Total == Esperado)]) :-
    creditos_bachillerato(Esperado),
    optativas_requeridas(NOpt),
    aggregate_all(sum(Cr), ( curso(_, _, Cr, N, _, _), N > 0 ), Fijos),
    Total is Fijos + NOpt * 3.

% FICTICIO: cada horario es de un curso existente, en dia valido y Inicio < Fin.
test(horarios_validos) :-
    forall(horario(C, _, Dia, Ini, Fin),
           ( curso(C, _, _, _, _, _), dia_semana(Dia, _), Ini < Fin )).

% FICTICIO: los cursos de I a IV nivel tienen al menos un grupo.
test(cursos_de_nivel_con_horario) :-
    forall(( curso(C, _, _, N, _, _), N > 0 ), horario(C, _, _, _, _)).

test(correquisitos_consistentes) :-
    forall(correquisito_base(A, B),
           ( curso(A, _, _, _, _, _), curso(B, _, _, _, _, _) )).

:- end_tests(base_conocimientos).

% ---------------------------------------------------------------------
% Bloque 1: estudiantes y persistencia
% ---------------------------------------------------------------------
:- begin_tests(estudiantes, [setup(cargar_perfiles)]).

test(perfiles_cargados, [true(N == 5)]) :-
    aggregate_all(count, estudiante(_, _), N).

test(aprobados_lausen, [true(N == 10)]) :-
    aggregate_all(count, aprobado(208490835, _), N).

test(primer_ingreso_sin_aprobados) :-
    \+ aprobado(111110001, _).

% Todos los cursos aprobados en los registros existen en el plan.
test(aprobados_existen) :-
    forall(aprobado(_, C), curso(C, _, _, _, _, _)).

test(registrar_duplicado_falla, [fail]) :-
    registrar_estudiante(208490835, 'Otro Nombre').

test(agregar_y_quitar_aprobado) :-
    agregar_aprobado(111110001, eif200),
    aprobado(111110001, eif200),
    quitar_aprobado(111110001, eif200),
    \+ aprobado(111110001, eif200).

% Guardar y volver a cargar deja exactamente los mismos hechos.
test(guardar_y_cargar, [cleanup(cargar_perfiles)]) :-
    tmp_file_stream(text, Tmp, S), close(S),
    findall(E-A, ( estudiante(E, _), aprobado(E, A) ), Antes),
    guardar_registros(Tmp),
    cargar_registros(Tmp),
    findall(E-A, ( estudiante(E, _), aprobado(E, A) ), Despues),
    delete_file(Tmp),
    msort(Antes, X), msort(Despues, X).

:- end_tests(estudiantes).

% ---------------------------------------------------------------------
% Bloque 2: reglas base
% ---------------------------------------------------------------------

% Estudiante temporal para casos puntuales (se borra al terminar).
con_estudiante_temporal(Aprobados, Meta) :-
    Carne = 999999999,
    setup_call_cleanup(
        ( registrar_estudiante(Carne, 'Temporal'),
          forall(member(C, Aprobados), agregar_aprobado(Carne, C)) ),
        call(Meta, Carne),
        ( retractall(estudiantes:aprobado(Carne, _)),
          retractall(estudiantes:estudiante(Carne, _)) )).

:- begin_tests(reglas, [setup(cargar_perfiles)]).

% Ejemplo del enunciado: disponibles y no disponibles.
test(ejemplo_enunciado_disponibles) :-
    forall(member(C, [eif206, eif207, mat005, mat006, eif202]),
           disponible(111110004, C)),
    \+ disponible(111110004, eif205),
    \+ disponible(111110004, eif211).

test(ejemplo_enunciado_falta_para_eif211, [true(Fs == [eif206, eif207])]) :-
    findall(F, requisito_faltante(111110004, eif211, F), Fs).

% Primer ingreso: solo cursos de I nivel sin requisitos (y optativos libres).
test(primer_ingreso_solo_sin_requisitos) :-
    forall(( disponible(111110001, C), \+ es_optativo(C) ),
           ( nivel_de(C, 1), \+ requisito(C, _) )).

test(no_disponible_si_ya_aprobado) :-
    \+ disponible(208490835, eif200).

test(correquisito_simetrico, [nondet]) :-
    correquisito(eif201, mat002),
    correquisito(mat002, eif201).

% Maria puede cursar EIF401 por requisitos, pero su correquisito EIF402
% no es cursable (le falta EIF212), asi que EIF401 NO esta disponible.
test(correquisito_bloquea_disponibilidad) :-
    puede_cursarse(111110003, eif401),
    \+ disponible(111110003, eif401).

test(choque_intencional, [nondet]) :-
    choque(eif206, eif207),
    choque(eif402, eif412).

test(suma_creditos_recursiva, [true(T == 7)]) :-
    suma_creditos([eif200, mat030], T).

:- end_tests(reglas).

% ---------------------------------------------------------------------
% Bloque 2: inferencia (recursividad, backtracking, avance)
% ---------------------------------------------------------------------
:- begin_tests(inferencia, [setup(cargar_perfiles)]).

% Recursividad: EIF402 -> EIF211 -> EIF207 (indirecto).
test(requisito_indirecto, [nondet]) :-
    requiere_indirecto(eif402, eif207),
    \+ requisito(eif402, eif207).

test(sin_requisitos_cadena_vacia, [true(L == [])]) :-
    cadena_requisitos(eif200, L).

% Varias soluciones por backtracking: 3 cadenas hacia EIF402.
test(rutas_multiples, [true(Rs == [[eif205, eif212, eif402],
                                   [eif206, eif211, eif402],
                                   [eif207, eif211, eif402]])]) :-
    findall(R, ruta_hacia(208490835, eif402, R), Rs).

test(ruta_meta_aprobada_falla, [fail]) :-
    ruta_hacia(208490835, eif200, _).

test(plan_por_etapas, [true(E == [[eif205, eif206, eif207],
                                  [eif209, eif210, eif211, eif212],
                                  [eif401, eif402],
                                  [eif408]])]) :-
    plan_por_etapas(208490835, eif408, E).

test(atrasados, [true(L == [eif202, lix411])]) :-
    findall(C, atrasado(111110003, C), L0), msort(L0, L).

test(prioridad_atrasados_primero, [true(Primeros == [eif202, lix411])]) :-
    cursos_priorizados(111110003, [A, B|_]),
    Primeros = [A, B].

% Backtracking: toda combinacion respeta tope, no tiene choques y
% no repite cursos.
test(combinaciones_validas) :-
    forall(limit(30, combinacion_valida(208490835, 18, Comb)),
           ( creditos_combinacion(Comb, Cr), Cr =< 18,
             \+ ( member(C1-G1, Comb), member(C2-G2, Comb),
                  choque_grupos(C1, G1, C2, G2) ) )).

% El correquisito pendiente va en la misma combinacion.
test(combinacion_incluye_correquisito) :-
    con_estudiante_temporal([eif200, mat030], [E]>>(
        forall(( limit(30, combinacion_valida(E, 18, Comb)),
                 memberchk(eif201-_, Comb) ),
               memberchk(mat002-_, Comb)))).

% Diplomado completo: la recomendacion lleva EIF401 y EIF402 juntos
% (correquisitos) y nunca EIF412 con EIF402 (choque inevitable).
test(recomendacion_diplomado) :-
    recomendar(111110002, 18, 3, [Primera|_]),
    memberchk(eif401-_, Primera),
    memberchk(eif402-_, Primera),
    \+ memberchk(eif412-_, Primera).

test(recomendacion_anual_respeta_topes) :-
    recomendar_anual(208490835, 18, 36, [C1, C2]),
    creditos_combinacion(C1, Cr1), Cr1 =< 18,
    creditos_combinacion(C2, Cr2), Cr2 =< 18,
    Cr1 + Cr2 =< 36,
    \+ aprobado(sim(_), _).        % la simulacion no deja basura

test(asignar_grupos_resuelve_correquisitos_en_choque) :-
    asignar_grupos([eif209, eif210], A),
    memberchk(eif210-2, A).

test(asignar_grupos_choque_inevitable, [fail]) :-
    asignar_grupos([eif402, eif412], _).

test(avance_diplomado) :-
    creditos_aprobados(111110002, 88),
    cumple_diplomado(111110002),
    \+ cumple_bachillerato(111110002).

test(avance_porcentaje, [true(P =:= 26.4)]) :-
    porcentaje_avance(208490835, P).

test(optativas_ok) :-
    con_estudiante_temporal([eif429o, eif430o, eif427o, eif441o],
                            [E]>>optativas_ok(E)),
    con_estudiante_temporal([eif429o, eif430o, eif437o, eif438o],
                            [E]>>( \+ optativas_ok(E) )).

:- end_tests(inferencia).
