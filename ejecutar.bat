@echo off
rem ejecutar.bat - Lanza el Consejero Academico Inteligente en Windows.
rem Funciona con doble clic o desde cualquier terminal, aunque esta no
rem tenga el PATH actualizado.

rem 1) Ir a la raiz del proyecto (donde esta este archivo)
cd /d "%~dp0"

rem 2) SWI-Prolog (libswipl.dll) y GCC/Make de WinLibs en el PATH de esta ventana
set "PATH=C:\Program Files\swipl\bin;%PATH%"
set "WINLIBS=%LOCALAPPDATA%\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin"
if exist "%WINLIBS%" set "PATH=%WINLIBS%;%PATH%"

rem 3) Compilar si se puede (si no hay make, usa el ejecutable ya compilado)
where mingw32-make >nul 2>nul && mingw32-make --no-print-directory -s

if not exist "build\consejero.exe" (
    echo [ERROR] No existe build\consejero.exe y no se encontro mingw32-make para compilarlo.
    echo         Instale GCC/Make ^(ver documentacion\manual_usuario.md^).
    pause
    exit /b 1
)

rem 4) Ejecutar
build\consejero.exe
pause
