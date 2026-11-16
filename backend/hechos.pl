% hechos.pl - Plan de estudios OFICIAL
% Ingenieria en Sistemas de Informacion, UNA (P.UNA-2498-21).
% Bachillerato con salida lateral de Diplomado en Programacion de
% Aplicaciones Informaticas. Fuente: Escuela de Informatica UNA.
%
% Responsabilidad: SOLO hechos del plan oficial. Los datos se copiaron
% tal cual del enunciado (no se agregaron ni quitaron cursos/requisitos).
% Depende de: nada (capa mas baja).
%
% Los datos inventados (correquisitos, horarios) estan en datos_ficticios.pl.

:- module(hechos, [
    curso/6,                        % curso(Codigo, Nombre, Creditos, Nivel, Ciclo, Tipo)
    requisito/2,                    % requisito(Curso, CursoRequerido)
    creditos_diplomado/1,
    creditos_bachillerato/1,
    optativas_requeridas/1,
    min_optativas_disciplinarias/1,
    area_general/2
]).

% curso(Codigo, Nombre, Creditos, Nivel, Ciclo, Tipo).
% Tipo: obligatorio | general | optativo_disciplinario | optativo_libre
% Nivel/Ciclo = 0 para optativos (no tienen ubicación fija).

% ---------- I NIVEL ----------
% I Ciclo (17 créditos)
curso(eif200, 'Fundamentos de Informática',            3, 1, 1, obligatorio).
curso(mat030, 'Matemática para Informática',           4, 1, 1, obligatorio).
curso(eg1,    'Estudios Generales I',                  3, 1, 1, general).
curso(eg2,    'Estudios Generales II',                 3, 1, 1, general).
curso(lix410, 'Inglés Integrado I',                    4, 1, 1, obligatorio).
% II Ciclo (18 créditos)
curso(eif201, 'Programación I',                        4, 1, 2, obligatorio).
curso(mat002, 'Cálculo I',                             4, 1, 2, obligatorio).
curso(eg3,    'Estudios Generales III',                3, 1, 2, general).
curso(eg4,    'Estudios Generales IV',                 3, 1, 2, general).
curso(lix411, 'Inglés Integrado II',                   4, 1, 2, obligatorio).

% ---------- II NIVEL ----------
% I Ciclo (18 créditos)
curso(eif202, 'Soporte Técnico',                       3, 2, 1, obligatorio).
curso(eif203, 'Estructuras Discretas para Informática',3, 2, 1, obligatorio).
curso(eif204, 'Programación II',                       4, 2, 1, obligatorio).
curso(mat005, 'Álgebra Lineal',                        4, 2, 1, obligatorio).
curso(lix412, 'Inglés Integrado III',                  4, 2, 1, obligatorio).
% II Ciclo (17 créditos)
curso(eif205, 'Arquitectura de Computadoras',          3, 2, 2, obligatorio).
curso(eif206, 'Programación III',                      4, 2, 2, obligatorio).
curso(eif207, 'Estructuras de Datos',                  4, 2, 2, obligatorio).
curso(eif404, 'La Organización y su Entorno',          3, 2, 2, obligatorio).
curso(mat006, 'Probabilidad y Estadística para Informática', 3, 2, 2, obligatorio).

% ---------- III NIVEL ----------
% I Ciclo (18 créditos)  -> al completar hasta aquí: DIPLOMADO (88 créditos)
curso(eif208, 'Comunicaciones y Redes de Computadores',3, 3, 1, obligatorio).
curso(eif209, 'Programación IV',                       4, 3, 1, obligatorio).
curso(eif210, 'Ingeniería de Sistemas I',              4, 3, 1, obligatorio).
curso(eif211, 'Diseño e Implementación de Bases de Datos', 4, 3, 1, obligatorio).
curso(eif212, 'Sistemas Operativos',                   3, 3, 1, obligatorio).
% II Ciclo (18 créditos)
curso(eif400, 'Paradigmas de Programación',            4, 3, 2, obligatorio).
curso(eif401, 'Ingeniería de Sistemas II',             4, 3, 2, obligatorio).
curso(eif402, 'Administración de Bases de Datos',      4, 3, 2, obligatorio).
curso(eif407, 'Liderazgo y Organización',              3, 3, 2, obligatorio).
curso(eif412, 'Investigación de Operaciones y sus Aplicaciones', 3, 3, 2, obligatorio).

