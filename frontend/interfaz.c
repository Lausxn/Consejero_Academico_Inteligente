/*
 * interfaz.c - Impresion de titulos, mensajes y tablas; lectura de lineas
 */
#include "interfaz.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#define ANCHO_TOTAL          112   /* ancho maximo de una tabla           */
#define ANCHO_MAX_COLUMNA    40    /* columnas que no son la ultima       */
#define ANCHO_MIN_ULTIMA     24    /* minimo para la ultima columna       */
#define MAX_COLUMNAS         8
#define SEPARADOR            " | "
#define LARGO_SEPARADOR      3
#define CARACTER_TITULO      '='
#define CARACTER_LINEA       '-'

/* ------------------------------------------------------------------ */
/* Mensajes                                                            */
/* ------------------------------------------------------------------ */

static void repetir(char caracter, int veces)
{
    for (int i = 0; i < veces; i++) {
        putchar(caracter);
    }
}

void interfaz_titulo(const char *titulo)
{
    int largo = (int)strlen(titulo) + 4;
    printf("\n");
    repetir(CARACTER_TITULO, largo);
    printf("\n  %s\n", titulo);
    repetir(CARACTER_TITULO, largo);
    printf("\n");
}

void interfaz_opcion(int numero, const char *texto)
{
    printf("  %2d. %s\n", numero, texto);
}

void interfaz_opcion_detalle(int numero, const char *texto, const char *detalle)
{
    printf("  %2d. %s (%s)\n", numero, texto, detalle);
}

void interfaz_dato(const char *etiqueta, const char *valor, const char *extra)
{
    if (extra != NULL) {
        printf("%s: %s - %s\n", etiqueta, valor, extra);
    } else {
        printf("%s: %s\n", etiqueta, valor);
    }
}

void interfaz_exito(const char *mensaje) { printf("[OK] %s\n", mensaje); }
void interfaz_error(const char *mensaje) { printf("[ERROR] %s\n", mensaje); }
void interfaz_aviso(const char *mensaje) { printf("[i] %s\n", mensaje); }

/* ------------------------------------------------------------------ */
/* Tablas                                                              */
/* ------------------------------------------------------------------ */

static int columnas_del_resultado(const char *encabezados[], int cantidad,
                                  const ResultadoConsulta *resultado)
{
    int columnas = (encabezados != NULL) ? cantidad : 0;
    for (int i = 0; i < resultado->cantidad; i++) {
        if (resultado->filas[i].cantidad > columnas) {
            columnas = resultado->filas[i].cantidad;
        }
    }
    return columnas > MAX_COLUMNAS ? MAX_COLUMNAS : columnas;
}

static int largo_natural(int columna, const char *encabezados[], int cantidad,
                         const ResultadoConsulta *resultado)
{
    int maximo = 0;
    if (encabezados != NULL && columna < cantidad) {
        maximo = (int)strlen(encabezados[columna]);
    }
    for (int i = 0; i < resultado->cantidad; i++) {
        const FilaResultado *fila = &resultado->filas[i];
        if (columna < fila->cantidad && (int)strlen(fila->columnas[columna]) > maximo) {
            maximo = (int)strlen(fila->columnas[columna]);
        }
    }
    return maximo;
}

/* Anchos: las primeras columnas hasta ANCHO_MAX_COLUMNA y la ultima con
   lo que sobre del ANCHO_TOTAL. Devuelve el ancho total de la tabla. */
static int calcular_anchos(int columnas, const char *encabezados[], int cantidad,
                           const ResultadoConsulta *resultado, int anchos[])
{
    int usado = 0;
    for (int c = 0; c < columnas; c++) {
        int natural = largo_natural(c, encabezados, cantidad, resultado);
        if (c < columnas - 1) {
            anchos[c] = natural < ANCHO_MAX_COLUMNA ? natural : ANCHO_MAX_COLUMNA;
            usado += anchos[c] + LARGO_SEPARADOR;
        } else {
            int disponible = ANCHO_TOTAL - usado;
            if (disponible < ANCHO_MIN_ULTIMA) {
                disponible = ANCHO_MIN_ULTIMA;
            }
            anchos[c] = natural < disponible ? natural : disponible;
            usado += anchos[c];
        }
        if (anchos[c] < 1) {
            anchos[c] = 1;
        }
    }
    return usado;
}

/* Toma el siguiente tramo de texto que cabe en 'ancho', cortando en un
   espacio cuando es posible. */
