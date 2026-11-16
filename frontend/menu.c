/*
 * menu.c - Menu principal, submenus y casos de uso
 *
 * Responsabilidad: control de flujo. Cada manejador pide los datos
 * (interfaz.c), valida su formato (validaciones.c), le pide a Prolog la
 * respuesta (conexion.h) y la manda a imprimir. NINGUNA decision del
 * dominio se toma aqui: disponibilidad, choques, rutas o recomendaciones
 * las deduce Prolog.
 *
 * Abierto/cerrado: los menus son tablas {numero, texto, manejador};
 * agregar una opcion es agregar una fila. Todos los manejadores tienen
 * la misma firma void (*)(void), asi que son intercambiables.
 */
#include "menu.h"

#include <limits.h>
#include <stddef.h>
#include <string.h>

#include "conexion.h"
#include "interfaz.h"
#include "validaciones.h"

#define TAM_ENTRADA      256
#define TAM_CARNE        16
#define TAM_CODIGO       16
#define MAX_NOMBRE       80
#define MAX_NIVEL_C      99     /* el maximo real lo valida Prolog */
#define MAX_TOPE_C       99     /* idem: el tope real lo aplica Prolog */
#define OPCION_SALIR     0
#define CANCELAR_AYUDA   "(Enter para cancelar)"

#define CANTIDAD(arreglo) ((int)(sizeof(arreglo) / sizeof((arreglo)[0])))

typedef void (*ManejadorOpcion)(void);

typedef struct {
    int             numero;
    const char     *texto;
    ManejadorOpcion manejador;    /* NULL = volver / salir */
} OpcionMenu;

/* Se activa si se acaba la entrada (EOF) para cerrar todos los menus. */
static int entrada_terminada = 0;

/* Estudiante elegido para el submenu de cursos aprobados. */
static char carne_actual[TAM_CARNE];

/* ================================================================== */
/* Utilidades de entrada y consulta (DRY)                              */
/* ================================================================== */

static int leer(const char *indicacion, char *destino, int tam)
{
    if (!interfaz_leer_linea(indicacion, destino, tam)) {
        entrada_terminada = 1;
        return 0;
    }
    return 1;
}

/* Ejecuta una consulta de Prolog, la muestra y libera el resultado.
   Devuelve el estado de la conexion. */
static int ejecutar_y_mostrar(const char *consulta,
                              const char *argumentos[], int cantidad,
                              const char *encabezados[], int columnas,
                              const char *sin_resultados)
{
    ResultadoConsulta resultado;
    int estado = conexion_consultar(consulta, argumentos, cantidad, &resultado);
    interfaz_mostrar_resultado(estado, &resultado, encabezados, columnas,
                               sin_resultados);
    conexion_liberar(&resultado);
    return estado;
}

static void mostrar_estudiantes(void)
{
    static const char *encabezados[] = { "Carne", "Nombre", "Creditos", "Avance" };
    ejecutar_y_mostrar("consulta_estudiantes", NULL, 0,
                       encabezados, CANTIDAD(encabezados),
                       "No hay estudiantes registrados.");
}

/* Pide un carne con formato valido (no verifica que exista). */
static int pedir_carne_nuevo(char *carne)
{
    for (;;) {
        if (!leer("Carne (9 digitos) " CANCELAR_AYUDA, carne, TAM_CARNE) ||
            carne[0] == '\0') {
            return 0;
        }
        if (validar_carne(carne)) {
            return 1;
        }
        interfaz_error("El carne debe tener exactamente 9 digitos.");
    }
}

/* Le pregunta a Prolog si el valor existe (consulta_existe_*) y muestra
   el dato encontrado o el motivo del error. Devuelve 1 si existe. */
static int confirmar_existencia(const char *consulta, const char *valor,
                                const char *etiqueta)
{
    ResultadoConsulta resultado;
    const char *argumentos[] = { valor };
    int estado = conexion_consultar(consulta, argumentos, 1, &resultado);

    if (estado == CONEXION_OK) {
        const FilaResultado *fila = &resultado.filas[0];
        interfaz_dato(etiqueta, fila->columnas[0],
                      fila->cantidad > 1 ? fila->columnas[1] : NULL);
    } else {
        interfaz_error(resultado.mensaje_error);
    }
    conexion_liberar(&resultado);
    return estado == CONEXION_OK;
}

