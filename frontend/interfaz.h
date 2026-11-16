/*
 * interfaz.h - Entrada y salida por consola (presentacion)
 *
 * Responsabilidad unica: imprimir titulos, mensajes y tablas, y leer
 * lineas del usuario. No contiene logica del dominio: muestra lo que
 * Prolog devolvio tal como viene.
 */
#ifndef INTERFAZ_H
#define INTERFAZ_H

#include "conexion.h"

void interfaz_titulo(const char *titulo);
void interfaz_opcion(int numero, const char *texto);
/* "  1. texto (detalle)" */
void interfaz_opcion_detalle(int numero, const char *texto, const char *detalle);
/* "Etiqueta: valor" o "Etiqueta: valor - extra" (extra puede ser NULL) */
void interfaz_dato(const char *etiqueta, const char *valor, const char *extra);
void interfaz_exito(const char *mensaje);
void interfaz_error(const char *mensaje);
void interfaz_aviso(const char *mensaje);

/*
 * Imprime un resultado de Prolog como tabla con columnas alineadas y
 * texto ajustado al ancho. encabezados puede ser NULL (sin encabezado).
 */
void interfaz_mostrar_tabla(const char *encabezados[], int cantidad,
                            const ResultadoConsulta *resultado);

/*
 * Muestra un resultado segun su estado: tabla si hay filas, aviso si no
 * hubo resultados y error con el mensaje de Prolog si fallo.
 */
void interfaz_mostrar_resultado(int estado, const ResultadoConsulta *resultado,
                                const char *encabezados[], int cantidad,
                                const char *sin_resultados);

/*
 * Lee una linea (sin el salto y sin espacios a los lados).
 * Devuelve 0 si se acabo la entrada (EOF).
 */
int interfaz_leer_linea(const char *indicacion, char *destino, int tam);

void interfaz_pausa(void);

#endif /* INTERFAZ_H */
