/*
 * prueba_integracion.c - Pruebas de integracion C <-> Prolog
 *
 * Usa SOLO conexion.h (igual que el front-end) para verificar el camino
 * completo: C arma la consulta, Prolog infiere y C recibe las filas.
 * Solo hace consultas de lectura: no modifica datos/registros.txt.
 *
 * Compilar y ejecutar desde la raiz:  mingw32-make test-c
 */
#include <stdio.h>
#include <string.h>

#include "conexion.h"

#define TAM_MENSAJE        256
#define REPETICIONES_MEMORIA 1000

static int pruebas_pasadas = 0;
static int pruebas_totales = 0;

/* ------------------------------------------------------------------ */
/* Utilidades                                                          */
/* ------------------------------------------------------------------ */

static void verificar(int condicion, const char *nombre)
{
    pruebas_totales++;
    if (condicion) {
        pruebas_pasadas++;
    }
    printf("[%s] I-%02d %s\n", condicion ? "PASA " : "FALLA", pruebas_totales, nombre);
}

/* 1 si alguna columna de alguna fila contiene el texto. */
static int contiene(const ResultadoConsulta *r, const char *texto)
{
    for (int i = 0; i < r->cantidad; i++) {
        for (int j = 0; j < r->filas[i].cantidad; j++) {
            if (strstr(r->filas[i].columnas[j], texto) != NULL) {
                return 1;
            }
        }
    }
    return 0;
}

/* 1 si alguna fila tiene exactamente 'codigo' en su primera columna. */
static int tiene_fila(const ResultadoConsulta *r, const char *codigo)
{
    for (int i = 0; i < r->cantidad; i++) {
        if (r->filas[i].cantidad > 0 && strcmp(r->filas[i].columnas[0], codigo) == 0) {
            return 1;
        }
    }
    return 0;
}

/* Cuenta las filas cuya primera columna empieza con el prefijo. */
static int contar_filas(const ResultadoConsulta *r, const char *prefijo)
{
    int n = 0;
    for (int i = 0; i < r->cantidad; i++) {
        if (r->filas[i].cantidad > 0 &&
            strncmp(r->filas[i].columnas[0], prefijo, strlen(prefijo)) == 0) {
            n++;
        }
    }
    return n;
}

static int consultar(const char *consulta, const char *a1, const char *a2,
                     const char *a3, ResultadoConsulta *r)
{
    const char *argumentos[3] = { a1, a2, a3 };
    int n = (a1 == NULL) ? 0 : (a2 == NULL) ? 1 : (a3 == NULL) ? 2 : 3;
    return conexion_consultar(consulta, argumentos, n, r);
}

/* ------------------------------------------------------------------ */
/* Casos                                                               */
/* ------------------------------------------------------------------ */

static void probar_carga(void)
{
    ResultadoConsulta r;
    int e = consultar("consulta_cargar", NULL, NULL, NULL, &r);
    verificar(e == CONEXION_OK && contiene(&r, "5 estudiante"),
              "consulta_cargar carga los 5 perfiles de registros.txt");
    conexion_liberar(&r);
}

static void probar_disponibles(void)
{
    ResultadoConsulta r;
    int e = consultar("consulta_disponibles", "111110004", NULL, NULL, &r);
    verificar(e == CONEXION_OK && r.cantidad > 5,
              "disponibles devuelve varias filas (una por solucion)");
    verificar(tiene_fila(&r, "EIF206") && tiene_fila(&r, "EIF207") &&
              tiene_fila(&r, "MAT005") && tiene_fila(&r, "MAT006"),
              "ejemplo del enunciado: EIF206, EIF207, MAT005 y MAT006 disponibles");
    verificar(!tiene_fila(&r, "EIF211") && !tiene_fila(&r, "EIF205"),
              "ejemplo del enunciado: EIF211 y EIF205 NO disponibles");
    verificar(r.cantidad > 0 && r.filas[0].cantidad == 4,
              "cada fila trae 4 columnas (codigo, nombre, creditos, por que)");
    conexion_liberar(&r);
}

static void probar_que_falta(void)
{
    ResultadoConsulta r;
    int e = consultar("consulta_que_falta", "111110004", "EIF211", NULL, &r);
    verificar(e == CONEXION_OK && contiene(&r, "NO DISPONIBLE") &&
              contiene(&r, "EIF206") && contiene(&r, "EIF207"),
              "que falta para EIF211: explica que faltan EIF206 y EIF207");
    conexion_liberar(&r);
}

