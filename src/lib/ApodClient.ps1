# ---------------------------------------------------------------------------
# Modelo: representa la respuesta de la API APOD
# ---------------------------------------------------------------------------
class ApodImage {
    [string]$Title
    [string]$Date
    [string]$MediaType
    [string]$Url
    [string]$HdUrl
    [string]$Copyright
    [string]$Explanation

    # Retorna true cuando el APOD del dia es una imagen (no video)
    [bool] IsImage() {
        return $this.MediaType -eq 'image'
    }

    # Prefiere la URL HD; cae en SD si no existe
    [string] BestUrl() {
        if (-not [string]::IsNullOrWhiteSpace($this.HdUrl)) { return $this.HdUrl }
        return $this.Url
    }

    # Credito normalizado: devuelve "NASA / Public Domain" si el campo esta vacio
    [string] CreditLine() {
        if ([string]::IsNullOrWhiteSpace($this.Copyright)) { return 'NASA / Public Domain' }
        return $this.Copyright.Trim()
    }

    # Descripcion recortada a maxLen caracteres para notificaciones
    [string] ShortExplanation([int]$maxLen) {
        if ([string]::IsNullOrWhiteSpace($this.Explanation)) { return '' }
        if ($this.Explanation.Length -le $maxLen) { return $this.Explanation }
        return $this.Explanation.Substring(0, $maxLen) + '...'
    }
}

# ---------------------------------------------------------------------------
# Servicio: consume la API NASA APOD
# ---------------------------------------------------------------------------
class ApodClient {
    static [string]$Endpoint = 'https://api.nasa.gov/planetary/apod'

    [string]$ApiKey

    ApodClient([string]$apiKey) {
        [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $this.ApiKey = $apiKey
    }

    # Descarga y deserializa el APOD del dia; lanza excepcion si falla la red
    [ApodImage] FetchToday() {
        $url = "$([ApodClient]::Endpoint)?api_key=$($this.ApiKey)"
        $client = New-Object System.Net.WebClient
        $client.Encoding = [System.Text.Encoding]::UTF8
        $raw = $null
        try {
            $raw = ($client.DownloadString($url) | ConvertFrom-Json)
        }
        finally {
            $client.Dispose()
        }

        $img = [ApodImage]::new()
        $img.Title = $raw.title
        $img.Date = $raw.date
        $img.MediaType = $raw.media_type
        $img.Url = $raw.url
        $img.HdUrl = $raw.hdurl
        $img.Copyright = $raw.copyright
        $img.Explanation = $raw.explanation
        return $img
    }
}
