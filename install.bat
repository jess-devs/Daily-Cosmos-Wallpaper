@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title CosmoWallpaper - Instalador

set "INSTALL_DIR=%ProgramData%\CosmoWallpaper"
set "TASK_NAME=NASADailyWallpaper"

:: --- Verificar permisos de Administrador ---
>nul 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\config\system"
if '%errorlevel%' NEQ '0' (
    echo.
    echo [!] Se requieren permisos de Administrador.
    echo     Solicitando elevacion UAC...
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
echo       CosmoWallpaper - NASA APOD Diario
echo  ============================================
echo.
echo   [1] Instalar
echo   [2] Desinstalar
echo   [3] Configurar notificaciones
echo   [4] Salir
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

:: OPCION 1 - INSTALAR
:INSTALL
cls
echo.
echo  --- Instalacion de CosmoWallpaper ---
echo.

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
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\cache" mkdir "%INSTALL_DIR%\cache"

echo  [2/5] Extrayendo archivos...

:: Extraer wallpaper.ps1
powershell -ExecutionPolicy Bypass -Command "$m='WALLPAPER_PS1';$c=Get-Content '%~f0' -Raw -Encoding UTF8;$p=$c -split ('::=== '+$m+' ===');if($p.Count -ge 3){[IO.File]::WriteAllText('%INSTALL_DIR%\wallpaper.ps1',$p[1].Trim(),[Text.UTF8Encoding]::new($false))}"

:: Extraer notify.ps1
powershell -ExecutionPolicy Bypass -Command "$m='NOTIFY_PS1';$c=Get-Content '%~f0' -Raw -Encoding UTF8;$p=$c -split ('::=== '+$m+' ===');if($p.Count -ge 3){[IO.File]::WriteAllText('%INSTALL_DIR%\notify.ps1',$p[1].Trim(),[Text.UTF8Encoding]::new($false))}"

:: Extraer config.json
powershell -ExecutionPolicy Bypass -Command "$m='CONFIG_JSON';$c=Get-Content '%~f0' -Raw -Encoding UTF8;$p=$c -split ('::=== '+$m+' ===');if($p.Count -ge 3){[IO.File]::WriteAllText('%INSTALL_DIR%\config.json',$p[1].Trim(),[Text.UTF8Encoding]::new($false))}"

:: Verificar extraccion
if not exist "%INSTALL_DIR%\wallpaper.ps1" (
    echo  [X] Error al extraer wallpaper.ps1
    goto INSTALL_FAIL
)
if not exist "%INSTALL_DIR%\notify.ps1" (
    echo  [X] Error al extraer notify.ps1
    goto INSTALL_FAIL
)
if not exist "%INSTALL_DIR%\config.json" (
    echo  [X] Error al extraer config.json
    goto INSTALL_FAIL
)

echo  [3/5] Configurando preferencias...
echo.
set /p "notif=  Deseas recibir notificaciones al cambiar el fondo? [S/N]: "
set "NOTIF_VAL=false"
if /i "%notif%"=="S" set "NOTIF_VAL=true"
powershell -ExecutionPolicy Bypass -Command "$c=Get-Content '%INSTALL_DIR%\config.json' -Raw|ConvertFrom-Json;$c.notifications=[bool]::Parse('%NOTIF_VAL%');$c|ConvertTo-Json|Set-Content '%INSTALL_DIR%\config.json' -Encoding UTF8"
if /i "%notif%"=="S" (echo  Notificaciones: ACTIVADAS) else (echo  Notificaciones: DESACTIVADAS)

echo.
echo  [4/5] Creando tarea programada (diario 08:00 AM)...
schtasks /create /tn "%TASK_NAME%" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%INSTALL_DIR%\wallpaper.ps1\"" /sc daily /st 08:00 /ru "%USERNAME%" /rl LIMITED /f
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
echo   Instalacion completada exitosamente!
echo  ============================================
echo.
echo   Directorio: %INSTALL_DIR%
echo   Tarea: %TASK_NAME% (diario 08:00 AM)
echo   El fondo de pantalla ha sido actualizado.
echo.
goto TEST_DONE

:TEST_FAIL
echo.
echo  [!] La prueba inicial tuvo un error.
echo      Revisa: %INSTALL_DIR%\wallpaper.log
echo      La tarea se creo de todas formas y reintentara manana.
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

:: OPCION 2 - DESINSTALAR
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
echo   Desinstalacion completada.
echo  ============================================
echo.
pause
goto MENU

:: OPCION 3 - CONFIGURAR NOTIFICACIONES
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
for /f "delims=" %%A in ('powershell -ExecutionPolicy Bypass -Command "(Get-Content '%INSTALL_DIR%\config.json' -Raw | ConvertFrom-Json).notifications"') do set "CURRENT=%%A"

if /i "%CURRENT%"=="True" (
    echo  Estado actual: ACTIVADAS
) else (
    echo  Estado actual: DESACTIVADAS
)

echo.
set /p "newnotif=  Activar notificaciones? [S/N]: "
set "NOTIF_VAL=false"
if /i "%newnotif%"=="S" set "NOTIF_VAL=true"
powershell -ExecutionPolicy Bypass -Command "$c=Get-Content '%INSTALL_DIR%\config.json' -Raw|ConvertFrom-Json;$c.notifications=[bool]::Parse('%NOTIF_VAL%');$c|ConvertTo-Json|Set-Content '%INSTALL_DIR%\config.json' -Encoding UTF8"
echo.
if /i "%newnotif%"=="S" (echo  Notificaciones: ACTIVADAS) else (echo  Notificaciones: DESACTIVADAS)

echo.
echo  Configuracion guardada.
echo.
pause
goto MENU

:: SALIR
:EXIT
echo.
echo  Hasta luego!
timeout /t 2 >nul
exit /B

:: ARCHIVOS EMBEBIDOS
:: Todo lo que sigue a "goto :eof" nunca es ejecutado por CMD.
:: PowerShell lee el BAT completo y extrae entre marcadores.
goto :eof
::=== WALLPAPER_PS1 ===
# ============================================================
# CosmoWallpaper - NASA APOD Daily Wallpaper
# ============================================================

# Forzar TLS 1.2 (PS 5.1 usa TLS 1.0 por defecto)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptDir = $PSScriptRoot
$configPath = Join-Path $scriptDir "config.json"
$cachePath  = Join-Path $scriptDir "cache"
$logPath    = Join-Path $scriptDir "wallpaper.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Add-Content -Path $logPath -Value $entry -Encoding UTF8
}

