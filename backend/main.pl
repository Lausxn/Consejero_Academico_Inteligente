/*  main.pl - Punto de carga del back-end (Consejero Academico Inteligente)

    Carga todos los modulos en el orden de dependencias:
        hechos / datos_ficticios / estudiantes   (capa de datos)
          -> reglas                              (reglas base)
            -> inferencia                        (recursivas y compuestas)
              -> explicaciones                   (el "por que")
                -> consultas                     (UNICA API que usa C)

    Cargar solo consultas seria suficiente (cada modulo importa lo que
    necesita), pero se listan todos para que el orden quede explicito.
*/

:- use_module(hechos).
:- use_module(datos_ficticios).
:- use_module(estudiantes).
:- use_module(reglas).
:- use_module(inferencia).
:- use_module(explicaciones).
:- use_module(consultas).
