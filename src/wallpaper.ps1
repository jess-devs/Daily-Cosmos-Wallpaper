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
