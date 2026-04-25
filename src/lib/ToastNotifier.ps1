class ToastNotifier {
    static [string]$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\explorer.exe'

    # Muestra una notificacion Toast con los datos del APOD
    # Silencia cualquier error para nunca interrumpir el flujo principal
    [void] Show([string]$title, [string]$date, [string]$copyright, [string]$explanation) {
        try {
            [void][Windows.UI.Notifications.ToastNotificationManager, 
            Windows.UI.Notifications, ContentType = WindowsRuntime]
            [void][Windows.Data.Xml.Dom.XmlDocument, 
            Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

            $t = [System.Security.SecurityElement]::Escape($title)
            $e = [System.Security.SecurityElement]::Escape($explanation)
            $d = [System.Security.SecurityElement]::Escape($date)
            $c = [System.Security.SecurityElement]::Escape($copyright)

            $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            $xml.LoadXml(@"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>NASA - Imagen del dia: $t</text>
      <text>$e</text>
      <text>Fecha: $d | Credito: $c</text>
    </binding>
  </visual>
</toast>
"@)
            $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(
                [ToastNotifier]::AppId
            ).Show($toast)
        }
        catch {
            # Silenciar — las notificaciones nunca deben romper el flujo principal
        }
    }
}