static void probar_ruta(void)
{
    ResultadoConsulta r;
    int e = consultar("consulta_ruta", "208490835", "eif402", NULL, &r);
    verificar(e == CONEXION_OK && contar_filas(&r, "Ruta ") == 3,
              "ruta hacia EIF402: 3 cadenas alternativas (backtracking)");
    conexion_liberar(&r);
}

static void probar_choques(void)
{
    ResultadoConsulta r;
    int e = consultar("consulta_choques", "eif209 eif210", NULL, NULL, &r);
    verificar(e == CONEXION_OK && contiene(&r, "EIF210 G2"),
              "choque EIF209/EIF210: encuentra grupos sin choque (EIF210 G2)");
    conexion_liberar(&r);

    e = consultar("consulta_choques", "eif402 eif412", NULL, NULL, &r);
    verificar(e == CONEXION_OK && tiene_fila(&r, "Sin solucion"),
              "choque inevitable EIF402/EIF412: no hay asignacion posible");
    conexion_liberar(&r);
}

static void probar_recomendacion(void)
{
    ResultadoConsulta r;
    int e = consultar("consulta_recomendar", "111110002", "ciclo", "18", &r);
    verificar(e == CONEXION_OK && r.cantidad > 0 &&
              strstr(r.filas[0].columnas[1], "EIF401") != NULL &&
              strstr(r.filas[0].columnas[1], "EIF402") != NULL,
              "recomendacion: la opcion 1 lleva los correquisitos EIF401 y EIF402");
    conexion_liberar(&r);
}

static void probar_errores(void)
{
    ResultadoConsulta r;
    int e;

    e = consultar("consulta_disponibles", "12ab", NULL, NULL, &r);
    verificar(e == CONEXION_ERROR && strstr(r.mensaje_error, "9 digitos") != NULL,
              "error: carne invalido llega como mensaje de Prolog");
    conexion_liberar(&r);

    e = consultar("consulta_avance", "123456789", NULL, NULL, &r);
    verificar(e == CONEXION_ERROR && strstr(r.mensaje_error, "No existe") != NULL,
              "error: estudiante inexistente");
    conexion_liberar(&r);

    e = consultar("consulta_recomendar", "208490835", "ciclo", "25", &r);
    verificar(e == CONEXION_ERROR && strstr(r.mensaje_error, "18") != NULL,
              "error: tope por ciclo mayor a 18 creditos");
    conexion_liberar(&r);

    e = consultar("consulta_aprobados", "111110001", NULL, NULL, &r);
    verificar(e == CONEXION_SIN_RESULTADOS && r.cantidad == 0,
              "sin resultados: primer ingreso no tiene aprobados");
    conexion_liberar(&r);

    e = consultar("halt", NULL, NULL, NULL, &r);
    verificar(e == CONEXION_ERROR,
              "seguridad: se rechaza un predicado fuera de la API consulta_*");
    conexion_liberar(&r);
}

static void probar_memoria(void)
{
    int correctas = 0;
    for (int i = 0; i < REPETICIONES_MEMORIA; i++) {
        ResultadoConsulta r;
        if (consultar("consulta_disponibles", "111110004", NULL, NULL, &r) == CONEXION_OK) {
            correctas++;
        }
        conexion_liberar(&r);
    }
    verificar(correctas == REPETICIONES_MEMORIA,
              "1000 consultas seguidas con liberacion de memoria");
}

int main(int argc, char **argv)
{
    char mensaje[TAM_MENSAJE];
    int inicio = conexion_iniciar(argc > 0 ? argv[0] : "prueba", mensaje, sizeof(mensaje));

    verificar(inicio == CONEXION_OK, "conexion_iniciar carga backend/main.pl");
    if (inicio != CONEXION_OK) {
        printf("%s\n", mensaje);
        return 1;
    }

    probar_carga();
    probar_disponibles();
    probar_que_falta();
    probar_ruta();
    probar_choques();
    probar_recomendacion();
    probar_errores();
    probar_memoria();

    conexion_cerrar();
    printf("\n%d de %d pruebas de integracion pasaron.\n", pruebas_pasadas, pruebas_totales);
    return pruebas_pasadas == pruebas_totales ? 0 : 1;
}
