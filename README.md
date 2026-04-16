# Daily Cosmos Wallpaper

Cambia automaticamente el fondo de pantalla de Windows cada dia usando la imagen astronomica del dia (APOD) de la NASA.

## Que hace

- Descarga la imagen del dia desde la API de NASA APOD
- Establece la imagen como fondo de pantalla (estilo Fill)
- Muestra una notificacion Toast con el titulo, fecha y descripcion de la imagen (opcional)
- Se ejecuta automaticamente cada dia a las 08:00 AM mediante una tarea programada
- Mantiene un cache local de imagenes con limpieza automatica

## Requisitos

- Windows 10/11 (build 1903+)
- PowerShell 5.1 (incluido en Windows)
- Sin dependencias externas

## Estructura

```
daily-cosmos-wallpaper/
  install.bat          <- Instalador/desinstalador (ejecutar como Admin)
  src/
    wallpaper.ps1      <- Script principal
    notify.ps1         <- Notificacion Toast nativa
    config.json        <- Configuracion por defecto
```

Al instalar, los archivos se copian a `C:\ProgramData\CosmoWallpaper\`.

## Instalacion

1. Clonar o descargar este repositorio
2. Click derecho en `install.bat` y seleccionar "Ejecutar como administrador"
3. Elegir la opcion [1] Instalar
4. Indicar si se desean notificaciones Toast (S/N)
5. El sistema se prueba automaticamente y el fondo cambiara a la imagen del dia

## Desinstalacion

1. Ejecutar `install.bat` como administrador
2. Elegir la opcion [2] Desinstalar
3. Se elimina la tarea programada y todos los archivos de `C:\ProgramData\CosmoWallpaper\`

## Configuracion

El archivo `C:\ProgramData\CosmoWallpaper\config.json` controla el comportamiento:

```json
{
  "apiKey": "DEMO_KEY",
  "changeTime": "08:00",
  "cacheMaxDays": 7,
  "notifications": true
}
```

- **apiKey**: clave de la API de NASA. `DEMO_KEY` funciona pero tiene limite de 30 peticiones/hora. Se puede obtener una clave propia gratis en https://api.nasa.gov/
- **changeTime**: hora de ejecucion diaria
- **cacheMaxDays**: dias que se conservan las imagenes en cache
- **notifications**: activar/desactivar notificaciones Toast

Las notificaciones tambien se pueden cambiar desde el menu del instalador (opcion [3]).

## Como funciona

1. `wallpaper.ps1` llama a la API de NASA APOD via `System.Net.WebClient`
2. Si la imagen del dia es una foto (no video), la descarga al cache local
3. Cambia el fondo de pantalla usando `SystemParametersInfo` (Win32 API via P/Invoke)
4. Si las notificaciones estan activas, lanza `notify.ps1` como proceso separado
5. Registra la actividad en `wallpaper.log`
