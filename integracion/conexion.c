/*
 * conexion.c - Implementacion del puente C <-> Prolog
 *
 * Integracion elegida: Prolog INCRUSTADO con la API de C de SWI-Prolog
 * (PL_initialise, PL_predicate, PL_open_query, PL_next_solution,
 * PL_exception, PL_close_query, PL_cleanup). Ver justificacion en
 * documentacion/diseno.md (decision D1).
 *
 * Responsabilidad unica: hablar con Prolog. No conoce el dominio: no sabe
 * que es un curso ni un estudiante; solo arma metas y convierte las
 * soluciones (listas de Prolog) a estructuras de C.
 */
#include "conexion.h"

#include <SWI-Prolog.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PREFIJO_CONSULTA   "consulta_"
#define MODULO_CONSULTAS   "consultas"
#define MAX_ARGUMENTOS     8
#define FILAS_INICIALES    16

/* Rutas donde se busca el back-end (relativas a la raiz del proyecto). */
static const char *RUTAS_BACKEND[] = {
    "backend/main.pl",       /* ejecutado desde la raiz (make run)   */
    "../backend/main.pl",    /* ejecutado desde build/               */
    NULL
};

static int prolog_iniciado = 0;

/* ------------------------------------------------------------------ */
/* Utilidades internas                                                 */
/* ------------------------------------------------------------------ */

static void copiar_mensaje(char *destino, int tam, const char *texto)
{
    if (destino != NULL && tam > 0) {
        snprintf(destino, (size_t)tam, "%s", texto);
    }
}

/* Copia un texto a memoria propia (strdup no es C11 estandar). */
static char *copiar_texto(const char *texto)
{
    size_t largo = strlen(texto) + 1;
    char *copia = malloc(largo);
    if (copia != NULL) {
        memcpy(copia, texto, largo);
    }
    return copia;
}

static int archivo_existe(const char *ruta)
{
    FILE *archivo = fopen(ruta, "r");
    if (archivo == NULL) {
        return 0;
    }
    fclose(archivo);
    return 1;
}

static const char *buscar_backend(void)
{
    for (int i = 0; RUTAS_BACKEND[i] != NULL; i++) {
        if (archivo_existe(RUTAS_BACKEND[i])) {
            return RUTAS_BACKEND[i];
        }
    }
    return NULL;
}

/* Llama a una meta de un argumento atomico, p. ej. consult('ruta'). */
static int llamar_con_atomo(const char *predicado, const char *modulo,
                            const char *atomo)
{
    term_t argumento = PL_new_term_ref();
    predicate_t pred = PL_predicate(predicado, 1, modulo);

    if (!PL_put_atom_chars(argumento, atomo)) {
        return 0;
    }
    return PL_call_predicate(NULL, PL_Q_CATCH_EXCEPTION, pred, argumento);
}

/* ------------------------------------------------------------------ */
/* Inicio y cierre                                                     */
/* ------------------------------------------------------------------ */

int conexion_iniciar(const char *programa, char *mensaje, int tam_mensaje)
{
    char *argv[] = { (char *)programa, "-q", NULL };
    const char *ruta;

    if (!PL_initialise(2, argv)) {
        copiar_mensaje(mensaje, tam_mensaje,
                       "No se pudo iniciar SWI-Prolog (revise que su carpeta bin este en el PATH).");
        return CONEXION_ERROR;
    }
    prolog_iniciado = 1;

    ruta = buscar_backend();
    if (ruta == NULL) {
        copiar_mensaje(mensaje, tam_mensaje,
                       "No se encontro backend/main.pl. Ejecute el programa desde la raiz del proyecto.");
        return CONEXION_ERROR;
    }

    if (!llamar_con_atomo("consult", "user", ruta) ||
        !llamar_con_atomo("current_module", "user", MODULO_CONSULTAS)) {
        copiar_mensaje(mensaje, tam_mensaje,
                       "No se pudo cargar el back-end de Prolog (revise errores en los archivos .pl).");
        return CONEXION_ERROR;
    }
    return CONEXION_OK;
}

