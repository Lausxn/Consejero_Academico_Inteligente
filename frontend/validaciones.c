/*
 * validaciones.c - Validacion de formato de las entradas (sin dominio)
 */
#include "validaciones.h"

#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#define LARGO_CARNE            9
#define MIN_LETRAS_CODIGO      2
#define MAX_LETRAS_CODIGO      3
#define MIN_DIGITOS_CODIGO     1
#define MAX_DIGITOS_CODIGO     3
#define SUFIJO_OPTATIVO        'o'
#define MIN_CURSOS_SELECCION   2
#define TAM_SELECCION          512
#define SEPARADORES_SELECCION  " ,;\t"

/* Cuenta cuantos caracteres seguidos cumplen el criterio. */
static size_t contar_mientras(const char *texto, int (*criterio)(int))
{
    size_t n = 0;
    while (texto[n] != '\0' && criterio((unsigned char)texto[n])) {
        n++;
    }
    return n;
}

int validar_carne(const char *texto)
{
    return texto != NULL &&
           strlen(texto) == LARGO_CARNE &&
           contar_mientras(texto, isdigit) == LARGO_CARNE;
}

int validar_codigo_curso(const char *texto)
{
    size_t letras, digitos, posicion;

    if (texto == NULL) {
        return 0;
    }
    letras = contar_mientras(texto, isalpha);
    digitos = contar_mientras(texto + letras, isdigit);
    posicion = letras + digitos;

    if (tolower((unsigned char)texto[posicion]) == SUFIJO_OPTATIVO) {
        posicion++;
    }
    return texto[posicion] == '\0' &&
           letras >= MIN_LETRAS_CODIGO && letras <= MAX_LETRAS_CODIGO &&
           digitos >= MIN_DIGITOS_CODIGO && digitos <= MAX_DIGITOS_CODIGO;
}

int validar_entero(const char *texto, int minimo, int maximo, int *valor)
{
    char *fin = NULL;
    long numero;

    if (texto == NULL || *texto == '\0') {
        return 0;
    }
    errno = 0;
    numero = strtol(texto, &fin, 10);
    if (errno != 0 || *fin != '\0' || numero < minimo || numero > maximo) {
        return 0;
    }
    *valor = (int)numero;
    return 1;
}

int validar_texto(const char *texto, size_t largo_maximo)
{
    size_t largo;

    if (texto == NULL) {
        return 0;
    }
    largo = strlen(texto);
    return largo > 0 && largo <= largo_maximo &&
           contar_mientras(texto, isspace) < largo;
}

int validar_seleccion_cursos(const char *texto)
{
    char copia[TAM_SELECCION];
    char *codigo;
    int cantidad = 0;

    if (texto == NULL || strlen(texto) >= sizeof(copia)) {
        return 0;
    }
    strcpy(copia, texto);

    for (codigo = strtok(copia, SEPARADORES_SELECCION);
         codigo != NULL;
         codigo = strtok(NULL, SEPARADORES_SELECCION)) {
        if (!validar_codigo_curso(codigo)) {
            return 0;
        }
        cantidad++;
    }
    return cantidad >= MIN_CURSOS_SELECCION;
}
