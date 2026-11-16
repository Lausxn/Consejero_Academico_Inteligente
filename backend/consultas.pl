% consultas.pl - UNICA API que llama el front-end en C
%
% Responsabilidad: un predicado consulta_<caso> por caso de uso del menu.
% Recibe las entradas tal como las escribio el usuario, las valida contra
% el dominio, invoca las reglas y devuelve filas de texto listas para
% imprimir. C no conoce nada de lo que hay detras de esta API.
% Depende de: explicaciones, inferencia, reglas, estudiantes (y datos).
%
% CONTRATO (igual para todas las consultas):
%   consulta_<caso>(+Arg1, ..., +ArgN, -Fila)
%   - Entradas: textos (string o atomo) escritos por el usuario.
%   - Fila: lista de textos (columnas). La consulta es NO determinista:
%     cada solucion es una fila; C las recorre con PL_next_solution.
%   - Sin resultados: la consulta falla (C muestra "sin resultados").
%   - Error del dominio: throw(error_sipa(Mensaje)).
%   - Toda la salida pasa por responder/2, que la deja en texto plano
%     sin acentos (decision D5 del diseno).

:- module(consultas, [
    consulta_existe_estudiante/2,
    consulta_existe_curso/2,
    consulta_estudiantes/1,
    consulta_registrar_estudiante/3,
    consulta_agregar_aprobado/3,
    consulta_quitar_aprobado/3,
    consulta_aprobados/2,
    consulta_tipos/1,
    consulta_plan_nivel/2,
    consulta_plan_tipo/2,
    consulta_requisitos_curso/2,
    consulta_disponibles/2,
    consulta_que_falta/3,
    consulta_ruta/3,
    consulta_choques/2,
    consulta_recomendar/4,
    consulta_avance/2,
    consulta_guardar/1,
    consulta_cargar/1,
    consulta_recargar_base/1
]).

:- use_module(hechos).
:- use_module(datos_ficticios).
:- use_module(estudiantes).
:- use_module(reglas).
:- use_module(inferencia).
:- use_module(explicaciones).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(solution_sequences)).

% Cantidad maxima de opciones y rutas que se muestran.
max_opciones_recomendacion(3).
max_rutas(10).

% =====================================================================
% Validacion y normalizacion de entradas (errores -> error_sipa/1)
% =====================================================================

error_sipa(Formato, Args) :-
    format(atom(Mensaje), Formato, Args),
    throw(error_sipa(Mensaje)).

texto_limpio(Entrada, Texto) :-
    text_to_string(Entrada, S0),
    normalize_space(string(Texto), S0).

%!  carne_valido(+Entrada, -Carne)   "208490835" -> 208490835
carne_valido(Entrada, Carne) :-
    texto_limpio(Entrada, Texto),
    (   string_length(Texto, 9),
        string_codes(Texto, Codigos),
        forall(member(D, Codigos), code_type(D, digit))
    ->  number_string(Carne, Texto)
    ;   error_sipa("El carne '~w' no es valido: debe tener 9 digitos.", [Texto])
    ).

%!  estudiante_registrado(+Entrada, -Carne)
estudiante_registrado(Entrada, Carne) :-
    carne_valido(Entrada, Carne),
    (   estudiante(Carne, _)
    ->  true
    ;   error_sipa("No existe un estudiante con carne ~w.", [Carne])
    ).

%!  curso_valido(+Entrada, -Curso)   "EIF206" -> eif206 (si existe)
curso_valido(Entrada, Curso) :-
    texto_limpio(Entrada, Texto),
    string_lower(Texto, Minuscula),
    atom_string(Curso, Minuscula),
    (   existe_curso(Curso)
    ->  true
    ;   error_sipa("El curso '~w' no existe en el plan de estudios.", [Texto])
    ).

%!  entero_en_rango(+Entrada, +Min, +Max, +Que, -N)
entero_en_rango(Entrada, Min, Max, Que, N) :-
    texto_limpio(Entrada, Texto),
    (   catch(number_string(N, Texto), _, fail),
        integer(N), N >= Min, N =< Max
    ->  true
    ;   error_sipa("~w debe ser un numero entero entre ~w y ~w.", [Que, Min, Max])
    ).

