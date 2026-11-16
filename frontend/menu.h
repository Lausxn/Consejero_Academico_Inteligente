/*
 * menu.h - Menu principal del Consejero Academico Inteligente
 *
 * Expone solo el punto de entrada del menu (segregacion de interfaces):
 * las opciones, los manejadores y los submenus son internos de menu.c.
 */
#ifndef MENU_H
#define MENU_H

/* Muestra el menu principal y despacha opciones hasta que el usuario
   elija Salir o se acabe la entrada. */
void menu_ejecutar(void);

#endif /* MENU_H */
