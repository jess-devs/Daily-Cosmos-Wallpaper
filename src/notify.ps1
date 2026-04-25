# ============================================================
# CosmoWallpaper - Proceso hijo para notificaciones Toast
# Ejecutado de forma aislada por NotifierLauncher
# ============================================================
param(
    [string]$Title,
    [string]$Date,
    [string]$Copyright,
    [string]$Explanation
)

. (Join-Path $PSScriptRoot 'lib\ToastNotifier.ps1')
[ToastNotifier]::new().Show($Title, $Date, $Copyright, $Explanation)
