# Manual de usuario — Consejero Académico Inteligente

**Universidad Nacional de Costa Rica** · Paradigmas de Programación · Ciclo II 2026
**Profesor:** Juan de Dios Murillo
**Estudiantes:** Lausen Paniagua Arias · Génesis Silesky Araya

---

## 1. Requisitos

| Componente | Versión probada | Para qué |
|---|---|---|
| SWI-Prolog | 10.1.16 (sirve 9.x o superior, de 64 bits) | motor lógico y biblioteca `libswipl.dll` |
| GCC (MinGW-w64) | 16.2.0 (WinLibs, UCRT) | compilar el front-end en C |
| GNU Make | 4.4.1 (`mingw32-make`, incluido en WinLibs) | compilar con el `Makefile` |

> El programa usa **Prolog incrustado en C**. Para ejecutarse necesita la biblioteca `libswipl.dll`, que se instala con SWI-Prolog. No es una librería externa de IA: es el mismo motor de SWI-Prolog que exige el enunciado.

---

## 2. Instalación en Windows

### 2.1 SWI-Prolog
1. Descargue el instalador de 64 bits desde <https://www.swi-prolog.org/download/stable>. También se puede instalar con `winget install SWI-Prolog.SWI-Prolog`.
2. Durante la instalación, marque **"Add swipl to the system PATH"**.
3. **Importante:** el ejecutable necesita encontrar `libswipl.dll`, que está en `C:\Program Files\swipl\bin`. Si no marcó la opción del PATH, agréguela a mano:
   - Abra *Configuración → Sistema → Información → Configuración avanzada del sistema → Variables de entorno*.
   - En *Path* (de usuario), agregue `C:\Program Files\swipl\bin`.
   - **Cierre y vuelva a abrir** la terminal.

### 2.2 GCC y Make (WinLibs)
1. Instálelo con `winget install BrechtSanders.WinLibs.POSIX.UCRT` o descárguelo desde <https://winlibs.com>.
2. Cierre y vuelva a abrir la terminal.

### 2.3 Verificar
```
swipl --version
gcc --version
mingw32-make --version
```
Los tres comandos deben responder con su versión.

## 3. Instalación en Linux (Debian/Ubuntu)

```
sudo apt install swi-prolog gcc make pkg-config
```

En Linux el `Makefile` usa `pkg-config swipl` y los comandos son `make`, `make run`, etc.

> Nota: el sistema se probó en Windows 11. La rama de Linux del `Makefile` no se ejecutó.

---

## 4. Compilar y ejecutar

Desde la **carpeta raíz del proyecto** (la que contiene el `Makefile`):

| Comando (Windows) | Qué hace |
|---|---|
| `mingw32-make` | compila `build/consejero.exe` |
| `mingw32-make run` | compila y ejecuta el programa |
| `mingw32-make test` | corre las 63 pruebas del back-end (plunit) |
| `mingw32-make test-c` | corre las 17 pruebas de integración C ↔ Prolog |
| `mingw32-make test-todo` | corre todas las pruebas |
| `mingw32-make prolog` | abre el back-end en `swipl`, para hacer consultas a mano |
| `mingw32-make clean` | borra la carpeta `build/` |

> **Ejecute siempre desde la raíz del proyecto** (por ejemplo, con `mingw32-make run`). El programa carga `backend/main.pl` y `datos/registros.txt` con rutas relativas.

---

## 5. Uso

Al iniciar, el programa carga los estudiantes guardados y muestra el menú:

```
   1. Registrar estudiante
   2. Registrar / quitar cursos aprobados
   3. Consultar plan de estudios
   4. Cursos disponibles para matricular
   5. Que me falta para llevar un curso
   6. Ruta de avance hacia un curso meta
   7. Detectar choques de horario
   8. Recomendar combinaciones de cursos
   9. Avance de carrera
  10. Generar reporte de planificacion
  11. Guardar / cargar sesion
  12. Recargar base de conocimientos
   0. Salir
```

**Convenciones:**
- **Carné:** 9 dígitos (cédula), por ejemplo `208490835`. Cuando se pide un carné, escriba **`?`** para ver la lista de estudiantes registrados.
- **Código de curso:** se acepta en mayúsculas o minúsculas, por ejemplo `EIF206`, `mat002`, `EG1` o `EIF420O`.
- **Enter vacío:** cancela la operación y vuelve al menú.
- Los cambios se **guardan automáticamente** en `datos/registros.txt`.

### Estudiantes de prueba incluidos

| Carné | Nombre | Situación |
|---|---|---|
| 208490835 | Lausen Paniagua Arias | mitad de II nivel |
| 111110001 | Ana Rojas Mora | primer ingreso |
| 111110002 | Carlos Vargas Solis | Diplomado completo |
| 111110003 | Maria Jimenez Castro | atrasada (sin LIX411 ni EIF202) |
| 111110004 | Jose Mendez Arias | ejemplo del enunciado |

### 5.1 Registrar estudiante (opción 1)
Pide el carné y el nombre completo.
```
Carne (9 digitos) (Enter para cancelar): 402220001
Nombre completo: Genesis Silesky Araya
Estudiante 402220001 registrado: Genesis Silesky Araya.
```

### 5.2 Registrar o quitar cursos aprobados (opción 2)
Primero pide el carné y luego abre un submenú: **1** ver aprobados, **2** agregar y **3** quitar. Al agregar o quitar puede escribir varios códigos seguidos; termine con Enter vacío.
```
Codigo del curso (Enter para terminar): eif200
Curso: EIF200 - Fundamentos de Informatica
EIF200 registrado como aprobado.
```
Si registra un curso sin tener sus requisitos, el sistema lo permite, pero avisa:
```
Advertencia: sus requisitos EIF204, MAT002 no estan registrados como aprobados.
```