void conexion_cerrar(void)
{
    if (prolog_iniciado) {
        PL_cleanup(0);
        prolog_iniciado = 0;
    }
}

/* ------------------------------------------------------------------ */
/* Conversion de terminos Prolog -> estructuras C                      */
/* ------------------------------------------------------------------ */

/* Convierte una lista Prolog de textos en una FilaResultado. */
static int convertir_fila(term_t lista, FilaResultado *fila)
{
    term_t cola = PL_copy_term_ref(lista);
    term_t cabeza = PL_new_term_ref();
    size_t largo = 0;
    int i = 0;

    fila->cantidad = 0;
    fila->columnas = NULL;

    if (PL_skip_list(lista, 0, &largo) != PL_LIST) {
        return 0;
    }
    fila->columnas = calloc(largo > 0 ? largo : 1, sizeof(char *));
    if (fila->columnas == NULL) {
        return 0;
    }

    while (PL_get_list(cola, cabeza, cola)) {
        char *texto = NULL;
        if (!PL_get_chars(cabeza, &texto,
                          CVT_ALL | CVT_WRITE | BUF_STACK | REP_MB)) {
            return 0;
        }
        fila->columnas[i] = copiar_texto(texto);
        if (fila->columnas[i] == NULL) {
            return 0;
        }
        fila->cantidad = ++i;
    }
    return 1;
}

/* Agrega una fila al resultado, creciendo el arreglo si hace falta. */
static int agregar_fila(ResultadoConsulta *resultado, term_t lista,
                        int *capacidad)
{
    if (resultado->cantidad == *capacidad) {
        int nueva = (*capacidad == 0) ? FILAS_INICIALES : *capacidad * 2;
        FilaResultado *filas = realloc(resultado->filas,
                                       (size_t)nueva * sizeof(FilaResultado));
        if (filas == NULL) {
            return 0;
        }
        resultado->filas = filas;
        *capacidad = nueva;
    }
    if (!convertir_fila(lista, &resultado->filas[resultado->cantidad])) {
        resultado->cantidad++;            /* para liberar lo parcial */
        return 0;
    }
    resultado->cantidad++;
    return 1;
}

/* Extrae el texto de una excepcion: error_sipa(Mensaje) u otra. */
static void describir_excepcion(term_t excepcion, char *destino, int tam)
{
    term_t mensaje = PL_new_term_ref();
    functor_t error_sipa = PL_new_functor(PL_new_atom("error_sipa"), 1);
    char *texto = NULL;

    if (PL_is_functor(excepcion, error_sipa) &&
        PL_get_arg(1, excepcion, mensaje) &&
        PL_get_chars(mensaje, &texto, CVT_ALL | CVT_WRITE | BUF_STACK | REP_MB)) {
        copiar_mensaje(destino, tam, texto);
        return;
    }
    if (PL_get_chars(excepcion, &texto, CVT_WRITE | BUF_STACK | REP_MB)) {
        snprintf(destino, (size_t)tam, "Error interno de Prolog: %s", texto);
        return;
    }
    copiar_mensaje(destino, tam, "Error interno de Prolog.");
}

/* ------------------------------------------------------------------ */
/* Consulta dinamica                                                   */
/* ------------------------------------------------------------------ */

static void iniciar_resultado(ResultadoConsulta *resultado)
{
    resultado->cantidad = 0;
    resultado->filas = NULL;
    resultado->mensaje_error[0] = '\0';
}

/* Pone cada argumento de C como string de Prolog. */
static int poner_argumentos(term_t argumentos, const char *valores[], int n)
{
    for (int i = 0; i < n; i++) {
        if (!PL_unify_chars(argumentos + i, PL_STRING | REP_MB,
                            (size_t)-1, valores[i])) {
            return 0;
        }
    }
    return 1;
}