try {
    # --- 1. Leer configuracion ---
    if (-not (Test-Path $configPath)) {
        Write-Log "ERROR: config.json no encontrado en $configPath"
        exit 1
    }
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $apiKey       = $config.apiKey
    $cacheMaxDays = $config.cacheMaxDays
    $notify       = $config.notifications

    # --- 2. Llamar API NASA APOD ---
    $apiUrl = "https://api.nasa.gov/planetary/apod?api_key=$apiKey"
    $client = New-Object System.Net.WebClient
    $client.Encoding = [System.Text.Encoding]::UTF8
    $jsonResponse = $client.DownloadString($apiUrl)
    $apod = $jsonResponse | ConvertFrom-Json

    # --- 3. Verificar media_type ---
    if ($apod.media_type -ne "image") {
        Write-Log "APOD de hoy es '$($apod.media_type)' (no imagen). Titulo: $($apod.title). Saltando."
        exit 0
    }

    # --- 4. Determinar URL de imagen (preferir HD) ---
    $imageUrl = if ($apod.hdurl) { $apod.hdurl } else { $apod.url }

    # --- 5. Descargar imagen ---
    if (-not (Test-Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    # Detectar extension desde URL
    $uri = [Uri]$imageUrl
    $ext = [System.IO.Path]::GetExtension($uri.AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($ext)) { $ext = ".jpg" }

    $fileName  = "$($apod.date)$ext"
    $localPath = Join-Path $cachePath $fileName

    # Solo descargar si no existe ya
    if (-not (Test-Path $localPath)) {
        $client.DownloadFile($imageUrl, $localPath)
    }

    # --- 6. Limpiar cache antiguo ---
    $cutoff = (Get-Date).AddDays(-$cacheMaxDays)
    Get-ChildItem $cachePath -File | Where-Object { $_.LastWriteTime -lt $cutoff } | Remove-Item -Force -ErrorAction SilentlyContinue

    # --- 7. Establecer estilo de fondo (Fill = 10) ---
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'

    # --- 8. Cambiar fondo via P/Invoke SystemParametersInfo ---
    if (-not ([System.Management.Automation.PSTypeName]'CosmoWallpaper').Type) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class CosmoWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    }

    # SPI_SETDESKWALLPAPER = 0x0014, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 0x03
    $absolutePath = (Resolve-Path $localPath).Path
    [CosmoWallpaper]::SystemParametersInfo(0x0014, 0, $absolutePath, 0x03) | Out-Null

    # --- 9. Notificacion Toast (si habilitada) ---
    $notifyStatus = "no"
    if ($notify -eq $true) {
        $notifyStatus = "si"
        $copyright = if ($apod.copyright) { $apod.copyright } else { "NASA / Public Domain" }
        $explanation = $apod.explanation
        if ($explanation.Length -gt 120) {
            $explanation = $explanation.Substring(0, 120) + "..."
        }

        $notifyScript = Join-Path $scriptDir "notify.ps1"
        if (Test-Path $notifyScript) {
            Start-Process -FilePath "powershell.exe" -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Hidden",
                "-File", "`"$notifyScript`"",
                "-Title", "`"$($apod.title)`"",
                "-Date", "`"$($apod.date)`"",
                "-Copyright", "`"$copyright`"",
                "-Explanation", "`"$explanation`""
            ) -WindowStyle Hidden -NoNewWindow:$false
        }
    }

    # --- 10. Registrar en log ---
    Write-Log "Fondo cambiado: $($apod.title) | Notificacion: $notifyStatus"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    # Liberar WebClient si existe
    if ($client) { $client.Dispose() }
}
::=== WALLPAPER_PS1 ===
::=== NOTIFY_PS1 ===
param(
    [string]$Title,
    [string]$Date,
    [string]$Copyright,
    [string]$Explanation
)

try {
    # Cargar el assembly de Windows.UI.Notifications (WinRT en PowerShell 5.1)
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

    # Valores por defecto
    if ([string]::IsNullOrWhiteSpace($Copyright)) {
        $Copyright = "NASA / Public Domain"
    }

    # Escapar caracteres especiales XML
    $safeTitle       = [System.Security.SecurityElement]::Escape($Title)
    $safeExplanation = [System.Security.SecurityElement]::Escape($Explanation)
    $safeCopyright   = [System.Security.SecurityElement]::Escape($Copyright)
    $safeDate        = [System.Security.SecurityElement]::Escape($Date)

    # Construir XML del Toast
    $toastXml = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>NASA - Imagen del dia: $safeTitle</text>
      <text>$safeExplanation</text>
      <text>Fecha: $safeDate | Credito: $safeCopyright</text>
    </binding>
  </visual>
</toast>
"@

    # Crear documento XML y cargar contenido
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($toastXml)

    # AppId de Explorer (siempre registrado en Windows)
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\explorer.exe"

    # Crear y mostrar notificacion (fire-and-forget)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
}
catch {
    # Silenciar cualquier error — nunca romper el flujo principal
    exit 0
}
::=== NOTIFY_PS1 ===
::=== CONFIG_JSON ===
{
  "apiKey": "DEMO_KEY",
  "changeTime": "08:00",
  "cacheMaxDays": 7,
  "notifications": true
}
::=== CONFIG_JSON ===