nombre_valido(Entrada, Nombre) :-
    texto_limpio(Entrada, Texto),
    string_length(Texto, Largo),
    (   Largo > 0, Largo =< 80
    ->  atom_string(Nombre, Texto)
    ;   error_sipa("El nombre no puede estar vacio ni superar 80 caracteres.", [])
    ).

% Lista de cursos escrita por el usuario: "eif206, EIF207 eif211"
seleccion_valida(Entrada, Cursos) :-
    texto_limpio(Entrada, Texto),
    split_string(Texto, " ,;", " ,;", Partes0),
    exclude(==(""), Partes0, Partes),
    maplist(curso_valido, Partes, Cursos0),
    list_to_set(Cursos0, Cursos),
    length(Cursos, N),
    (   N >= 2
    ->  true
    ;   error_sipa("Ingrese al menos 2 cursos distintos.", [])
    ).

% =====================================================================
% Salida: filas en texto plano
% =====================================================================

%!  responder(+Columnas, -Fila)
%   Convierte cada columna a string sin acentos.
responder(Columnas, Fila) :-
    maplist(texto_plano, Columnas, Fila).

%!  emitir(+Filas, -Fila)   una solucion por fila (backtracking)
emitir(Filas, Fila) :-
    member(Columnas, Filas),
    responder(Columnas, Fila).

texto_plano(Valor, Plano) :-
    format(string(S), "~w", [Valor]),
    string_codes(S, Codigos),
    maplist(sin_acento, Codigos, Limpios),
    string_codes(Plano, Limpios).

