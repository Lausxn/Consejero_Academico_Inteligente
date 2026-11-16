% estudiantes.pl - Estudiantes y cursos aprobados (hechos dinamicos)
%
% Responsabilidad: almacenar estudiante/2 y aprobado/2 en memoria
% (assert/retract) y persistirlos en datos/registros.txt.
% No valida reglas del dominio (si el curso existe, si cumple requisitos,
% etc.): eso lo hacen las capas superiores.
% Depende de: nada (capa de datos).
%
% Formato de registros.txt: terminos Prolog, uno por linea:
%     estudiante(208490835, 'Lausen Paniagua Arias').
%     aprobado(208490835, eif200).
% Se lee con read_term/3 (no con consult) y solo se aceptan esos dos
% tipos de termino, con los tipos correctos.

:- module(estudiantes, [
    estudiante/2,            % estudiante(Carne, Nombre)
    aprobado/2,              % aprobado(Carne, Curso)
    registrar_estudiante/2,
    agregar_aprobado/2,
    quitar_aprobado/2,
    guardar_registros/1,
    cargar_registros/1,
    ruta_registros/1,
    ruta_proyecto/2
]).

:- dynamic estudiante/2.
:- dynamic aprobado/2.

% ---------------------------------------------------------------------
% Rutas: se resuelven desde la carpeta del proyecto (no desde el
% directorio actual), para que funcione sin importar desde donde se
% ejecute el programa.
% ---------------------------------------------------------------------
:- dynamic directorio_backend/1.
:- retractall(directorio_backend(_)),
   prolog_load_context(directory, Dir),
   assertz(directorio_backend(Dir)).

%!  ruta_proyecto(+Relativa, -Absoluta)
%   Ruta dentro de la raiz del proyecto (carpeta padre de backend/).
ruta_proyecto(Relativa, Absoluta) :-
    directorio_backend(Dir),
    file_directory_name(Dir, Raiz),
    atomic_list_concat([Raiz, '/', Relativa], Absoluta).

% ruta_alternativa/1: solo la usan las pruebas, para no escribir sobre
% el registros.txt real.
:- dynamic ruta_alternativa/1.

ruta_registros(Ruta) :-
    ruta_alternativa(Ruta), !.
ruta_registros(Ruta) :-
    ruta_proyecto('datos/registros.txt', Ruta).

% ---------------------------------------------------------------------
% Altas y bajas (fallan si la operacion no tiene sentido)
% ---------------------------------------------------------------------

%!  registrar_estudiante(+Carne, +Nombre)
%   Falla si el carne ya esta registrado.
registrar_estudiante(Carne, Nombre) :-
    \+ estudiante(Carne, _),
    assertz(estudiante(Carne, Nombre)).

%!  agregar_aprobado(+Carne, +Curso)
%   Falla si el estudiante no existe o el curso ya estaba aprobado.
agregar_aprobado(Carne, Curso) :-
    estudiante(Carne, _),
    \+ aprobado(Carne, Curso),
    assertz(aprobado(Carne, Curso)).

%!  quitar_aprobado(+Carne, +Curso)
%   Falla si el curso no estaba aprobado.
quitar_aprobado(Carne, Curso) :-
    retract(aprobado(Carne, Curso)).

% ---------------------------------------------------------------------
% Persistencia
% ---------------------------------------------------------------------

%!  guardar_registros(+Ruta)
%   Escribe todos los estudiantes, cada uno seguido de sus aprobados.
guardar_registros(Ruta) :-
    setup_call_cleanup(
        open(Ruta, write, Salida, [encoding(utf8)]),
        escribir_registros(Salida),
        close(Salida)).

escribir_registros(Salida) :-
    format(Salida, "% Registros del Consejero Academico Inteligente.~n", []),
    format(Salida, "% Archivo generado automaticamente.~n~n", []),
    forall(estudiante(Carne, Nombre),
           escribir_estudiante(Salida, Carne, Nombre)).

escribir_estudiante(Salida, Carne, Nombre) :-
    portray_clause(Salida, estudiante(Carne, Nombre)),
    forall(aprobado(Carne, Curso),
           portray_clause(Salida, aprobado(Carne, Curso))),
    nl(Salida).

%!  cargar_registros(+Ruta)
%   Reemplaza los datos en memoria por los del archivo. Si el archivo no
%   existe, deja la base vacia (primer uso).
cargar_registros(Ruta) :-
    retractall(estudiante(_, _)),
    retractall(aprobado(_, _)),
    (   exists_file(Ruta)
    ->  setup_call_cleanup(
            open(Ruta, read, Entrada, [encoding(utf8)]),
            leer_terminos(Entrada),
            close(Entrada))
    ;   true
    ).

% leer_terminos(+Entrada): recorrido recursivo hasta end_of_file.
leer_terminos(Entrada) :-
    read_term(Entrada, Termino, []),
    (   Termino == end_of_file
    ->  true
    ;   cargar_termino(Termino),
        leer_terminos(Entrada)
    ).

% cargar_termino(+Termino): solo acepta terminos bien formados.
cargar_termino(estudiante(Carne, Nombre)) :-
    integer(Carne), atom(Nombre), !,
    assertz(estudiante(Carne, Nombre)).
cargar_termino(aprobado(Carne, Curso)) :-
    integer(Carne), atom(Curso), !,
    assertz(aprobado(Carne, Curso)).
cargar_termino(Termino) :-
    print_message(warning, format("registros.txt: termino ignorado ~q", [Termino])).