% ---------- IV NIVEL ----------
% I Ciclo (17 créditos = 11 + 2 optativas de 3)
curso(eif406, 'Ingeniería de Sistemas III',            4, 4, 1, obligatorio).
curso(eif411, 'Diseño y Programación de Plataformas Móviles', 4, 4, 1, obligatorio).
curso(eif413, 'Métodos de Investigación Científica en Informática', 3, 4, 1, obligatorio).
% II Ciclo (17 créditos = 11 + 2 optativas de 3) -> BACHILLERATO (140 créditos)
curso(eif408, 'Proyectos y su Aplicación en la Organización (PPS)', 5, 4, 2, obligatorio).
curso(eif409, 'Aplicaciones Informáticas Globales',    4, 4, 2, obligatorio).
curso(eif410, 'Informática y Sociedad',                2, 4, 2, obligatorio).

% ---------- OPTATIVOS DISCIPLINARIOS ----------
curso(eif100o, 'Dispositivos para Comunicaciones de Datos', 3, 0, 0, optativo_disciplinario).
curso(eif420o, 'Inteligencia Artificial',              3, 0, 0, optativo_disciplinario).
curso(eif421o, 'Análisis de Algoritmos',               3, 0, 0, optativo_disciplinario).
curso(eif422o, 'Diseño de Interfaces de Usuario',      3, 0, 0, optativo_disciplinario).
curso(eif424o, 'Desarrollo de Aplicaciones Educativas',3, 0, 0, optativo_disciplinario).
curso(eif425o, 'Diseño de Ambientes Multimediales',    3, 0, 0, optativo_disciplinario).
curso(eif426o, 'Diseño de Ambientes de Aprendizaje',   3, 0, 0, optativo_disciplinario).
curso(eif427o, 'Robótica',                             3, 0, 0, optativo_disciplinario).
curso(eif428o, 'Fundamentos de Programación Web',      3, 0, 0, optativo_disciplinario).
curso(eif431o, 'Administración de Servidores Basados en Software Libre', 3, 0, 0, optativo_disciplinario).
curso(eif432o, 'Introducción a la Programación Paralela en Arquitecturas Multinúcleo', 3, 0, 0, optativo_disciplinario).
curso(eif433o, 'Contexto, Desarrollo y Aplicación de Software Libre y de Código Abierto', 3, 0, 0, optativo_disciplinario).
curso(eif434o, 'Minería de Datos I',                   3, 0, 0, optativo_disciplinario).
curso(eif435o, 'Minería de Datos II',                  3, 0, 0, optativo_disciplinario).
curso(eig416o, 'Gestión de Tecnología Educativa',      3, 0, 0, optativo_disciplinario).
curso(eif436o, 'Gráficos por Computadora',             3, 0, 0, optativo_disciplinario).
curso(eif440o, 'Seguridad Informática',                3, 0, 0, optativo_disciplinario).
curso(eif441o, 'Soporte Técnico Avanzado',             3, 0, 0, optativo_disciplinario).
curso(eif442o, 'Entornos de Programación para Videojuegos', 3, 0, 0, optativo_disciplinario).
curso(eif443o, 'Diseño y Programación de Videojuegos en 3D', 3, 0, 0, optativo_disciplinario).
curso(eif423o, 'Introducción a la Programación de Dispositivos Móviles', 3, 0, 0, optativo_disciplinario).
curso(eif439o, 'Uso Estratégico del Comercio Electrónico', 3, 0, 0, optativo_disciplinario).
curso(eif101o, 'Redes Avanzadas I',                    3, 0, 0, optativo_disciplinario).