### 5.3 Consultar el plan de estudios (opción 3)
Submenú con tres opciones:
1. **Por nivel:** cursos del 1 al 4.
2. **Por tipo:** obligatorio, general, optativo disciplinario u optativo libre.
3. **Requisitos de un curso:** requisitos directos e indirectos, correquisitos, cursos que desbloquea y horario.

### 5.4 Cursos disponibles (opción 4)
Lista, **en orden de prioridad**, los cursos que el estudiante puede matricular y explica por qué.
```
Codigo | Nombre           | Cr | Por que esta disponible
EIF206 | Programacion III | 4  | Tiene aprobados todos sus requisitos: EIF204, MAT002.
```
Los cursos atrasados (de niveles inferiores) aparecen primero.

### 5.5 ¿Qué me falta para llevar X? (opción 5)
```
Estado   | NO DISPONIBLE
Por que  | No esta disponible porque falta EIF212, que a su vez requiere EIF205;
         | EIF211, que a su vez requiere EIF206 y EIF207.
Faltan (directos) | EIF212, EIF211
Faltan (cadena completa, con correquisitos) | EIF205, EIF206, ...
Minimo de etapas (sin tope)   | 3
Ciclos estimados (tope 18 cr) | 3
```

### 5.6 Ruta de avance (opción 6)
Muestra el **plan por etapas** hasta el curso meta y las **rutas alternativas** (cadenas de requisitos):
```
Etapa 1 | EIF205, EIF206, EIF207 (11 creditos)
Etapa 2 | EIF209, EIF210, EIF211, EIF212 (15 creditos)
Etapa 3 | EIF401, EIF402 (8 creditos)
Ruta 1  | EIF205 -> EIF212 -> EIF402
Ruta 2  | EIF206 -> EIF211 -> EIF402
Ruta 3  | EIF207 -> EIF211 -> EIF402
```

### 5.7 Choques de horario (opción 7)
Escriba 2 o más cursos separados por espacio o coma, por ejemplo `EIF209 EIF210`. El sistema muestra cada choque y, si es posible, propone **grupos sin choque**:
```
Choque            | EIF209 G1 y EIF210 G1 coinciden el martes de 18:00 a 21:00.
Grupos sin choque | EIF209 G1 martes 18:00-21:00; EIF210 G2 miercoles 18:00-21:00
```

### 5.8 Recomendar combinaciones (opción 8)
Elija la modalidad: **1** para un ciclo (tope máximo 18 créditos) o **2** para un año (tope máximo 36). Luego ingrese el tope. El sistema muestra hasta 3 opciones (o el plan de los dos ciclos) y explica por qué recomienda cada curso.

### 5.9 Avance de carrera (opción 9)
Muestra los créditos aprobados, el porcentaje, el nivel actual, si cumple el Diplomado o el Bachillerato (y qué le falta) y las optativas.

### 5.10 Reporte de planificación (opción 10)
Genera `datos/reportes/reporte_<carne>.txt` con el avance, los aprobados, los disponibles, las recomendaciones y el plan hacia el Bachillerato.

### 5.11 Guardar o cargar la sesión (opción 11)
Guarda o vuelve a cargar `datos/registros.txt`. Normalmente no hace falta, porque cada cambio se guarda solo y el programa guarda también al salir.

### 5.12 Recargar la base de conocimientos (opción 12)
Si se modifica algún archivo `.pl` (por ejemplo, se agrega un requisito en `backend/hechos.pl`), esta opción lo recarga **sin cerrar el programa ni recompilar**.

---

## 6. Mensajes de error frecuentes

| Mensaje | Causa |
|---|---|
| `El carne debe tener exactamente 9 digitos.` | formato de carné inválido |
| `No existe un estudiante con carne ...` | el carné no está registrado (use `?` para ver la lista) |
| `Formato de codigo invalido ...` | el código no tiene la forma `EIF206`, `EG1`, etc. |
| `El curso '...' no existe en el plan de estudios.` | el código tiene buen formato, pero no está en el plan |
| `El tope de creditos por ciclo debe ser ... entre 1 y 18.` | tope mayor al permitido |
| `Opcion invalida. Elija un numero de la lista.` | opción del menú inexistente |
| `[i] El estudiante no tiene cursos aprobados.` | la consulta no tiene resultados |

---

## 7. Solución de problemas

| Problema | Solución |
|---|---|
| Al ejecutar aparece "no se encontró libswipl.dll" o el programa no abre | agregue `C:\Program Files\swipl\bin` al PATH (§2.1) y abra una terminal nueva |
| `No se encontro backend/main.pl` | ejecute desde la raíz del proyecto (`mingw32-make run`) |
| `gcc` o `mingw32-make` "no se reconoce" | instale WinLibs (§2.2) y abra una terminal nueva |
| `No se pudo cargar el back-end de Prolog` | hay un error en un `.pl`; ejecute `mingw32-make prolog` para verlo |

---

## 8. Archivos de datos

- **`datos/registros.txt`:** estudiantes y cursos aprobados, guardados como términos de Prolog, por ejemplo `estudiante(208490835, 'Lausen Paniagua Arias').` y `aprobado(208490835, eif200).`. Se puede editar a mano con el programa cerrado.
- **`datos/reportes/`:** reportes generados con la opción 10.
