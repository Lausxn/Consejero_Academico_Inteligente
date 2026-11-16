/*  pruebas_prolog.pl - Pruebas automaticas del back-end (plunit)

    Ejecutar desde la raiz del proyecto:
        swipl -g run_tests -t halt pruebas/pruebas_prolog.pl
    Los 15+ casos se agregan en el Bloque 7.
*/

:- use_module(library(plunit)).
:- ensure_loaded('../backend/main').

:- begin_tests(carga).

test(modulos_cargados) :-
    forall(member(M, [hechos, datos_ficticios, estudiantes, reglas,
                      inferencia, explicaciones, consultas]),
           current_module(M)).

:- end_tests(carga).
