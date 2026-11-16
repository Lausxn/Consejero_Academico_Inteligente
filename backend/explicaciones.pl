:- encoding(utf8).
% explicaciones.pl - El "por que" de cada conclusion
%
% Responsabilidad: convertir en texto las conclusiones de reglas.pl e
% inferencia.pl. No decide nada nuevo: solo explica lo que ya se dedujo.
% Tambien da formato a codigos, listas y horarios para la salida.
% Depende de: inferencia, reglas (y la capa de datos).

:- module(explicaciones, [
    % --- explicaciones de conclusiones
    explicar_disponible/3,
    explicar_no_disponible/3,
    explicar_recomendacion/3,
    explicar_choque/3,
    explicar_ruta/3,
    explicar_avance/2,
    describir_pendiente/3,
    % --- formato de salida
    texto_codigo/2,
    texto_lista/2,
    texto_grupo/3,
    texto_combinacion/2
]).

:- use_module(hechos).
:- use_module(datos_ficticios).
:- use_module(estudiantes).
:- use_module(reglas).
:- use_module(inferencia).
:- use_module(library(lists)).
:- use_module(library(apply)).

% =====================================================================
% Formato
% =====================================================================

%!  texto_codigo(+Curso, -Texto)   eif206 -> "EIF206"
texto_codigo(C, T) :-
    upcase_atom(C, T).

%!  texto_lista(+Cursos, -Texto)   [eif204, mat002] -> "EIF204, MAT002"
texto_lista([], "ninguno") :- !.
texto_lista(Cursos, Texto) :-
    maplist(texto_codigo, Cursos, Codigos),
    atomic_list_concat(Codigos, ', ', Texto).

%!  texto_grupo(+Curso, +Grupo, -Texto)   "G1 martes 16:00-19:00"
texto_grupo(C, G, Texto) :-
    findall(S, ( horario(C, G, Dia, I, F),
                 format(atom(S), "~w ~w:00-~w:00", [Dia, I, F]) ),
            Sesiones),
    atomic_list_concat(Sesiones, ' y ', TextoSesiones),
    format(atom(Texto), "G~w ~w", [G, TextoSesiones]).

%!  texto_combinacion(+[Curso-Grupo], -Texto)
texto_combinacion(Combinacion, Texto) :-
    maplist(texto_item_combinacion, Combinacion, Partes),
    atomic_list_concat(Partes, '; ', Texto).

texto_item_combinacion(C-G, T) :-
    texto_codigo(C, Cod),
    texto_grupo(C, G, Grupo),
    format(atom(T), "~w ~w", [Cod, Grupo]).

% Une frases no vacias con un espacio.
unir_frases(Frases, Texto) :-
    exclude(==(''), Frases, NoVacias),
    atomic_list_concat(NoVacias, ' ', Texto).

% =====================================================================
% 1. Por que esta disponible
% =====================================================================

%!  explicar_disponible(+Est, +Curso, -Texto)
explicar_disponible(Est, C, Texto) :-
    frase_requisitos_cumplidos(C, F1),
    frase_correquisitos(Est, C, F2),
    frase_oferta(C, F3),
    unir_frases([F1, F2, F3], Texto).

frase_requisitos_cumplidos(C, F) :-
    findall(R, requisito(C, R), Requisitos),
    (   Requisitos == []
    ->  F = 'No tiene requisitos (ingreso a carrera).'
    ;   texto_lista(Requisitos, L),
        format(atom(F), "Tiene aprobados todos sus requisitos: ~w.", [L])
    ).

frase_correquisitos(Est, C, F) :-
    findall(K, correquisito_pendiente(Est, C, K), Pendientes),
    (   Pendientes == []
    ->  F = ''
    ;   texto_lista(Pendientes, L),
        format(atom(F), "Debe matricularse junto con su correquisito ~w.", [L])
    ).

frase_oferta(C, F) :-
    (   ofertado(C)
    ->  F = ''
    ;   F = 'No se oferta este ciclo (sin horario asignado).'
    ).

