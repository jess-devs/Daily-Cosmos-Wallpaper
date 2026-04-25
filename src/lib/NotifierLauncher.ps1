class NotifierLauncher {
    [string]$ScriptPath

    NotifierLauncher([string]$scriptPath) {
        $this.ScriptPath = $scriptPath
    }

    # Lanza notify.ps1 en un proceso oculto separado (fire-and-forget)
    # Recibe un objeto con los campos Title, Date, Copyright, Explanation y
    # el metodo ShortExplanation([int]) y CreditLine() — compatible con ApodImage
    [void] Launch([object]$image) {
        if (-not (Test-Path $this.ScriptPath)) { return }

        $explanation = $image.ShortExplanation(120)

        Start-Process -FilePath 'powershell.exe' -ArgumentList @(
            '-ExecutionPolicy', 'Bypass',
            '-WindowStyle', 'Hidden',
            '-File', "`"$($this.ScriptPath)`"",
            '-Title', "`"$($image.Title)`"",
            '-Date', "`"$($image.Date)`"",
            '-Copyright', "`"$($image.CreditLine())`"",
            '-Explanation', "`"$explanation`""
        ) -WindowStyle Hidden
    }
}
