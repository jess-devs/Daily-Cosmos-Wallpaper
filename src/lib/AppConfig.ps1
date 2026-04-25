class AppConfig {
    [string]$ApiKey
    [string]$ChangeTime
    [int]   $CacheMaxDays
    [bool]  $Notifications

    static [AppConfig] Load([string]$path) {
        if (-not (Test-Path $path)) {
            throw "config.json no encontrado en: $path"
        }

        $raw = Get-Content $path -Raw | ConvertFrom-Json

        $cfg = [AppConfig]::new()
        $cfg.ApiKey = $raw.apiKey
        $cfg.ChangeTime = $raw.changeTime
        $cfg.CacheMaxDays = [int]$raw.cacheMaxDays
        $cfg.Notifications = [bool]$raw.notifications
        return $cfg
    }
}
