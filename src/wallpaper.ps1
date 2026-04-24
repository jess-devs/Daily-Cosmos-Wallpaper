# PS 5.1 defaults to TLS 1.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptDir = $PSScriptRoot
$configPath = Join-Path $scriptDir "config.json"
$cachePath = Join-Path $scriptDir "cache"
$logPath = Join-Path $scriptDir "wallpaper.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message" -Encoding UTF8
}

try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    $client = New-Object System.Net.WebClient
    $client.Encoding = [System.Text.Encoding]::UTF8
    $apod = $client.DownloadString("https://api.nasa.gov/planetary/apod?api_key=$($config.apiKey)") | ConvertFrom-Json

    if ($apod.media_type -ne "image") {
        Write-Log "APOD de hoy es '$($apod.media_type)' (no imagen). Titulo: $($apod.title). Saltando."
        exit 0
    }

    $imageUrl = if ($apod.hdurl) { $apod.hdurl } else { $apod.url }

    if (-not (Test-Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    $ext = [System.IO.Path]::GetExtension(([Uri]$imageUrl).AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($ext)) { $ext = ".jpg" }

    $localPath = Join-Path $cachePath "$($apod.date)$ext"

    if (-not (Test-Path $localPath)) {
        $client.DownloadFile($imageUrl, $localPath)
    }

    # WallpaperStyle 10 = Fill
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'

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
    [CosmoWallpaper]::SystemParametersInfo(0x0014, 0, $localPath, 0x03) | Out-Null

    $cutoff = (Get-Date).AddDays(-$config.cacheMaxDays)
    Get-ChildItem $cachePath -File | Where-Object { $_.LastWriteTime -lt $cutoff } | Remove-Item -Force -ErrorAction SilentlyContinue

    if ($config.notifications -eq $true) {
        $explanation = $apod.explanation
        if ($explanation.Length -gt 120) {
            $explanation = $explanation.Substring(0, 120) + "..."
        }

        $notifyScript = Join-Path $scriptDir "notify.ps1"
        if (Test-Path $notifyScript) {
            Start-Process -FilePath "powershell.exe" -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-File", "`"$notifyScript`"",
                "-Title", "`"$($apod.title)`"",
                "-Date", "`"$($apod.date)`"",
                "-Copyright", "`"$($apod.copyright)`"",
                "-Explanation", "`"$explanation`""
            ) -WindowStyle Hidden
        }
    }

    Write-Log "Fondo cambiado: $($apod.title) | Notificacion: $(if ($config.notifications) { 'si' } else { 'no' })"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    if ($client) { $client.Dispose() }
}