/* Pide el carne de un estudiante REGISTRADO: valida el formato en C y la
   existencia en Prolog. Con "?" lista los estudiantes. */
static int pedir_carne_registrado(char *carne)
{
    for (;;) {
        if (!leer("Carne (? = ver estudiantes) " CANCELAR_AYUDA, carne, TAM_CARNE) ||
            carne[0] == '\0') {
            return 0;
        }
        if (strcmp(carne, "?") == 0) {
            mostrar_estudiantes();
        } else if (!validar_carne(carne)) {
            interfaz_error("El carne debe tener exactamente 9 digitos.");
        } else if (confirmar_existencia("consulta_existe_estudiante", carne, "Estudiante")) {
            return 1;
        }
    }
}

/* Pide un codigo de curso: formato en C, existencia en Prolog. */
static int pedir_curso(const char *indicacion, char *codigo)
{
    for (;;) {
        if (!leer(indicacion, codigo, TAM_CODIGO) || codigo[0] == '\0') {
            return 0;
        }
        if (!validar_codigo_curso(codigo)) {
            interfaz_error("Formato de codigo invalido (ejemplos: EIF206, MAT002, EG1, EIF420O).");
        } else if (confirmar_existencia("consulta_existe_curso", codigo, "Curso")) {
            return 1;
        }
    }
}

/* Pide un entero en [minimo, maximo]; lo deja tambien como texto. */
static int pedir_entero(const char *indicacion, int minimo, int maximo,
                        char *texto, int tam)
{
    for (;;) {
        int valor;
        if (!leer(indicacion, texto, tam) || texto[0] == '\0') {
            return 0;
        }
        if (validar_entero(texto, minimo, maximo, &valor)) {
            return 1;
        }
        interfaz_error("Debe ingresar un numero entero valido.");
    }
}

/*
 * Pide a Prolog una lista de opciones (columna 0 = valor que se envia,
 * columna 1 = detalle), la muestra numerada y devuelve el numero elegido
 * (0 si se cancela o falla). Siempre hay que liberar 'opciones'.
 */
static int elegir_opcion_de_prolog(const char *consulta, const char *indicacion,
                                   ResultadoConsulta *opciones)
{
    char eleccion[TAM_CODIGO];
    int indice = 0;

    if (conexion_consultar(consulta, NULL, 0, opciones) != CONEXION_OK) {
        interfaz_error("No se pudieron obtener las opciones desde Prolog.");
        return 0;
    }
    for (int i = 0; i < opciones->cantidad; i++) {
        interfaz_opcion_detalle(i + 1, opciones->filas[i].columnas[0],
                                opciones->filas[i].columnas[1]);
    }
    if (!pedir_entero(indicacion, 1, opciones->cantidad, eleccion, sizeof(eleccion)) ||
        !validar_entero(eleccion, 1, opciones->cantidad, &indice)) {
        return 0;
    }
    return indice;
}

/* ================================================================== */
/* Motor generico de menus (tabla de opciones)                         */
/* ================================================================== */

static const OpcionMenu *buscar_opcion(const OpcionMenu opciones[], int cantidad,
                                       int numero)
{
    for (int i = 0; i < cantidad; i++) {
        if (opciones[i].numero == numero) {
            return &opciones[i];
        }
    }
    return NULL;
}

static void mostrar_opciones(const char *titulo, const OpcionMenu opciones[],
                             int cantidad)
{
    interfaz_titulo(titulo);
    for (int i = 0; i < cantidad; i++) {
        interfaz_opcion(opciones[i].numero, opciones[i].texto);
    }
}

