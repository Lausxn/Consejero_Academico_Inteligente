/*
 * conexion.h - Puente entre el front-end en C y el back-end en Prolog
 *
 * Es la UNICA abstraccion que conoce el front-end (inversion de
 * dependencias): no expone ningun tipo de SWI-Prolog. Si se cambiara la
 * integracion (por ejemplo, a pipes con swipl), solo se reescribe
 * conexion.c; menu.c e interfaz.c no cambian.
 *
 * Contrato con Prolog (ver documentacion/diseno.md, seccion 3):
 *   consulta_<caso>(+Arg1, ..., +ArgN, -Fila)
 *   - cada solucion es una fila (lista de textos),
 *   - si no hay soluciones -> CONEXION_SIN_RESULTADOS,
 *   - si lanza error_sipa(Mensaje) -> CONEXION_ERROR con ese mensaje.
 */
#ifndef CONEXION_H
#define CONEXION_H

#define CONEXION_OK              0
#define CONEXION_SIN_RESULTADOS  1
#define CONEXION_ERROR           2

#define CONEXION_TAM_MENSAJE     512

/* Una fila del resultado: una solucion de Prolog. */
typedef struct {
    int    cantidad;      /* cantidad de columnas */
    char **columnas;      /* textos propios; se liberan con conexion_liberar */
} FilaResultado;

/* Resultado completo de una consulta. */
typedef struct {
    int            cantidad;                          /* cantidad de filas */
    FilaResultado *filas;
    char           mensaje_error[CONEXION_TAM_MENSAJE];
} ResultadoConsulta;

/*
 * Inicia Prolog y carga el back-end (backend/main.pl).
 * programa: argv[0] del ejecutable.
 * Devuelve CONEXION_OK o CONEXION_ERROR (con el motivo en mensaje).
 */
int conexion_iniciar(const char *programa, char *mensaje, int tam_mensaje);

/* Cierra Prolog y libera sus recursos. */
void conexion_cerrar(void);

/*
 * Ejecuta consulta(arg1, ..., argN, Fila) del modulo consultas y recoge
 * TODAS sus soluciones en resultado.
 * Solo acepta predicados cuyo nombre empiece con "consulta_".
 * Devuelve CONEXION_OK, CONEXION_SIN_RESULTADOS o CONEXION_ERROR.
 * Siempre hay que llamar a conexion_liberar(resultado) despues.
 */
int conexion_consultar(const char *consulta,
                       const char *argumentos[], int cantidad_argumentos,
                       ResultadoConsulta *resultado);

/* Libera la memoria de un resultado (se puede llamar mas de una vez). */
void conexion_liberar(ResultadoConsulta *resultado);

#endif /* CONEXION_H */
