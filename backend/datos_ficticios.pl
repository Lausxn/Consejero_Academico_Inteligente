:- encoding(utf8).
% datos_ficticios.pl - Datos que el plan oficial NO trae
%
% *** TODO LO DE ESTE ARCHIVO ES FICTICIO (inventado por el equipo) ***
% Se mantiene separado de hechos.pl para no mezclar datos oficiales con
% datos de prueba.
%
% Responsabilidad: correquisitos, horarios por grupo y topes de creditos.
% Depende de: nada (capa de datos).

:- module(datos_ficticios, [
    correquisito_base/2,     % correquisito_base(CursoA, CursoB)
    horario/5,               % horario(Curso, Grupo, Dia, HoraInicio, HoraFin)
    dia_semana/2,            % dia_semana(Dia, Orden)
    tope_creditos_ciclo/1,
    tope_creditos_anual/1
]).

% ---------------------------------------------------------------------
% CORREQUISITOS (FICTICIOS)
% Se escriben en un solo sentido; reglas.pl los vuelve simetricos.
% Un correquisito se cumple si el otro curso ya esta aprobado o si se
% matricula en la misma combinacion.
% ---------------------------------------------------------------------
correquisito_base(eif201, mat002).
correquisito_base(eif209, eif210).
correquisito_base(eif401, eif402).

% ---------------------------------------------------------------------
% TOPES DE CREDITOS (definidos por el equipo)
% ---------------------------------------------------------------------
tope_creditos_ciclo(18).    % maximo por ciclo (semestre)
tope_creditos_anual(36).    % maximo por anio (2 ciclos)

% ---------------------------------------------------------------------
% DIAS (el orden se usa para imprimir horarios ordenados)
% ---------------------------------------------------------------------
dia_semana(lunes,     1).
dia_semana(martes,    2).
dia_semana(miercoles, 3).
dia_semana(jueves,    4).
dia_semana(viernes,   5).

% ---------------------------------------------------------------------
% HORARIOS (FICTICIOS)
% horario(Curso, Grupo, Dia, HoraInicio, HoraFin)  - horas enteras 24 h
%
% Esquema base del grupo 1:
%   I nivel   : I ciclo 7-10,  II ciclo 10-13
%   II nivel  : I ciclo 13-16, II ciclo 16-19
%   III nivel : I ciclo 18-21, II ciclo 13-16
%   IV nivel  : I ciclo 16-19, II ciclo 10-13
% El grupo 2 (cuando existe) da una alternativa para resolver choques.
%
% CHOQUES INTENCIONALES (para demostrar la deteccion de conflictos):
%   (1) eif206-1 vs eif207-1  martes 16-19     -> se resuelve con eif207-2
%   (2) eif209-1 vs eif210-1  martes 18-21     -> son correquisitos: deben
%                                                 ir juntos, se resuelve
%                                                 con eif210-2
%   (3) eif211-1 vs eif212-1  jueves 18-21     -> se resuelve con eif211-2
%   (4) eif402-1 vs eif412-1  miercoles 13-16  -> INEVITABLE (un solo
%                                                 grupo cada uno)
%   (5) eif207-2 vs eif427o-1 viernes 16-19    -> optativo vs obligatorio
%
% Los cursos optativos que no tienen horario se consideran "no ofertados"
% este ciclo: pueden estar disponibles, pero no entran en combinaciones.
% ---------------------------------------------------------------------

% ----- I NIVEL, I ciclo -----
horario(eif200, 1, lunes,     7, 10).
horario(eif200, 2, miercoles, 18, 21).
horario(mat030, 1, martes,    7, 10).
horario(mat030, 2, jueves,    18, 21).
horario(eg1,    1, miercoles, 7, 10).
horario(eg2,    1, jueves,    7, 10).
horario(lix410, 1, viernes,   7, 10).
horario(lix410, 2, lunes,     18, 21).

% ----- I NIVEL, II ciclo -----
horario(eif201, 1, lunes,     10, 13).
horario(eif201, 2, viernes,   18, 21).
horario(mat002, 1, martes,    10, 13).
horario(mat002, 2, miercoles, 7, 10).
horario(eg3,    1, miercoles, 10, 13).
horario(eg4,    1, jueves,    10, 13).
horario(lix411, 1, viernes,   10, 13).
horario(lix411, 2, martes,    13, 16).

% ----- II NIVEL, I ciclo -----
horario(eif202, 1, lunes,     13, 16).
horario(eif203, 1, martes,    13, 16).
horario(eif204, 1, miercoles, 13, 16).
horario(eif204, 2, viernes,   13, 16).
horario(mat005, 1, jueves,    13, 16).
horario(lix412, 1, viernes,   13, 16).

% ----- II NIVEL, II ciclo -----
horario(eif205, 1, lunes,     16, 19).
horario(eif206, 1, martes,    16, 19).          % choque (1)
horario(eif206, 2, lunes,     7, 10).
horario(eif207, 1, martes,    16, 19).          % choque (1)
horario(eif207, 2, viernes,   16, 19).          % choque (5)
horario(eif404, 1, miercoles, 16, 19).
horario(mat006, 1, jueves,    16, 19).

% ----- III NIVEL, I ciclo -----
horario(eif208, 1, lunes,     18, 21).
horario(eif209, 1, martes,    18, 21).          % choque (2)
horario(eif210, 1, martes,    18, 21).          % choque (2)
horario(eif210, 2, miercoles, 18, 21).
horario(eif211, 1, jueves,    18, 21).          % choque (3)
horario(eif211, 2, viernes,   18, 21).
horario(eif212, 1, jueves,    18, 21).          % choque (3)

% ----- III NIVEL, II ciclo -----
horario(eif400, 1, lunes,     13, 16).
horario(eif401, 1, martes,    13, 16).
horario(eif401, 2, viernes,   7, 10).
horario(eif402, 1, miercoles, 13, 16).          % choque (4)
horario(eif407, 1, jueves,    13, 16).
horario(eif412, 1, miercoles, 13, 16).          % choque (4)

% ----- IV NIVEL, I ciclo -----
horario(eif406, 1, lunes,     16, 19).
horario(eif411, 1, martes,    16, 19).
horario(eif413, 1, miercoles, 16, 19).

% ----- IV NIVEL, II ciclo -----
horario(eif408, 1, lunes,     10, 13).
horario(eif409, 1, martes,    10, 13).
horario(eif410, 1, miercoles, 10, 13).

% ----- OPTATIVOS OFERTADOS ESTE CICLO -----
horario(eif420o, 1, jueves,    16, 19).
horario(eif421o, 1, viernes,   13, 16).
horario(eif422o, 1, viernes,   10, 13).
horario(eif427o, 1, viernes,   16, 19).        % choque (5)
horario(eif428o, 1, lunes,     16, 19).
horario(eif434o, 1, jueves,    13, 16).
horario(eif440o, 1, viernes,   7, 10).
horario(eif441o, 1, miercoles, 7, 10).
horario(eif429o, 1, martes,    7, 10).         % optativo libre
horario(eif444o, 1, jueves,    18, 21).        % optativo libre