/* Repite: mostrar, leer opcion, despachar, hasta Volver/Salir o EOF. */
static void ejecutar_menu(const char *titulo, const OpcionMenu opciones[],
                          int cantidad, int pausar)
{
    char entrada[TAM_ENTRADA];

    while (!entrada_terminada) {
        const OpcionMenu *opcion;
        int numero;

        mostrar_opciones(titulo, opciones, cantidad);
        if (!leer("Opcion", entrada, sizeof(entrada))) {
            return;
        }
        if (!validar_entero(entrada, 0, INT_MAX, &numero) ||
            (opcion = buscar_opcion(opciones, cantidad, numero)) == NULL) {
            interfaz_error("Opcion invalida. Elija un numero de la lista.");
            continue;
        }
        if (opcion->manejador == NULL) {
            return;
        }
        opcion->manejador();
        if (pausar && !entrada_terminada) {
            interfaz_pausa();
        }
    }
}

/* ================================================================== */
/* 1. Registrar estudiante                                             */
/* ================================================================== */

static void opcion_registrar_estudiante(void)
{
    char carne[TAM_CARNE];
    char nombre[TAM_ENTRADA];
    const char *argumentos[2];

    interfaz_titulo("Registrar estudiante");
    if (!pedir_carne_nuevo(carne)) {
        return;
    }
    if (!leer("Nombre completo", nombre, sizeof(nombre))) {
        return;
    }
    if (!validar_texto(nombre, MAX_NOMBRE)) {
        interfaz_error("El nombre no puede estar vacio ni superar 80 caracteres.");
        return;
    }
    argumentos[0] = carne;
    argumentos[1] = nombre;
    ejecutar_y_mostrar("consulta_registrar_estudiante", argumentos, 2,
                       NULL, 0, "");
}

/* ================================================================== */
/* 2. Cursos aprobados (submenu)                                       */
/* ================================================================== */

static void aprobados_ver(void)
{
    static const char *encabezados[] = { "Codigo", "Nombre", "Cr", "Ubicacion", "Requisitos" };
    const char *argumentos[] = { carne_actual };
    ejecutar_y_mostrar("consulta_aprobados", argumentos, 1,
                       encabezados, CANTIDAD(encabezados),
                       "El estudiante no tiene cursos aprobados.");
}

/* Agrega o quita cursos uno tras otro hasta que el usuario de Enter. */
static void aprobados_modificar(const char *consulta)
{
    char codigo[TAM_CODIGO];
    const char *argumentos[2];

    argumentos[0] = carne_actual;
    argumentos[1] = codigo;
    while (pedir_curso("Codigo del curso (Enter para terminar)", codigo)) {
        ejecutar_y_mostrar(consulta, argumentos, 2, NULL, 0, "");
    }
}

static void aprobados_agregar(void) { aprobados_modificar("consulta_agregar_aprobado"); }
static void aprobados_quitar(void)  { aprobados_modificar("consulta_quitar_aprobado"); }

static const OpcionMenu MENU_APROBADOS[] = {
    { 1, "Ver cursos aprobados",     aprobados_ver },
    { 2, "Agregar cursos aprobados", aprobados_agregar },
    { 3, "Quitar cursos aprobados",  aprobados_quitar },
    { 0, "Volver",                   NULL }
};

static void opcion_cursos_aprobados(void)
{
    interfaz_titulo("Cursos aprobados");
    if (pedir_carne_registrado(carne_actual)) {
        ejecutar_menu("Cursos aprobados", MENU_APROBADOS,
                      CANTIDAD(MENU_APROBADOS), 0);
    }
}

/* ================================================================== */
/* 3. Plan de estudios (submenu)                                       */
/* ================================================================== */

static const char *ENCABEZADOS_PLAN[] = { "Codigo", "Nombre", "Cr", "Ubicacion", "Requisitos" };

static void plan_por_nivel(void)
{
    char nivel[TAM_CODIGO];
    const char *argumentos[] = { nivel };
    /* el rango de niveles lo valida Prolog (C no sabe cuantos hay) */
    if (pedir_entero("Nivel", 1, MAX_NIVEL_C, nivel, sizeof(nivel))) {
        ejecutar_y_mostrar("consulta_plan_nivel", argumentos, 1,
                           ENCABEZADOS_PLAN, CANTIDAD(ENCABEZADOS_PLAN),
                           "No hay cursos en ese nivel.");
    }
}

