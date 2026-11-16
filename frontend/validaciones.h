/*
 * validaciones.h - Validacion de FORMATO de las entradas del usuario
 *
 * Responsabilidad unica: decidir si un texto tiene la forma correcta
 * (RF-03). No conoce el dominio: si un curso o un estudiante EXISTE lo
 * decide Prolog (consulta_existe_curso / consulta_existe_estudiante).
 * Todas devuelven 1 si es valido y 0 si no.
 */
#ifndef VALIDACIONES_H
#define VALIDACIONES_H

#include <stddef.h>

/* Carne: exactamente 9 digitos (cedula). */
int validar_carne(const char *texto);

/* Codigo de curso: 2-4 letras + 1-4 digitos + 'o' opcional
   (eif200, EG1, eif420o). Acepta mayusculas o minusculas. */
int validar_codigo_curso(const char *texto);

/* Entero completo dentro de [minimo, maximo]; lo deja en *valor. */
int validar_entero(const char *texto, int minimo, int maximo, int *valor);

/* Texto no vacio de a lo sumo largo_maximo caracteres. */
int validar_texto(const char *texto, size_t largo_maximo);

/* Al menos 2 codigos de curso validos separados por espacios o comas. */
int validar_seleccion_cursos(const char *texto);

#endif /* VALIDACIONES_H */
