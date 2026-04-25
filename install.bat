@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title CosmoWallpaper - Instalador

set "INSTALL_DIR=%ProgramData%\CosmoWallpaper"
set "TASK_NAME=NASADailyWallpaper"
set "SRC_DIR=%~dp0src"

:: --- Verificar permisos de Administrador ---
>nul 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\config\system"
if '%errorlevel%' NEQ '0' (
  echo.
  echo [!] Se requieren permisos de Administrador.
  echo  Solicitando elevacion UAC...
  echo.
  echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\cosmowp_uac.vbs"
  echo UAC.ShellExecute "cmd.exe", "/c ""%~f0""", "", "runas", 1 >> "%temp%\cosmowp_uac.vbs"
  "%temp%\cosmowp_uac.vbs"
  del /f /q "%temp%\cosmowp_uac.vbs" >nul 2>&1
  exit /B
)

:MENU
cls
echo.
echo  ============================================
echo  CosmoWallpaper - NASA APOD Diario
echo  ============================================
echo.
echo  [1] Instalar
echo  [2] Desinstalar
echo  [3] Configurar notificaciones
echo  [4] Salir
echo.
set /p "opcion=  Selecciona una opcion [1-4]: "

if "%opcion%"=="1" goto INSTALL
if "%opcion%"=="2" goto UNINSTALL
if "%opcion%"=="3" goto CONFIG_NOTIFY
if "%opcion%"=="4" goto EXIT
echo.
echo  [!] Opcion no valida.
timeout /t 2 >nul
goto MENU

:: ============================================================
:: OPCION 1 - INSTALAR
:: ============================================================
:INSTALL
cls
echo.
echo  --- Instalacion de CosmoWallpaper ---
echo.

:: Verificar que el directorio src existe junto al bat
if not exist "%SRC_DIR%\wallpaper.ps1" (
  echo  [X] No se encontro la carpeta src junto a install.bat.
  echo  Asegurate de ejecutar el instalador desde la raiz del repositorio.
  echo.
  pause
  goto MENU
)

:: Detectar instalacion previa
if exist "%INSTALL_DIR%\wallpaper.ps1" (
  echo  [!] Se detecto una instalacion previa.
  set /p "overwrite=  Deseas sobreescribir? [S/N]: "
  if /i "!overwrite!" NEQ "S" (
    echo.
    echo  Instalacion cancelada.
    timeout /t 3 >nul
    goto MENU
  )
)

echo.
echo  [1/5] Creando directorios...
if not exist "%INSTALL_DIR%"        mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\cache"  mkdir "%INSTALL_DIR%\cache"

echo  [2/5] Copiando archivos...
xcopy "%SRC_DIR%\*" "%INSTALL_DIR%\" /E /I /Y /Q >nul
if !errorlevel! NEQ 0 (
  echo  [X] Error al copiar los archivos.
  goto INSTALL_FAIL
)

echo  [3/5] Configurando preferencias...
echo.
set /p "notif=  Deseas recibir notificaciones al cambiar el fondo? [S/N]: "
set "NOTIF_VAL=false"
if /i "%notif%"=="S" set "NOTIF_VAL=true"
powershell -ExecutionPolicy Bypass -Command ^
"$c=Get-Content '%INSTALL_DIR%\config.json' -Raw|ConvertFrom-Json;$c.notifications=[bool]::Parse('%NOTIF_VAL%');$c|ConvertTo-Json|Set-Content '%INSTALL_DIR%\config.json' -Encoding UTF8"
if /i "%notif%"=="S" (echo  Notificaciones: ACTIVADAS) else (echo  Notificaciones: DESACTIVADAS)

echo.
echo  [4/5] Creando tarea programada (diario 08:00 AM)...
schtasks /create /tn "%TASK_NAME%" ^
/tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%INSTALL_DIR%\wallpaper.ps1\"" ^
/sc daily /st 08:00 /ru "%USERNAME%" /rl LIMITED /f
if !errorlevel! NEQ 0 (
  echo  [X] Error al crear la tarea programada.
  goto INSTALL_FAIL
)
echo  Tarea "%TASK_NAME%" creada correctamente.

