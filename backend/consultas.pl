% consultas.pl - UNICA API que llama el front-end en C
%
% Responsabilidad: un predicado consulta_<caso> por caso de uso del menu.
% Todos siguen el mismo contrato (ver documentacion/diseno.md):
%     consulta_<caso>(+Arg1, ..., +ArgN, -Fila)
% Depende de: explicaciones, inferencia, reglas, estudiantes.
%
% Se completa en el Bloque 3.

:- module(consultas, []).
