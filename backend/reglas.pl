% reglas.pl - Reglas base del dominio
%
% Responsabilidad: deducir hechos "de primer nivel" a partir de los datos:
% acceso al plan, requisitos cumplidos, disponibilidad, correquisitos,
% choques de horario y creditos.
% Ninguna conclusion se guarda como hecho: todo se deduce con reglas.
% Depende de: hechos, datos_ficticios, estudiantes.

:- module(reglas, [
    existe_curso/1,
    nombre_de/2, creditos_de/2, nivel_de/2, ciclo_de/2, tipo_de/2,
    es_optativo/1, es_disciplinario/1,
    grupo_de/2, ofertado/1,
    correquisito/2,
    cumple_requisitos/2,
    requisito_faltante/3,
    puede_cursarse/2,
    disponible/2,
    correquisito_pendiente/3,
    choque_grupos/4,
    choque/2,
    suma_creditos/2,
    cursos_aprobados/2,
    creditos_aprobados/2
]).

:- use_module(hechos).
:- use_module(datos_ficticios).
:- use_module(estudiantes).
:- use_module(library(solution_sequences)).

% ---------------------------------------------------------------------
% Acceso al plan de estudios
% ---------------------------------------------------------------------
existe_curso(C)     :- curso(C, _, _, _, _, _).
nombre_de(C, N)     :- curso(C, N, _, _, _, _).
creditos_de(C, Cr)  :- curso(C, _, Cr, _, _, _).
nivel_de(C, N)      :- curso(C, _, _, N, _, _).
ciclo_de(C, Ci)     :- curso(C, _, _, _, Ci, _).
tipo_de(C, T)       :- curso(C, _, _, _, _, T).

es_optativo(C) :-
    tipo_de(C, T),
    memberchk(T, [optativo_disciplinario, optativo_libre]).

es_disciplinario(C) :-
    tipo_de(C, optativo_disciplinario).

%!  grupo_de(?Curso, ?Grupo)
%   Grupos con horario de un curso (sin repetir si un grupo tiene varias
%   sesiones).
grupo_de(C, G) :-
    distinct(C-G, horario(C, G, _, _, _)).

%!  ofertado(+Curso)
%   Un curso se oferta este ciclo si tiene al menos un grupo con horario.
ofertado(C) :-
    once(horario(C, _, _, _, _)).

% ---------------------------------------------------------------------
% Correquisitos: cierre simetrico de correquisito_base/2
% ---------------------------------------------------------------------
correquisito(A, B) :- correquisito_base(A, B).
correquisito(A, B) :- correquisito_base(B, A).

% ---------------------------------------------------------------------
% Requisitos y disponibilidad
% ---------------------------------------------------------------------

%!  cumple_requisitos(+Est, +Curso)
%   Todos los requisitos directos del curso estan aprobados.
cumple_requisitos(Est, C) :-
    forall(requisito(C, R), aprobado(Est, R)).

%!  requisito_faltante(+Est, ?Curso, ?Faltante)
%   Faltante es un requisito directo de Curso que Est no ha aprobado.
requisito_faltante(Est, C, R) :-
    requisito(C, R),
    \+ aprobado(Est, R).

%!  puede_cursarse(+Est, ?Curso)
%   No lo ha aprobado y cumple todos sus requisitos (sin mirar
%   correquisitos).
puede_cursarse(Est, C) :-
    existe_curso(C),
    \+ aprobado(Est, C),
    cumple_requisitos(Est, C).

%!  disponible(+Est, ?Curso)
%   Puede cursarse y cada correquisito esta aprobado o tambien puede
%   cursarse (y entonces se matricula en la misma combinacion).
disponible(Est, C) :-
    puede_cursarse(Est, C),
    forall(correquisito(C, K), correquisito_cubierto(Est, K)).

correquisito_cubierto(Est, K) :- aprobado(Est, K), !.
correquisito_cubierto(Est, K) :- puede_cursarse(Est, K).

%!  correquisito_pendiente(+Est, ?Curso, ?Correquisito)
%   Correquisito de Curso no aprobado: debe ir en la misma matricula.
correquisito_pendiente(Est, C, K) :-
    correquisito(C, K),
    \+ aprobado(Est, K).

% ---------------------------------------------------------------------
% Choques de horario
% ---------------------------------------------------------------------

%!  choque_grupos(?C1, ?G1, ?C2, ?G2)
%   Una sesion del grupo G1 de C1 y una del grupo G2 de C2 caen el mismo
%   dia con horas solapadas.
choque_grupos(C1, G1, C2, G2) :-
    horario(C1, G1, Dia, I1, F1),
    horario(C2, G2, Dia, I2, F2),
    C1 \== C2,
    horas_solapadas(I1, F1, I2, F2).

% Dos intervalos [I1,F1) y [I2,F2) se solapan.
horas_solapadas(I1, F1, I2, F2) :-
    I1 < F2,
    I2 < F1.

%!  choque(?C1, ?C2)
%   Algun grupo de C1 choca con algun grupo de C2 (cada par una vez).
choque(C1, C2) :-
    distinct(C1-C2, choque_grupos(C1, _, C2, _)).

% ---------------------------------------------------------------------
% Creditos
% ---------------------------------------------------------------------

%!  suma_creditos(+Cursos, -Total)
%   RECURSIVA. Caso base: lista vacia suma 0. Caso recursivo: creditos
%   de la cabeza + suma de la cola. Termina porque la lista se acorta.
suma_creditos([], 0).
suma_creditos([C|Cs], Total) :-
    creditos_de(C, Cr),
    suma_creditos(Cs, Parcial),
    Total is Parcial + Cr.

%!  cursos_aprobados(+Est, -Lista)
%   Aprobados que existen en el plan (si el profesor quita un curso del
%   plan en vivo, no rompe los calculos).
cursos_aprobados(Est, Lista) :-
    findall(C, ( aprobado(Est, C), existe_curso(C) ), Lista).

creditos_aprobados(Est, Total) :-
    cursos_aprobados(Est, Lista),
    suma_creditos(Lista, Total).