echo.
echo  [5/5] Ejecutando prueba inicial...
echo.
powershell -ExecutionPolicy Bypass -File "%INSTALL_DIR%\wallpaper.ps1"
if !errorlevel! NEQ 0 goto TEST_FAIL

echo.
echo  ============================================
echo  Instalacion completada exitosamente!
echo  ============================================
echo.
echo  Directorio : %INSTALL_DIR%
echo  Tarea  : %TASK_NAME% (diario 08:00 AM)
echo  El fondo de pantalla ha sido actualizado.
echo.
goto TEST_DONE

:TEST_FAIL
echo.
echo  [!] La prueba inicial tuvo un error.
echo  Revisa: %INSTALL_DIR%\wallpaper.log
echo  La tarea se creo de todas formas y reintentara manana.
echo.

:TEST_DONE
echo  Presiona una tecla para continuar...
pause >nul
goto MENU

:INSTALL_FAIL
echo.
echo  [X] La instalacion fallo. Revisa los permisos y reintenta.
echo.
echo  Presiona una tecla para continuar...
pause >nul
goto MENU

:: ============================================================
:: OPCION 2 - DESINSTALAR
:: ============================================================
:UNINSTALL
cls
echo.
echo  --- Desinstalacion de CosmoWallpaper ---
echo.

if not exist "%INSTALL_DIR%" (
  echo  [!] No se encontro una instalacion de CosmoWallpaper.
  echo.
  pause
  goto MENU
)

set /p "confirmar=  Confirmas desinstalar CosmoWallpaper? [S/N]: "
if /i "%confirmar%" NEQ "S" (
  echo.
  echo  Desinstalacion cancelada.
  timeout /t 2 >nul
  goto MENU
)

echo.
echo  [1/2] Eliminando tarea programada...
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
echo  Tarea eliminada.

echo  [2/2] Eliminando archivos...
rd /s /q "%INSTALL_DIR%" >nul 2>&1
echo  Directorio eliminado.

echo.
echo  ============================================
echo  Desinstalacion completada.
echo  ============================================
echo.
pause
goto MENU

:: ============================================================
:: OPCION 3 - CONFIGURAR NOTIFICACIONES
:: ============================================================
:CONFIG_NOTIFY
cls
echo.
echo  --- Configurar Notificaciones ---
echo.

if not exist "%INSTALL_DIR%\config.json" (
  echo  [!] No se encontro config.json. Instala primero.
  echo.
  pause
  goto MENU
)

:: Leer estado actual
for /f "delims=" %%A in ('powershell -ExecutionPolicy Bypass -Command ^
"(Get-Content '%INSTALL_DIR%\config.json' -Raw | ConvertFrom-Json).notifications"') do set "CURRENT=%%A"

if /i "%CURRENT%"=="True" (
  echo  Estado actual: ACTIVADAS
  ) else (
  echo  Estado actual: DESACTIVADAS
)

echo.
set /p "newnotif=  Activar notificaciones? [S/N]: "
set "NOTIF_VAL=false"
if /i "%newnotif%"=="S" set "NOTIF_VAL=true"
powershell -ExecutionPolicy Bypass -Command ^
"$c=Get-Content '%INSTALL_DIR%\config.json' -Raw|ConvertFrom-Json;$c.notifications=[bool]::Parse('%NOTIF_VAL%');$c|ConvertTo-Json|Set-Content '%INSTALL_DIR%\config.json' -Encoding UTF8"
echo.
if /i "%newnotif%"=="S" (echo  Notificaciones: ACTIVADAS) else (echo  Notificaciones: DESACTIVADAS)

echo.
echo  Configuracion guardada.
echo.
pause
goto MENU

:: ============================================================
:: SALIR
:: ============================================================
:EXIT
echo.
echo  Hasta luego!
timeout /t 2 >nul
exit /B