static const char *tomar_tramo(const char *texto, int ancho, int *largo)
{
    int total;
    int corte;

    while (*texto == ' ') {
        texto++;
    }
    total = (int)strlen(texto);
    if (total <= ancho) {
        *largo = total;
        return texto;
    }
    corte = ancho;
    while (corte > 0 && texto[corte] != ' ') {
        corte--;
    }
    *largo = (corte > 0) ? corte : ancho;
    return texto;
}

/* Imprime una fila; las celdas largas continuan en lineas siguientes. */
static void imprimir_fila(const char *celdas[], int columnas, const int anchos[])
{
    const char *resto[MAX_COLUMNAS];
    int quedan = 1;

    for (int c = 0; c < columnas; c++) {
        resto[c] = celdas[c];
    }
    while (quedan) {
        quedan = 0;
        for (int c = 0; c < columnas; c++) {
            int largo = 0;
            const char *tramo = (resto[c] != NULL) ? tomar_tramo(resto[c], anchos[c], &largo) : "";
            if (c > 0) {
                fputs(SEPARADOR, stdout);
            }
            printf("%-*.*s", anchos[c], largo, tramo);
            resto[c] = (resto[c] != NULL && tramo[largo] != '\0') ? tramo + largo : NULL;
            quedan = quedan || resto[c] != NULL;
        }
        putchar('\n');
    }
}

void interfaz_mostrar_tabla(const char *encabezados[], int cantidad,
                            const ResultadoConsulta *resultado)
{
    int anchos[MAX_COLUMNAS];
    const char *celdas[MAX_COLUMNAS];
    int columnas = columnas_del_resultado(encabezados, cantidad, resultado);
    int ancho_total;

    if (columnas == 0) {
        return;
    }
    ancho_total = calcular_anchos(columnas, encabezados, cantidad, resultado, anchos);
    printf("\n");
    if (encabezados != NULL) {
        for (int c = 0; c < columnas; c++) {
            celdas[c] = (c < cantidad) ? encabezados[c] : "";
        }
        imprimir_fila(celdas, columnas, anchos);
        repetir(CARACTER_LINEA, ancho_total);
        putchar('\n');
    }
    for (int i = 0; i < resultado->cantidad; i++) {
        const FilaResultado *fila = &resultado->filas[i];
        for (int c = 0; c < columnas; c++) {
            celdas[c] = (c < fila->cantidad) ? fila->columnas[c] : "";
        }
        imprimir_fila(celdas, columnas, anchos);
    }
}

void interfaz_mostrar_resultado(int estado, const ResultadoConsulta *resultado,
                                const char *encabezados[], int cantidad,
                                const char *sin_resultados)
{
    switch (estado) {
    case CONEXION_OK:
        interfaz_mostrar_tabla(encabezados, cantidad, resultado);
        break;
    case CONEXION_SIN_RESULTADOS:
        interfaz_aviso(sin_resultados);
        break;
    default:
        interfaz_error(resultado->mensaje_error);
        break;
    }
}

/* ------------------------------------------------------------------ */
/* Entrada                                                             */
/* ------------------------------------------------------------------ */

/* Quita espacios a los lados y la marca BOM de UTF-8 si viene al inicio
   (algunas consolas la agregan al redirigir la entrada). */
static void recortar(char *texto)
{
    static const char BOM_UTF8[] = "\xEF\xBB\xBF";
    size_t inicio = (strncmp(texto, BOM_UTF8, 3) == 0) ? 3 : 0;
    size_t largo = strlen(texto);

    while (largo > 0 && isspace((unsigned char)texto[largo - 1])) {
        texto[--largo] = '\0';
    }
    while (isspace((unsigned char)texto[inicio])) {
        inicio++;
    }
    memmove(texto, texto + inicio, largo - inicio + 1);
}

int interfaz_leer_linea(const char *indicacion, char *destino, int tam)
{
    printf("%s: ", indicacion);
    fflush(stdout);
    if (fgets(destino, tam, stdin) == NULL) {
        destino[0] = '\0';
        return 0;
    }
    if (strchr(destino, '\n') == NULL) {        /* linea mas larga: descartar resto */
        int c;
        while ((c = getchar()) != '\n' && c != EOF) {
        }
    }
    recortar(destino);
    return 1;
}

void interfaz_pausa(void)
{
    int c;
    printf("\nPresione Enter para continuar...");
    fflush(stdout);
    while ((c = getchar()) != '\n' && c != EOF) {   /* descarta lo escrito */
    }
    if (c == EOF) {
        printf("\n");
    }
}
