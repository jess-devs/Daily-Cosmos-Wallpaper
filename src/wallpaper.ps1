# ============================================================
# CosmoWallpaper - Orquestador principal
# Cada responsabilidad vive en su clase dentro de lib/
# ============================================================

$ErrorActionPreference = 'Stop'
$lib = Join-Path $PSScriptRoot 'lib'

. (Join-Path $lib 'Logger.ps1')
. (Join-Path $lib 'AppConfig.ps1')
. (Join-Path $lib 'ApodClient.ps1')
. (Join-Path $lib 'ImageCache.ps1')
. (Join-Path $lib 'WallpaperSetter.ps1')
. (Join-Path $lib 'NotifierLauncher.ps1')

$logger = [Logger]::new((Join-Path $PSScriptRoot 'wallpaper.log'))

try {
    # 1. Configuracion
    $config = [AppConfig]::Load((Join-Path $PSScriptRoot 'config.json'))

    # 2. Obtener APOD del dia
    $image = [ApodClient]::new($config.ApiKey).FetchToday()

    if (-not $image.IsImage()) {
        $logger.Info("APOD de hoy es '$($image.MediaType)' (no imagen). Titulo: $($image.Title). Saltando.")
        exit 0
    }

    # 3. Cache + descarga
    $cache = [ImageCache]::new((Join-Path $PSScriptRoot 'cache'), $config.CacheMaxDays)
    $localPath = $cache.Download($image.BestUrl(), $image.Date)
    $cache.Cleanup()

    # 4. Aplicar fondo de pantalla
    [WallpaperSetter]::new().Apply($localPath)

    # 5. Notificacion Toast (proceso hijo independiente)
    if ($config.Notifications) {
        $notifyScript = Join-Path $PSScriptRoot 'notify.ps1'
        [NotifierLauncher]::new($notifyScript).Launch($image)
    }

    $notifStatus = if ($config.Notifications) { 'si' } else { 'no' }
    $logger.Info("Fondo cambiado: $($image.Title) | Notificacion: $notifStatus")
}
catch {
    $logger.Error($_.Exception.Message)
    exit 1
}