% =====================================================================
% 2. Por que NO esta disponible
% =====================================================================

%!  explicar_no_disponible(+Est, +Curso, -Texto)
%   Casos: ya aprobado, faltan requisitos (con la cadena completa) o un
%   correquisito no se puede cursar todavia.
explicar_no_disponible(Est, C, 'Ya fue aprobado; no se vuelve a matricular.') :-
    aprobado(Est, C), !.
explicar_no_disponible(Est, C, Texto) :-
    texto_faltantes(Est, C, Detalle), !,
    format(atom(Texto), "No esta disponible porque falta ~w.", [Detalle]).
explicar_no_disponible(Est, C, Texto) :-
    correquisito(C, K),
    \+ aprobado(Est, K),
    \+ puede_cursarse(Est, K),
    texto_faltantes(Est, K, DetalleK), !,
    texto_codigo(K, CodK),
    format(atom(Texto),
           "Cumple sus requisitos, pero su correquisito ~w no puede cursarse aun: a ~w le falta ~w.",
           [CodK, CodK, DetalleK]).

% texto_faltantes(+Est, +Curso, -Detalle): falla si no le falta nada.
texto_faltantes(Est, C, Detalle) :-
    findall(R, requisito_faltante(Est, C, R), Faltantes),
    Faltantes \== [],
    maplist(describir_pendiente(Est), Faltantes, Partes),
    atomic_list_concat(Partes, '; ', Detalle).

%!  describir_pendiente(+Est, +Curso, -Texto)
%   RECURSIVA. "EIF211, que a su vez requiere EIF207 (...)".
%   - Caso base: el curso pendiente ya tiene sus requisitos aprobados.
%   - Caso recursivo: se describen sus requisitos faltantes.
%   Terminacion: baja por el grafo de requisitos, que es aciclico.
describir_pendiente(Est, C, Texto) :-
    texto_codigo(C, Cod),
    findall(R, requisito_faltante(Est, C, R), Faltantes),
    (   Faltantes == []
    ->  Texto = Cod
    ;   maplist(describir_pendiente(Est), Faltantes, Partes),
        atomic_list_concat(Partes, ' y ', Sub),
        format(atom(Texto), "~w, que a su vez requiere ~w", [Cod, Sub])
    ).

% =====================================================================
% 3. Por que se recomienda
% =====================================================================

%!  explicar_recomendacion(+Est, +Curso, -Texto)
explicar_recomendacion(Est, C, Texto) :-
    frase_atraso(Est, C, F1),
    frase_desbloqueo(C, F2),
    frase_correquisitos(Est, C, F3),
    frase_optativo(C, F4),
    unir_frases([F1, F2, F3, F4], Texto0),
    (   Texto0 == ''
    ->  nivel_de(C, N), ciclo_de(C, Ci),
        format(atom(Texto), "Corresponde al nivel ~w, ciclo ~w del plan.", [N, Ci])
    ;   Texto = Texto0
    ).

frase_atraso(Est, C, F) :-
    (   atrasado(Est, C)
    ->  nivel_de(C, N), nivel_actual(Est, A),
        format(atom(F), "Esta atrasado: es de nivel ~w y ya cursa nivel ~w.", [N, A])
    ;   F = ''
    ).

frase_desbloqueo(C, F) :-
    cantidad_desbloquea(C, Total),
    (   Total > 0
    ->  cursos_que_desbloquea(C, Directos),
        texto_lista(Directos, L),
        format(atom(F), "Desbloquea ~w curso(s) en total (directamente: ~w).", [Total, L])
    ;   F = ''
    ).

frase_optativo(C, F) :-
    (   es_disciplinario(C)
    ->  F = 'Optativo disciplinario: cuenta para las optativas requeridas.'
    ;   es_optativo(C)
    ->  F = 'Optativo libre: cuenta para las optativas requeridas.'
    ;   F = ''
    ).

% =====================================================================
% 4. Por que hay choque
% =====================================================================

