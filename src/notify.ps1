param(
    [string]$Title,
    [string]$Date,
    [string]$Copyright,
    [string]$Explanation
)

try {
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

    if ([string]::IsNullOrWhiteSpace($Copyright)) {
        $Copyright = "NASA / Public Domain"
    }

    $safeTitle = [System.Security.SecurityElement]::Escape($Title)
    $safeExplanation = [System.Security.SecurityElement]::Escape($Explanation)
    $safeCopyright = [System.Security.SecurityElement]::Escape($Copyright)
    $safeDate = [System.Security.SecurityElement]::Escape($Date)

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

    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($toastXml)

    # AppId de Explorer (siempre registrado en Windows)
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\explorer.exe"

    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
}
catch {
    # Silenciar — nunca romper el flujo principal
    exit 0
}
