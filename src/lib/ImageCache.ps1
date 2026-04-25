class ImageCache {
    [string]$Root
    [int]   $MaxDays

    ImageCache([string]$root, [int]$maxDays) {
        $this.Root = $root
        $this.MaxDays = $maxDays
        $this.EnsureRoot()
    }

    # Descarga la imagen si no existe en cache; devuelve la ruta absoluta local
    [string] Download([string]$url, [string]$dateKey) {
        $ext = [System.IO.Path]::GetExtension(([Uri]$url).AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($ext)) { $ext = '.jpg' }

        $localPath = Join-Path $this.Root "$dateKey$ext"

        if (-not (Test-Path $localPath)) {
            $client = New-Object System.Net.WebClient
            try {
                $client.DownloadFile($url, $localPath)
            }
            finally {
                $client.Dispose()
            }
        }

        return (Resolve-Path $localPath).Path
    }

    # Elimina archivos con mas de MaxDays dias de antiguedad
    [void] Cleanup() {
        $cutoff = (Get-Date).AddDays(-$this.MaxDays)
        Get-ChildItem $this.Root -File |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    }

    # Crea el directorio raiz si no existe
    hidden [void] EnsureRoot() {
        if (-not (Test-Path $this.Root)) {
            New-Item -Path $this.Root -ItemType Directory -Force | Out-Null
        }
    }
}
