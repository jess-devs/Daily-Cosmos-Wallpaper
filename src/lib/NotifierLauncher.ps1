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

        $title = $image.Title -replace '"', "'" -replace '\r?\n', ' '
        $copyright = $image.CreditLine() -replace '"', "'" -replace '\r?\n', ' '
        $explanation = ($image.ShortExplanation(120) -replace '\r?\n', ' ').Trim() -replace '"', "'"

        Start-Process -FilePath 'powershell.exe' -ArgumentList @(
            '-ExecutionPolicy', 'Bypass',
            '-WindowStyle', 'Hidden',
            '-File', "`"$($this.ScriptPath)`"",
            '-Title', "`"$title`"",
            '-Date', "`"$($image.Date)`"",
            '-Copyright', "`"$copyright`"",
            '-Explanation', "`"$explanation`""
        ) -WindowStyle Hidden
    }
}