sin_acento(C, L) :- acento(C, L), !.
sin_acento(C, C) :- C < 128, !.
sin_acento(_, 0'?).

acento(0'á, 0'a). acento(0'é, 0'e). acento(0'í, 0'i).
acento(0'ó, 0'o). acento(0'ú, 0'u). acento(0'ü, 0'u). acento(0'ñ, 0'n).
acento(0'Á, 0'A). acento(0'É, 0'E). acento(0'Í, 0'I).
acento(0'Ó, 0'O). acento(0'Ú, 0'U). acento(0'Ü, 0'U). acento(0'Ñ, 0'N).

texto_curso(C, Texto) :-
    texto_codigo(C, Cod),
    nombre_de(C, Nombre),
    format(atom(Texto), "~w - ~w", [Cod, Nombre]).

% Cada modificacion se guarda de inmediato (RF-14).
persistir :-
    ruta_registros(Ruta),
    guardar_registros(Ruta).

% =====================================================================
% Validacion previa (RF-03)
% =====================================================================

consulta_existe_estudiante(CarneT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    estudiante(Carne, Nombre),
    responder([Nombre], Fila).

consulta_existe_curso(CursoT, Fila) :-
    curso_valido(CursoT, C),
    texto_codigo(C, Cod),
    nombre_de(C, Nombre),
    responder([Cod, Nombre], Fila).

% =====================================================================
% 1-2. Estudiantes y cursos aprobados
% =====================================================================

consulta_estudiantes(Fila) :-
    estudiante(Carne, Nombre),
    creditos_aprobados(Carne, Cr),
    porcentaje_avance(Carne, P),
    format(atom(Avance), "~w %", [P]),
    responder([Carne, Nombre, Cr, Avance], Fila).

consulta_registrar_estudiante(CarneT, NombreT, Fila) :-
    carne_valido(CarneT, Carne),
    nombre_valido(NombreT, Nombre),
    (   estudiante(Carne, Existente)
    ->  error_sipa("Ya existe un estudiante con carne ~w (~w).", [Carne, Existente])
    ;   true
    ),
    registrar_estudiante(Carne, Nombre),
    persistir,
    format(atom(Msg), "Estudiante ~w registrado: ~w.", [Carne, Nombre]),
    responder([Msg], Fila).

consulta_agregar_aprobado(CarneT, CursoT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    curso_valido(CursoT, C),
    texto_codigo(C, Cod),
    (   aprobado(Carne, C)
    ->  error_sipa("~w ya estaba registrado como aprobado.", [Cod])
    ;   true
    ),
    findall(R, requisito_faltante(Carne, C, R), SinAprobar),
    agregar_aprobado(Carne, C),
    persistir,
    format(atom(Msg), "~w registrado como aprobado.", [Cod]),
    advertencia_requisitos(SinAprobar, Advertencias),
    emitir([[Msg]|Advertencias], Fila).

advertencia_requisitos([], []) :- !.
advertencia_requisitos(SinAprobar, [[Msg]]) :-
    texto_lista(SinAprobar, L),
    format(atom(Msg),
           "Advertencia: sus requisitos ~w no estan registrados como aprobados.", [L]).

consulta_quitar_aprobado(CarneT, CursoT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    curso_valido(CursoT, C),
    texto_codigo(C, Cod),
    (   quitar_aprobado(Carne, C)
    ->  true
    ;   error_sipa("~w no estaba registrado como aprobado.", [Cod])
    ),
    persistir,
    findall(X, ( aprobado(Carne, X), requisito(X, C) ), Dependientes),
    format(atom(Msg), "~w quitado de los cursos aprobados.", [Cod]),
    advertencia_dependientes(Dependientes, Advertencias),
    emitir([[Msg]|Advertencias], Fila).

advertencia_dependientes([], []) :- !.
advertencia_dependientes(Dependientes, [[Msg]]) :-
    texto_lista(Dependientes, L),
    format(atom(Msg),
           "Advertencia: ~w siguen aprobados y lo tienen como requisito.", [L]).

%   Fila: [Codigo, Nombre, Creditos, Ubicacion]
consulta_aprobados(CarneT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    findall(k(N, Ci, C), ( aprobado(Carne, C), nivel_de(C, N), ciclo_de(C, Ci) ), L0),
    msort(L0, L),
    member(k(_, _, C), L),
    fila_curso(C, Fila).

% Fila estandar de un curso: [Codigo, Nombre, Creditos, Ubicacion, Requisitos]
fila_curso(C, Fila) :-
    texto_codigo(C, Cod),
    nombre_de(C, Nombre),
    creditos_de(C, Cr),
    texto_ubicacion(C, Ubicacion),
    findall(R, requisito(C, R), Reqs),
    texto_lista(Reqs, TReqs),
    responder([Cod, Nombre, Cr, Ubicacion, TReqs], Fila).

texto_ubicacion(C, Texto) :-
    nivel_de(C, N),
    ciclo_de(C, Ci),
    (   N =:= 0
    ->  Texto = 'Optativo'
    ;   format(atom(Texto), "Nivel ~w Ciclo ~w", [N, Ci])
    ).

% =====================================================================
% 3. Plan de estudios
% =====================================================================

%   Fila: [Tipo, CantidadDeCursos]   (C arma el submenu con esto)
consulta_tipos(Fila) :-
    setof(T, C^N^Cr^Nv^Ci^curso(C, N, Cr, Nv, Ci, T), Tipos),
    member(T, Tipos),
    aggregate_all(count, tipo_de(_, T), Cantidad),
    responder([T, Cantidad], Fila).

consulta_plan_nivel(NivelT, Fila) :-
    aggregate_all(max(N), nivel_de(_, N), Max),
    entero_en_rango(NivelT, 1, Max, 'El nivel', Nivel),
    findall(k(Ci, C), ( nivel_de(C, Nivel), ciclo_de(C, Ci) ), L0),
    msort(L0, L),
    member(k(_, C), L),
    fila_curso(C, Fila).

consulta_plan_tipo(TipoT, Fila) :-
    texto_limpio(TipoT, Texto),
    atom_string(Tipo, Texto),
    (   tipo_de(_, Tipo)
    ->  true
    ;   error_sipa("El tipo de curso '~w' no existe.", [Texto])
    ),
    findall(k(N, Ci, C), ( tipo_de(C, Tipo), nivel_de(C, N), ciclo_de(C, Ci) ), L0),
    msort(L0, L),
    member(k(_, _, C), L),
    fila_curso(C, Fila).

%   Fila: [Etiqueta, Valor]
consulta_requisitos_curso(CursoT, Fila) :-
    curso_valido(CursoT, C),
    texto_curso(C, TCurso),
    findall(R, requisito(C, R), Directos),
    cadena_requisitos(C, Cadena),
    subtract(Cadena, Directos, Indirectos),
    findall(K, correquisito(C, K), Correqs),
    cursos_que_desbloquea(C, Desbloquea),
    maplist(texto_lista, [Directos, Indirectos, Correqs, Desbloquea],
            [TD, TI, TC, TB]),
    texto_horarios(C, TH),
    emitir([ ['Curso', TCurso],
             ['Requisitos directos', TD],
             ['Requisitos indirectos', TI],
             ['Correquisitos (ficticios)', TC],
             ['Es requisito de', TB],
             ['Horario (ficticio)', TH] ], Fila).

texto_horarios(C, Texto) :-
    findall(T, ( grupo_de(C, G), texto_grupo(C, G, T) ), Grupos),
    (   Grupos == []
    ->  Texto = 'No se oferta este ciclo'
    ;   atomic_list_concat(Grupos, '; ', Texto)
    ).

% =====================================================================
% 4. Cursos disponibles (con explicacion)
% =====================================================================

%   Fila: [Codigo, Nombre, Creditos, PorQue]   en orden de prioridad
consulta_disponibles(CarneT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    cursos_priorizados(Carne, Cursos),
    member(C, Cursos),
    texto_codigo(C, Cod),
    nombre_de(C, Nombre),
    creditos_de(C, Cr),
    explicar_disponible(Carne, C, PorQue),
    responder([Cod, Nombre, Cr, PorQue], Fila).

% =====================================================================
% 5. Que me falta para llevar X
% =====================================================================

%   Fila: [Etiqueta, Valor]
consulta_que_falta(CarneT, CursoT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    curso_valido(CursoT, C),
    texto_curso(C, TCurso),
    filas_que_falta(Carne, C, Filas),
    emitir([['Curso', TCurso]|Filas], Fila).

filas_que_falta(Carne, C, [['Estado', 'YA APROBADO']]) :-
    aprobado(Carne, C), !.
filas_que_falta(Carne, C, [['Estado', 'DISPONIBLE'], ['Por que', PorQue]]) :-
    disponible(Carne, C), !,
    explicar_disponible(Carne, C, PorQue).
filas_que_falta(Carne, C, [ ['Estado', 'NO DISPONIBLE'],
                            ['Por que', PorQue],
                            ['Faltan (directos)', TDirectos],
                            ['Faltan (cadena completa, con correquisitos)', TCadena],
                            ['Minimo de ciclos', NEtapas] ]) :-
    explicar_no_disponible(Carne, C, PorQue),
    findall(R, requisito_faltante(Carne, C, R), Directos),
    cursos_necesarios(Carne, C, Necesarios0),
    delete(Necesarios0, C, Necesarios),
    texto_lista(Directos, TDirectos),
    texto_lista(Necesarios, TCadena),
    plan_por_etapas(Carne, C, Etapas),
    length(Etapas, NEtapas).

% =====================================================================
% 6. Ruta de avance hacia un curso meta
% =====================================================================

%   Fila: [Etiqueta, Valor]
consulta_ruta(CarneT, MetaT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    curso_valido(MetaT, Meta),
    texto_codigo(Meta, CodMeta),
    (   aprobado(Carne, Meta)
    ->  error_sipa("~w ya esta aprobado: no necesita ruta.", [CodMeta])
    ;   true
    ),
    (   plan_por_etapas(Carne, Meta, Etapas)
    ->  true
    ;   error_sipa("No se pudo construir un plan hacia ~w.", [CodMeta])
    ),
    filas_etapas(Etapas, 1, FilasEtapas),
    length(Etapas, NEtapas),
    filas_rutas(Carne, Meta, FilasRutas),
    texto_curso(Meta, TMeta),
    append([ [['Meta', TMeta]],
             FilasEtapas,
             [['Minimo de ciclos', NEtapas]],
             FilasRutas ], Filas),
    emitir(Filas, Fila).

% filas_etapas(+Etapas, +Numero, -Filas): una fila por etapa.
filas_etapas([], _, []).
filas_etapas([E|Es], N, [[Etiqueta, Texto]|Filas]) :-
    format(atom(Etiqueta), "Etapa ~w", [N]),
    texto_lista(E, L),
    suma_creditos(E, Cr),
    format(atom(Texto), "~w (~w creditos)", [L, Cr]),
    N1 is N + 1,
    filas_etapas(Es, N1, Filas).

% Cadenas alternativas (varias soluciones de ruta_hacia/3).
filas_rutas(Carne, Meta, Filas) :-
    max_rutas(Max),
    findall(R, limit(Max, ruta_hacia(Carne, Meta, R)), Rutas),
    numerar_rutas(Rutas, 1, FilasRutas),
    (   Rutas = [Primera|_]
    ->  explicar_ruta(Carne, Primera, Explicacion),
        append(FilasRutas, [['Por que (ruta 1)', Explicacion]], Filas)
    ;   Filas = FilasRutas
    ).

numerar_rutas([], _, []).
numerar_rutas([R|Rs], N, [[Etiqueta, Texto]|Filas]) :-
    format(atom(Etiqueta), "Ruta ~w", [N]),
    maplist(texto_codigo, R, Codigos),
    atomic_list_concat(Codigos, ' -> ', Texto),
    N1 is N + 1,
    numerar_rutas(Rs, N1, Filas).

% =====================================================================
% 7. Choques de horario de una seleccion
% =====================================================================

%   Fila: [Etiqueta, Valor]
consulta_choques(SeleccionT, Fila) :-
    seleccion_valida(SeleccionT, Cursos),
    partition(ofertado, Cursos, Ofertados, NoOfertados),
    findall(['Sin horario', T],
            ( member(C, NoOfertados), texto_codigo(C, Cod),
              format(atom(T), "~w no se oferta este ciclo.", [Cod]) ),
            FilasSinHorario),
    filas_choques(Ofertados, FilasChoques),
    filas_asignacion(Ofertados, FilasAsignacion),
    append([FilasSinHorario, FilasChoques, FilasAsignacion], Filas),
    emitir(Filas, Fila).

filas_choques(Cursos, Filas) :-
    findall(['Choque', T],
            ( append(_, [C1|Resto], Cursos), member(C2, Resto),
              choque_grupos(C1, G1, C2, G2),
              explicar_choque(C1-G1, C2-G2, T) ),
            Filas0),
    (   Filas0 == []
    ->  Filas = [['Resultado', 'No hay choques entre los cursos seleccionados.']]
    ;   Filas = Filas0
    ).

filas_asignacion([], []) :- !.
filas_asignacion(Cursos, Filas) :-
    (   asignar_grupos(Cursos, Asignacion)
    ->  texto_combinacion(Asignacion, T),
        creditos_combinacion(Asignacion, Cr),
        Filas = [['Grupos sin choque', T], ['Creditos', Cr]]
    ;   Filas = [['Sin solucion',
                  'No existe una combinacion de grupos sin choque para esta seleccion.']]
    ).

% =====================================================================
% 8. Recomendar combinaciones
% =====================================================================

%   Modalidad: "ciclo" (tope maximo 18) o "anual" (tope maximo 36)
%   Fila: [Etiqueta, Valor]
consulta_recomendar(CarneT, ModalidadT, TopeT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    texto_limpio(ModalidadT, Modalidad0),
    string_lower(Modalidad0, Modalidad),
    filas_recomendacion(Modalidad, Carne, TopeT, Filas),
    emitir(Filas, Fila).

filas_recomendacion("ciclo", Carne, TopeT, Filas) :- !,
    tope_creditos_ciclo(Max),
    entero_en_rango(TopeT, 1, Max, 'El tope de creditos por ciclo', Tope),
    max_opciones_recomendacion(N),
    recomendar(Carne, Tope, N, Opciones),
    (   Opciones = [Primera|_]
    ->  true
    ;   error_sipa("No hay cursos disponibles ofertados que quepan en ~w creditos.", [Tope])
    ),
    filas_opciones(Opciones, 1, FilasOpciones),
    filas_porque(Carne, Primera, 'opcion 1', FilasPorque),
    append(FilasOpciones, FilasPorque, Filas).
filas_recomendacion("anual", Carne, TopeT, Filas) :- !,
    tope_creditos_ciclo(MaxCiclo),
    tope_creditos_anual(MaxAnual),
    entero_en_rango(TopeT, 1, MaxAnual, 'El tope de creditos anual', Tope),
    (   recomendar_anual(Carne, MaxCiclo, Tope, [Ciclo1, Ciclo2])
    ->  true
    ;   error_sipa("No hay cursos disponibles ofertados que quepan en ~w creditos.", [Tope])
    ),
    fila_ciclo('Ciclo 1', Ciclo1, F1),
    fila_ciclo('Ciclo 2', Ciclo2, F2),
    creditos_combinacion(Ciclo1, Cr1),
    creditos_combinacion(Ciclo2, Cr2),
    Total is Cr1 + Cr2,
    format(atom(TTotal), "~w de ~w creditos permitidos", [Total, Tope]),
    filas_porque(Carne, Ciclo1, 'ciclo 1', FilasPorque),
    append([F1, F2, ['Total anual', TTotal]], FilasPorque, Filas).
filas_recomendacion(Modalidad, _, _, _) :-
    error_sipa("Modalidad '~w' no valida: use ciclo o anual.", [Modalidad]).

filas_opciones([], _, []).
filas_opciones([O|Os], N, [Fila|Filas]) :-
    format(atom(Etiqueta), "Opcion ~w", [N]),
    fila_ciclo(Etiqueta, O, Fila),
    N1 is N + 1,
    filas_opciones(Os, N1, Filas).

fila_ciclo(Etiqueta, [], [Etiqueta, 'Sin cursos (tope alcanzado o nada disponible)']) :- !.
fila_ciclo(Etiqueta0, Combinacion, [Etiqueta, Texto]) :-
    creditos_combinacion(Combinacion, Cr),
    format(atom(Etiqueta), "~w (~w cr)", [Etiqueta0, Cr]),
    texto_combinacion(Combinacion, Texto).

filas_porque(Carne, Combinacion, Cual, Filas) :-
    findall([Etiqueta, PorQue],
            ( member(C-_, Combinacion),
              texto_codigo(C, Cod),
              format(atom(Etiqueta), "Por que ~w (~w)", [Cod, Cual]),
              explicar_recomendacion(Carne, C, PorQue) ),
            Filas).

% =====================================================================
% 9. Avance de carrera
% =====================================================================

%   Fila: [Etiqueta, Valor]
consulta_avance(CarneT, Fila) :-
    estudiante_registrado(CarneT, Carne),
    estudiante(Carne, Nombre),
    format(atom(TEst), "~w (~w)", [Nombre, Carne]),
    explicar_avance(Carne, Lineas),
    findall([E, T], member(E-T, Lineas), Filas),
    emitir([['Estudiante', TEst]|Filas], Fila).

% =====================================================================
% 11-12. Sesion y base de conocimientos
% =====================================================================

consulta_guardar(Fila) :-
    persistir,
    ruta_registros(Ruta),
    aggregate_all(count, estudiante(_, _), N),
    format(atom(Msg), "Se guardaron ~w estudiante(s) en ~w.", [N, Ruta]),
    responder([Msg], Fila).

consulta_cargar(Fila) :-
    ruta_registros(Ruta),
    cargar_registros(Ruta),
    aggregate_all(count, estudiante(_, _), N),
    aggregate_all(count, aprobado(_, _), NA),
    format(atom(Msg), "Se cargaron ~w estudiante(s) y ~w curso(s) aprobado(s).", [N, NA]),
    responder([Msg], Fila).

%!  consulta_recargar_base(-Fila)
%   Recarga los archivos .pl modificados (make/0) sin reiniciar el
%   programa ni recompilar C. Guarda antes y recarga despues los
%   estudiantes, por si tambien se recargo estudiantes.pl.
consulta_recargar_base(Fila) :-
    persistir,
    make,
    ruta_registros(Ruta),
    cargar_registros(Ruta),
    aggregate_all(count, curso(_, _, _, _, _, _), NC),
    aggregate_all(count, requisito(_, _), NR),
    format(atom(Msg),
           "Base de conocimientos recargada: ~w cursos y ~w requisitos.", [NC, NR]),
    responder([Msg], Fila).