/* Los tipos los entrega Prolog: C no sabe cuales existen. */
static void plan_por_tipo(void)
{
    ResultadoConsulta tipos;
    int indice = elegir_opcion_de_prolog("consulta_tipos", "Tipo", &tipos);

    if (indice > 0) {
        const char *argumentos[] = { tipos.filas[indice - 1].columnas[0] };
        ejecutar_y_mostrar("consulta_plan_tipo", argumentos, 1,
                           ENCABEZADOS_PLAN, CANTIDAD(ENCABEZADOS_PLAN),
                           "No hay cursos de ese tipo.");
    }
    conexion_liberar(&tipos);
}

static void plan_requisitos_curso(void)
{
    char codigo[TAM_CODIGO];
    const char *argumentos[] = { codigo };
    if (pedir_curso("Codigo del curso " CANCELAR_AYUDA, codigo)) {
        ejecutar_y_mostrar("consulta_requisitos_curso", argumentos, 1,
                           NULL, 0, "");
    }
}

static const OpcionMenu MENU_PLAN[] = {
    { 1, "Cursos por nivel",                         plan_por_nivel },
    { 2, "Cursos por tipo",                          plan_por_tipo },
    { 3, "Requisitos y correquisitos de un curso",   plan_requisitos_curso },
    { 0, "Volver",                                   NULL }
};

static void opcion_plan_estudios(void)
{
    ejecutar_menu("Plan de estudios", MENU_PLAN, CANTIDAD(MENU_PLAN), 1);
}

/* ================================================================== */
/* 4-9. Consultas sobre un estudiante                                  */
/* ================================================================== */

static void opcion_disponibles(void)
{
    static const char *encabezados[] = { "Codigo", "Nombre", "Cr", "Por que esta disponible" };
    char carne[TAM_CARNE];
    const char *argumentos[] = { carne };

    interfaz_titulo("Cursos disponibles para matricular (en orden de prioridad)");
    if (pedir_carne_registrado(carne)) {
        ejecutar_y_mostrar("consulta_disponibles", argumentos, 1,
                           encabezados, CANTIDAD(encabezados),
                           "No hay cursos disponibles para este estudiante.");
    }
}

static void opcion_que_falta(void)
{
    char carne[TAM_CARNE];
    char codigo[TAM_CODIGO];
    const char *argumentos[] = { carne, codigo };

    interfaz_titulo("Que me falta para llevar un curso");
    if (pedir_carne_registrado(carne) &&
        pedir_curso("Curso que quiere llevar " CANCELAR_AYUDA, codigo)) {
        ejecutar_y_mostrar("consulta_que_falta", argumentos, 2, NULL, 0, "");
    }
}

static void opcion_ruta(void)
{
    char carne[TAM_CARNE];
    char codigo[TAM_CODIGO];
    const char *argumentos[] = { carne, codigo };

    interfaz_titulo("Ruta de avance hacia un curso meta");
    if (pedir_carne_registrado(carne) &&
        pedir_curso("Curso meta " CANCELAR_AYUDA, codigo)) {
        ejecutar_y_mostrar("consulta_ruta", argumentos, 2, NULL, 0, "");
    }
}

static void opcion_choques(void)
{
    char seleccion[TAM_ENTRADA];
    const char *argumentos[] = { seleccion };

    interfaz_titulo("Detectar choques de horario");
    if (!leer("Cursos separados por espacio o coma (ej: EIF206 EIF207)",
              seleccion, sizeof(seleccion)) || seleccion[0] == '\0') {
        return;
    }
    if (!validar_seleccion_cursos(seleccion)) {
        interfaz_error("Ingrese al menos 2 codigos de curso con formato valido.");
        return;
    }
    ejecutar_y_mostrar("consulta_choques", argumentos, 1, NULL, 0, "");
}

/* Las modalidades y sus topes los entrega Prolog: C no conoce los
   limites de creditos. */
