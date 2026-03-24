@echo off
:: =============================================================================
::
::   IniciarServidor.bat  —  Minecraft Server Manager Launcher
::   Lanzador del Gestor de Servidor Minecraft
::
::   WHAT IT DOES / QUE HACE:
::     Launches mortups.ps1 using PowerShell with the required flags.
::     Lanza mortups.ps1 usando PowerShell con los flags necesarios.
::
::   HOW TO USE / COMO USAR:
::     Double-click this file. That's it.
::     Hacé doble clic en este archivo. Eso es todo.
::
::   REQUIREMENTS / REQUISITOS:
::     · This file must be in the SAME folder as mortups.ps1
::       Este archivo debe estar en la MISMA carpeta que mortups.ps1
::     · Java must be installed (https://adoptium.net)
::       Java debe estar instalado
::     · 7-Zip must be installed (https://7-zip.org)
::       7-Zip debe estar instalado
::     · RCON must be enabled in server.properties
::       RCON debe estar habilitado en server.properties
::
::   NOTES / NOTAS:
::     -ExecutionPolicy Bypass  : Allows running .ps1 scripts without
::                                permanently changing system policy.
::                                Permite ejecutar scripts .ps1 sin cambiar
::                                permanentemente la política del sistema.
::     -NoProfile               : Skips loading the PowerShell user profile,
::                                making startup faster and avoiding conflicts.
::                                Omite cargar el perfil de usuario de PowerShell,
::                                haciendo el inicio más rápido y evitando conflictos.
::
:: =============================================================================

title mortups — Server 1.12.2
color 0A

echo.
echo  +--------------------------------------------------+
echo  ^|         mortups  v1.0  by mortamc           ^|
echo  +--------------------------------------------------+
echo  ^|  Starting... / Iniciando...                      ^|
echo  +--------------------------------------------------+
echo.

:: ── Check 1: PowerShell is available ──────────────────────────────────────
:: ── Verificacion 1: PowerShell esta disponible ────────────────────────────
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] PowerShell was not found on this system.
    echo  [ERROR] PowerShell no fue encontrado en este sistema.
    echo.
    echo  PowerShell is included with Windows 7 and later.
    echo  PowerShell viene incluido con Windows 7 y versiones posteriores.
    pause
    exit /b 1
)

:: ── Check 2: Java is in the PATH ──────────────────────────────────────────
:: ── Verificacion 2: Java esta en el PATH ──────────────────────────────────
where java >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] Java was not found in the system PATH.
    echo  [ERROR] Java no fue encontrado en el PATH del sistema.
    echo.
    echo  Download Java 8 from: https://adoptium.net
    echo  Descarga Java 8 desde: https://adoptium.net
    echo.
    echo  After installing, make sure to check "Add to PATH" during setup.
    echo  Al instalar, asegurate de marcar "Agregar al PATH" durante la instalacion.
    pause
    exit /b 1
)

:: ── Check 3: mortups.ps1 is in the same folder ───────────────────
:: ── Verificacion 3: mortups.ps1 esta en la misma carpeta ─────────
if not exist "%~dp0mortups.ps1" (
    echo  [ERROR] mortups.ps1 was not found in this folder.
    echo  [ERROR] mortups.ps1 no fue encontrado en esta carpeta.
    echo.
    echo  Both files must be in the same folder as server.jar
    echo  Ambos archivos deben estar en la misma carpeta que server.jar
    echo.
    echo  Expected path / Ruta esperada:
    echo  %~dp0mortups.ps1
    pause
    exit /b 1
)

echo  All checks passed. Launching manager...
echo  Todas las verificaciones pasaron. Iniciando manager...
echo.

:: ── Launch the PowerShell script ──────────────────────────────────────────
:: ── Lanzar el script de PowerShell ────────────────────────────────────────
::
:: %~dp0 is the directory of this .bat file (with trailing backslash).
:: Using it ensures the script is found regardless of the current working directory.
:: %~dp0 es el directorio de este archivo .bat (con barra invertida al final).
:: Usarlo garantiza que el script se encuentre sin importar el directorio de trabajo actual.
::
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0mortups.ps1"
