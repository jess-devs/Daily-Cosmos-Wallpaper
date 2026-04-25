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

        [CosmoWallpaperNative]::SystemParametersInfo(
            [WallpaperSetter]::SPI_SET,
            0,
            $absolutePath,
            [WallpaperSetter]::SPI_SEND
        ) | Out-Null
    }

    # Carga el tipo P/Invoke solo una vez por proceso
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
