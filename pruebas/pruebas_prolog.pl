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
