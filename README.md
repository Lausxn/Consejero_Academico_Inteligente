# Consejero Académico Inteligente

Sistema de planificación académica para Ingeniería en Sistemas de Información (UNA).
Front-end en **C** (consola) y back-end en **SWI-Prolog**, integrados con la API de C de SWI-Prolog (Prolog incrustado).

**Proyecto Programado N.º 2 · Paradigmas de Programación · Ciclo II 2026**
Universidad Nacional de Costa Rica · Prof. Juan de Dios Murillo

**Estudiantes:** Lausen Paniagua Arias · Génesis Silesky Araya

## Estructura

```
frontend/       Capa 1: presentación (solo C)
integracion/    Capa 2: puente C <-> Prolog (conexion.c/h)
backend/        Capa 3: razonamiento (solo Prolog)
datos/          registros.txt y reportes generados
pruebas/        pruebas plunit y casos documentados
documentacion/  diseño, manuales y guía de defensa
```

## Requisitos

- SWI-Prolog 9 o superior, con su carpeta `bin` en el `PATH` (en tiempo de ejecución se necesita `libswipl.dll`).
- GCC (en Windows, MinGW-w64; por ejemplo, WinLibs).

## Compilar y ejecutar

```sh
mingw32-make          # compila en build/consejero.exe   (Linux: make)
mingw32-make run      # ejecuta desde la raíz del proyecto
mingw32-make test     # corre las pruebas de Prolog
mingw32-make prolog   # abre el back-end en swipl
```

> El ejecutable debe correrse desde la raíz del proyecto, porque carga `backend/main.pl` y `datos/registros.txt` con rutas relativas.

El detalle de instalación está en `documentacion/manual_usuario.md` (Bloque 8).
