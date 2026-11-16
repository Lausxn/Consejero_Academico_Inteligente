# Consejero Académico Inteligente

Sistema de planificación académica para Ingeniería en Sistemas de Información (UNA). A partir del historial de un estudiante, razona sobre el plan de estudios oficial y deduce qué cursos puede matricular, qué le falta, rutas hacia un curso meta, choques de horario, combinaciones recomendadas y su avance hacia el Diplomado o el Bachillerato. Cada conclusión viene con su explicación.

- **Front-end:** C (consola).
- **Back-end:** SWI-Prolog.
- **Integración:** Prolog incrustado con la API de C de SWI-Prolog.

**Proyecto Programado N.º 2** · Paradigmas de Programación · Ciclo II 2026
Universidad Nacional de Costa Rica · Prof. Juan de Dios Murillo
**Estudiantes:** Lausen Paniagua Arias · Génesis Silesky Araya

## Inicio rápido

Requisitos: SWI-Prolog 9 o superior, con su carpeta `bin` en el `PATH` (en tiempo de ejecución se necesita `libswipl.dll`), y GCC con Make (MinGW-w64 en Windows).

```sh
mingw32-make            # compila build/consejero.exe        (Linux: make)
mingw32-make run        # ejecuta desde la raíz del proyecto
mingw32-make test-todo  # 63 pruebas plunit + 17 de integración C <-> Prolog
```

En Windows también se puede abrir con **doble clic en `ejecutar.bat`**. Agrega SWI-Prolog al PATH, compila si hace falta y abre el programa, aunque la terminal no tenga el PATH actualizado.

Para probarlo, use el carné `111110004` (el ejemplo del enunciado) o escriba `?` cuando se pida un carné para ver los estudiantes de prueba.

## Estructura

```
frontend/       Capa 1: presentación (solo C): main, menu, interfaz, validaciones
integracion/    Capa 2: puente C <-> Prolog (conexion.c/h)
backend/        Capa 3: razonamiento (solo Prolog):
                hechos -> reglas -> inferencia -> explicaciones -> consultas
datos/          registros.txt y reportes generados
pruebas/        pruebas plunit, prueba de integración en C, casos documentados
documentacion/  diseño, manuales y guía de defensa
```

## Documentación

| Documento | Contenido |
|---|---|
| [`documentacion/manual_usuario.md`](documentacion/manual_usuario.md) | instalación, compilación, uso de cada opción y solución de problemas |
| [`documentacion/manual_tecnico.md`](documentacion/manual_tecnico.md) | arquitectura, base de conocimientos, reglas, integración, conteo de mínimos y SOLID |
| [`documentacion/guia_defensa.md`](documentacion/guia_defensa.md) | hechos y reglas, unificación, recursividad, backtracking, flujo C ↔ Prolog y demo en vivo |
| [`documentacion/diseno.md`](documentacion/diseno.md) | diseño previo y decisiones |
| [`pruebas/casos_prueba.txt`](pruebas/casos_prueba.txt) | 31 casos con entrada, esperado, obtenido y evidencia |
