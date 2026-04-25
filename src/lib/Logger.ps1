class Logger {
    [string]$Path

    Logger([string]$path) {
        $this.Path = $path
    }

    [void] Info([string]$message) {
        $this.Write('INFO', $message)
    }

    [void] Error([string]$message) {
        $this.Write('ERROR', $message)
    }

    hidden [void] Write([string]$level, [string]$message) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -Path $this.Path -Value "[$timestamp] [$level] $message" -Encoding UTF8
    }
}