% ---------- OPTATIVOS LIBRES (sin requisitos) ----------
curso(eif429o, 'Introducción a la Creación de Empresas', 3, 0, 0, optativo_libre).
curso(eif430o, 'Las TICs en el Ámbito Jurídico de Costa Rica', 3, 0, 0, optativo_libre).
curso(eif437o, 'Propiedad Intelectual y su Aplicación Práctica', 3, 0, 0, optativo_libre).
curso(eif438o, 'Gobierno Electrónico y su Regulación en Costa Rica', 3, 0, 0, optativo_libre).
curso(eig417o, 'Liderazgo y Organizaciones',           3, 0, 0, optativo_libre).
curso(eig418o, 'La Organización y su Entorno (optativo)', 3, 0, 0, optativo_libre).
curso(eif444o, 'Introducción a la Innovación Tecnológica', 3, 0, 0, optativo_libre).
curso(eif102o, 'Introducción al Análisis de Datos para Otras Carreras', 3, 0, 0, optativo_libre).

% ---------- REQUISITOS: requisito(Curso, CursoRequerido) ----------
% "Ingreso a carrera" = sin requisitos (eif200, mat030, lix410, eg1-eg4, optativos libres).
requisito(eif201, eif200).  requisito(eif201, mat030).
requisito(mat002, mat030).
requisito(lix411, lix410).
requisito(eif202, eif200).
requisito(eif203, eif200).  requisito(eif203, mat030).
requisito(eif204, eif201).
requisito(mat005, mat002).
requisito(lix412, lix411).
requisito(eif205, eif201).  requisito(eif205, eif202).
requisito(eif206, eif204).  requisito(eif206, mat002).
requisito(eif207, eif203).  requisito(eif207, eif204).
requisito(eif404, eif201).
requisito(mat006, mat002).  requisito(mat006, eif203).
requisito(eif208, eif205).
requisito(eif209, eif206).
requisito(eif210, eif206).
requisito(eif211, eif206).  requisito(eif211, eif207).
requisito(eif212, eif204).  requisito(eif212, eif205).
requisito(eif400, eif206).
requisito(eif401, eif210).
requisito(eif402, eif212).  requisito(eif402, eif211).
requisito(eif407, eif404).
requisito(eif412, eif206).  requisito(eif412, mat005).  requisito(eif412, mat006).
requisito(eif406, eif401).
requisito(eif411, eif209).
requisito(eif413, mat006).
requisito(eif408, eif209).  requisito(eif408, eif401).  requisito(eif408, eif402).
requisito(eif409, eif209).  requisito(eif409, eif401).  requisito(eif409, eif402).
requisito(eif410, eif401).
% Optativos disciplinarios
requisito(eif100o, eif208).
requisito(eif420o, eif207).
requisito(eif421o, eif207). requisito(eif421o, mat002).
requisito(eif422o, eif206).
requisito(eif424o, eif204). requisito(eif424o, eif206).
requisito(eif425o, eif204). requisito(eif425o, eif206).
requisito(eif426o, eif204). requisito(eif426o, eif206).
requisito(eif427o, eif204).
requisito(eif428o, eif206). requisito(eif428o, eif211).
requisito(eif431o, eif212). requisito(eif431o, eif402).
requisito(eif432o, eif207). requisito(eif432o, eif212).
requisito(eif433o, eif212). requisito(eif433o, eif211).
requisito(eif434o, eif402). requisito(eif434o, mat006).
requisito(eif435o, eif434o).
requisito(eig416o, eif425o).
requisito(eif436o, eif207). requisito(eif436o, mat005).
requisito(eif440o, eif208). requisito(eif440o, eif212).
requisito(eif441o, eif202).
requisito(eif442o, eif204). requisito(eif442o, mat002).
requisito(eif443o, eif204). requisito(eif443o, mat002).
requisito(eif423o, eif209).
requisito(eif439o, eif209). requisito(eif439o, eif211).
requisito(eif101o, eif208).

% ---------- REGLAS DE GRADUACIÓN DEL PLAN ----------
creditos_diplomado(88).      % I, II nivel completos + III nivel I ciclo
creditos_bachillerato(140).
optativas_requeridas(4).     % 2 en IV nivel I ciclo + 2 en IV nivel II ciclo
min_optativas_disciplinarias(2).
% Estudios generales: 4 cursos, uno por área.
area_general(eg1, ciencia_y_tecnologia).
area_general(eg2, cientifico_social).
area_general(eg3, filosofia_y_letras).
area_general(eg4, arte).
