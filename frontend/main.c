/*
 * main.c - Punto de entrada del Consejero Academico Inteligente
 *
 * Responsabilidad: orquestar el ciclo de vida del programa:
 *   1) iniciar Prolog y cargar el back-end (conexion.h),
 *   2) cargar los estudiantes guardados,
 *   3) ejecutar el menu,
 *   4) guardar y cerrar Prolog.
 */
#include <stdio.h>

#include "conexion.h"
#include "interfaz.h"
#include "menu.h"

#define TAM_MENSAJE 256

/* Ejecuta una consulta sin argumentos y muestra su mensaje. */
static void ejecutar_comando(const char *consulta)
{
    ResultadoConsulta resultado;
    int estado = conexion_consultar(consulta, NULL, 0, &resultado);
    interfaz_mostrar_resultado(estado, &resultado, NULL, 0, "");
    conexion_liberar(&resultado);
}

int main(int argc, char **argv)
{
    char mensaje[TAM_MENSAJE];
    const char *programa = (argc > 0) ? argv[0] : "consejero";

    if (conexion_iniciar(programa, mensaje, sizeof(mensaje)) != CONEXION_OK) {
        interfaz_error(mensaje);
        conexion_cerrar();
        return 1;
    }

    interfaz_titulo("Consejero Academico Inteligente - UNA");
    ejecutar_comando("consulta_cargar");

    menu_ejecutar();

    ejecutar_comando("consulta_guardar");
    conexion_cerrar();
    printf("Hasta luego.\n");
    return 0;
}