%!  explicar_choque(+C1-G1, +C2-G2, -Texto)
explicar_choque(C1-G1, C2-G2, Texto) :-
    horario(C1, G1, Dia, I1, F1),
    horario(C2, G2, Dia, I2, F2),
    I1 < F2, I2 < F1, !,
    Desde is max(I1, I2),
    Hasta is min(F1, F2),
    texto_codigo(C1, Cod1),
    texto_codigo(C2, Cod2),
    format(atom(Texto),
           "~w G~w y ~w G~w coinciden el ~w de ~w:00 a ~w:00.",
           [Cod1, G1, Cod2, G2, Dia, Desde, Hasta]).

% =====================================================================
% 5. Por que esa ruta
% =====================================================================

%!  explicar_ruta(+Est, +Ruta, -Texto)
explicar_ruta(Est, [Primero|Resto], Texto) :-
    texto_codigo(Primero, P),
    (   Resto == []
    ->  format(atom(Base), "~w ya cumple sus requisitos: puede matricularlo.", [P])
    ;   last(Resto, Meta),
        texto_codigo(Meta, M),
        length(Resto, Pasos),
        format(atom(Base),
               "Empiece por ~w (ya cumple sus requisitos); cada curso de la ruta es requisito del siguiente, asi que llega a ~w en ~w paso(s) mas.",
               [P, M, Pasos])
    ),
    frase_correquisitos(Est, Primero, Correquisito),
    unir_frases([Base, Correquisito], Texto).

% =====================================================================
% 6. Avance de carrera
% =====================================================================

%!  explicar_avance(+Est, -Lineas)
%   Lineas = [Etiqueta-Texto, ...]
explicar_avance(Est, [
        'Creditos aprobados'-TCreditos,
        'Avance de carrera'-TAvance,
        'Nivel actual'-Nivel,
        'Diplomado'-TDiplomado,
        'Bachillerato'-TBachillerato,
        'Optativas'-TOptativas
    ]) :-
    creditos_aprobados(Est, Cr),
    creditos_bachillerato(CrB),
    format(atom(TCreditos), "~w de ~w", [Cr, CrB]),
    porcentaje_avance(Est, P),
    format(atom(TAvance), "~w %", [P]),
    nivel_actual(Est, Nivel),
    texto_titulo(Est, diplomado, TDiplomado),
    texto_titulo(Est, bachillerato, TBachillerato),
    texto_optativas(Est, TOptativas).

texto_titulo(Est, diplomado, Texto) :-
    creditos_diplomado(Min),
    faltantes_diplomado(Est, Faltan),
    texto_estado_titulo(Est, cumple_diplomado(Est), Min, Faltan, Texto).
texto_titulo(Est, bachillerato, Texto) :-
    creditos_bachillerato(Min),
    faltantes_bachillerato(Est, Faltan),
    texto_estado_titulo(Est, cumple_bachillerato(Est), Min, Faltan, Texto).

texto_estado_titulo(Est, Cumple, Min, Faltan, Texto) :-
    creditos_aprobados(Est, Cr),
    (   call(Cumple)
    ->  format(atom(Texto), "CUMPLE (~w creditos, minimo ~w).", [Cr, Min])
    ;   length(Faltan, N),
        CrFaltan is max(0, Min - Cr),
        texto_lista(Faltan, L),
        format(atom(Texto),
               "No cumple: faltan ~w credito(s) y ~w curso(s) fijos: ~w.",
               [CrFaltan, N, L])
    ).

texto_optativas(Est, Texto) :-
    optativas_aprobadas(Est, Optativas),
    length(Optativas, N),
    include(es_disciplinario, Optativas, Disc),
    length(Disc, ND),
    optativas_requeridas(Req),
    min_optativas_disciplinarias(MinD),
    ( optativas_ok(Est) -> Estado = 'CUMPLE' ; Estado = 'No cumple' ),
    format(atom(Texto),
           "~w: ~w de ~w aprobadas (~w disciplinarias, minimo ~w).",
           [Estado, N, Req, ND, MinD]).
