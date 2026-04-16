param(
    [string]$Title,
    [string]$Date,
    [string]$Copyright,
    [string]$Explanation
)

try {
    # Cargar el assembly de Windows.UI.Notifications (WinRT en PowerShell 5.1)
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

    # Valores por defecto
    if ([string]::IsNullOrWhiteSpace($Copyright)) {
        $Copyright = "NASA / Public Domain"
    }

    # Escapar caracteres especiales XML
    $safeTitle       = [System.Security.SecurityElement]::Escape($Title)
    $safeExplanation = [System.Security.SecurityElement]::Escape($Explanation)
    $safeCopyright   = [System.Security.SecurityElement]::Escape($Copyright)
    $safeDate        = [System.Security.SecurityElement]::Escape($Date)

    # Construir XML del Toast
    $toastXml = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>NASA - Imagen del dia: $safeTitle</text>
      <text>$safeExplanation</text>
      <text>Fecha: $safeDate | Credito: $safeCopyright</text>
    </binding>
  </visual>
</toast>
"@

    # Crear documento XML y cargar contenido
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($toastXml)

    # AppId de Explorer (siempre registrado en Windows)
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\explorer.exe"

    # Crear y mostrar notificacion (fire-and-forget)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
}
catch {
    # Silenciar cualquier error — nunca romper el flujo principal
    exit 0
}