static void opcion_recomendar(void)
{
    ResultadoConsulta modalidades;
    char carne[TAM_CARNE];
    char tope[TAM_CODIGO];
    int indice;

    interfaz_titulo("Recomendar combinaciones de cursos");
    if (!pedir_carne_registrado(carne)) {
        return;
    }
    indice = elegir_opcion_de_prolog("consulta_modalidades", "Modalidad", &modalidades);
    if (indice > 0 && pedir_entero("Tope de creditos", 1, MAX_TOPE_C, tope, sizeof(tope))) {
        const char *argumentos[] = { carne, modalidades.filas[indice - 1].columnas[0], tope };
        ejecutar_y_mostrar("consulta_recomendar", argumentos, 3, NULL, 0,
                           "No hay combinaciones posibles.");
    }
    conexion_liberar(&modalidades);
}

static void opcion_avance(void)
{
    char carne[TAM_CARNE];
    const char *argumentos[] = { carne };

    interfaz_titulo("Avance de carrera");
    if (pedir_carne_registrado(carne)) {
        ejecutar_y_mostrar("consulta_avance", argumentos, 1, NULL, 0, "");
    }
}

/* ================================================================== */
/* 10. Reporte de planificacion                                        */
/* ================================================================== */

static void opcion_reporte(void)
{
    char carne[TAM_CARNE];
    const char *argumentos[] = { carne };

    interfaz_titulo("Generar reporte de planificacion");
    if (pedir_carne_registrado(carne)) {
        ejecutar_y_mostrar("consulta_reporte", argumentos, 1, NULL, 0, "");
    }
}

/* ================================================================== */
/* 11-12. Sesion y base de conocimientos                               */
/* ================================================================== */

static void sesion_guardar(void) { ejecutar_y_mostrar("consulta_guardar", NULL, 0, NULL, 0, ""); }
static void sesion_cargar(void)  { ejecutar_y_mostrar("consulta_cargar", NULL, 0, NULL, 0, ""); }

static const OpcionMenu MENU_SESION[] = {
    { 1, "Guardar estudiantes en datos/registros.txt",  sesion_guardar },
    { 2, "Cargar estudiantes desde datos/registros.txt", sesion_cargar },
    { 0, "Volver",                                       NULL }
};

static void opcion_sesion(void)
{
    ejecutar_menu("Guardar / cargar sesion", MENU_SESION, CANTIDAD(MENU_SESION), 1);
}

static void opcion_recargar(void)
{
    interfaz_titulo("Recargar base de conocimientos");
    ejecutar_y_mostrar("consulta_recargar_base", NULL, 0, NULL, 0, "");
}

/* ================================================================== */
/* Menu principal                                                      */
/* ================================================================== */

static const OpcionMenu MENU_PRINCIPAL[] = {
    { 1,  "Registrar estudiante",                  opcion_registrar_estudiante },
    { 2,  "Registrar / quitar cursos aprobados",   opcion_cursos_aprobados },
    { 3,  "Consultar plan de estudios",            opcion_plan_estudios },
    { 4,  "Cursos disponibles para matricular",    opcion_disponibles },
    { 5,  "Que me falta para llevar un curso",     opcion_que_falta },
    { 6,  "Ruta de avance hacia un curso meta",    opcion_ruta },
    { 7,  "Detectar choques de horario",           opcion_choques },
    { 8,  "Recomendar combinaciones de cursos",    opcion_recomendar },
    { 9,  "Avance de carrera",                     opcion_avance },
    { 10, "Generar reporte de planificacion",      opcion_reporte },
    { 11, "Guardar / cargar sesion",               opcion_sesion },
    { 12, "Recargar base de conocimientos",        opcion_recargar },
    { OPCION_SALIR, "Salir",                       NULL }
};

void menu_ejecutar(void)
{
    ejecutar_menu("CONSEJERO ACADEMICO INTELIGENTE - Menu principal",
                  MENU_PRINCIPAL, CANTIDAD(MENU_PRINCIPAL), 1);
}