/* Recorre las soluciones una a una (backtracking) y las guarda. */
static int recorrer_soluciones(predicate_t pred, term_t argumentos, int n,
                               ResultadoConsulta *resultado)
{
    qid_t consulta = PL_open_query(NULL, PL_Q_CATCH_EXCEPTION, pred, argumentos);
    term_t excepcion;
    int capacidad = 0;
    int estado = CONEXION_OK;

    while (PL_next_solution(consulta)) {
        if (!agregar_fila(resultado, argumentos + n, &capacidad)) {
            copiar_mensaje(resultado->mensaje_error, CONEXION_TAM_MENSAJE,
                           "Prolog devolvio una fila con formato invalido.");
            estado = CONEXION_ERROR;
            break;
        }
    }

    excepcion = PL_exception(consulta);
    if (estado == CONEXION_OK && excepcion) {
        describir_excepcion(excepcion, resultado->mensaje_error,
                            CONEXION_TAM_MENSAJE);
        estado = CONEXION_ERROR;
    }
    PL_close_query(consulta);

    if (estado == CONEXION_OK && resultado->cantidad == 0) {
        estado = CONEXION_SIN_RESULTADOS;
    }
    return estado;
}

int conexion_consultar(const char *consulta,
                       const char *argumentos[], int cantidad_argumentos,
                       ResultadoConsulta *resultado)
{
    fid_t marco;
    term_t terminos;
    predicate_t pred;
    int estado;

    iniciar_resultado(resultado);

    if (!prolog_iniciado) {
        copiar_mensaje(resultado->mensaje_error, CONEXION_TAM_MENSAJE,
                       "Prolog no esta iniciado.");
        return CONEXION_ERROR;
    }
    if (consulta == NULL ||
        strncmp(consulta, PREFIJO_CONSULTA, strlen(PREFIJO_CONSULTA)) != 0) {
        copiar_mensaje(resultado->mensaje_error, CONEXION_TAM_MENSAJE,
                       "Solo se permiten predicados consulta_* (API de consultas.pl).");
        return CONEXION_ERROR;
    }
    if (cantidad_argumentos < 0 || cantidad_argumentos > MAX_ARGUMENTOS) {
        copiar_mensaje(resultado->mensaje_error, CONEXION_TAM_MENSAJE,
                       "Cantidad de argumentos invalida.");
        return CONEXION_ERROR;
    }

    marco = PL_open_foreign_frame();
    pred = PL_predicate(consulta, cantidad_argumentos + 1, MODULO_CONSULTAS);
    terminos = PL_new_term_refs((size_t)cantidad_argumentos + 1);

    if (!poner_argumentos(terminos, argumentos, cantidad_argumentos)) {
        copiar_mensaje(resultado->mensaje_error, CONEXION_TAM_MENSAJE,
                       "No se pudieron convertir los argumentos para Prolog.");
        estado = CONEXION_ERROR;
    } else {
        estado = recorrer_soluciones(pred, terminos, cantidad_argumentos,
                                     resultado);
    }

    PL_discard_foreign_frame(marco);

    if (estado == CONEXION_ERROR) {
        /* conserva el mensaje pero descarta filas parciales */
        char mensaje[CONEXION_TAM_MENSAJE];
        copiar_mensaje(mensaje, CONEXION_TAM_MENSAJE, resultado->mensaje_error);
        conexion_liberar(resultado);
        copiar_mensaje(resultado->mensaje_error, CONEXION_TAM_MENSAJE, mensaje);
    }
    return estado;
}

/* ------------------------------------------------------------------ */
/* Liberacion de memoria                                               */
/* ------------------------------------------------------------------ */

void conexion_liberar(ResultadoConsulta *resultado)
{
    if (resultado == NULL) {
        return;
    }
    for (int i = 0; i < resultado->cantidad; i++) {
        FilaResultado *fila = &resultado->filas[i];
        for (int j = 0; j < fila->cantidad; j++) {
            free(fila->columnas[j]);
        }
        free(fila->columnas);
    }
    free(resultado->filas);
    resultado->filas = NULL;
    resultado->cantidad = 0;
    resultado->mensaje_error[0] = '\0';
}
