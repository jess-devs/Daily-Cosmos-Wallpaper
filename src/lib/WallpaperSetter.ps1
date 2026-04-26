# Regular function so [CosmoWallpaperNative] is resolved at call time, not at class-parse time
function Invoke-NativeSPI {
    param([int]$action, [string]$path, [int]$flags)
    return [CosmoWallpaperNative]::SystemParametersInfo($action, 0, $path, $flags)
}

class WallpaperSetter {
    # Win32 API: SPI_SETDESKWALLPAPER = 0x0014
    static [int]$SPI_SET = 0x0014
    # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 0x03
    static [int]$SPI_SEND = 0x03
    # WallpaperStyle 10 = Fill
    static [int]$STYLE_FILL = 10

    WallpaperSetter() {
        $this.RegisterNativeType()
    }

    # Aplica la imagen indicada como fondo de pantalla (estilo Fill)
    [void] Apply([string]$absolutePath) {
        Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle `
            -Value ([string][WallpaperSetter]::STYLE_FILL)
        Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper `
            -Value '0'

        $ok = Invoke-NativeSPI -action ([WallpaperSetter]::SPI_SET) `
            -path $absolutePath `
            -flags ([WallpaperSetter]::SPI_SEND)
        if ($ok -eq 0) { throw "SystemParametersInfo falló al aplicar el fondo (ruta: $absolutePath)" }
    }

    # Registra el tipo P/Invoke una sola vez por proceso; debe correr antes de Apply
    hidden [void] RegisterNativeType() {
        if (([System.Management.Automation.PSTypeName]'CosmoWallpaperNative').Type) { return }

        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class CosmoWallpaperNative {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int SystemParametersInfo(
        int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    }
}
