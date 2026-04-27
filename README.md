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
  install.bat              <- Instalador/desinstalador (ejecutar como Admin)
  src/
    wallpaper.ps1          <- Orquestador principal
    notify.ps1             <- Notificacion Toast nativa
    config.json            <- Configuracion por defecto
    lib/
      AppConfig.ps1        <- Lectura y validacion de config.json
      ApodClient.ps1       <- Cliente HTTP para la API NASA APOD
      ImageCache.ps1       <- Descarga y limpieza del cache local
      WallpaperSetter.ps1  <- Aplica el fondo via Win32 API (P/Invoke)
      NotifierLauncher.ps1 <- Lanza notify.ps1 como proceso independiente
      Logger.ps1           <- Escritura de wallpaper.log
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

1. `wallpaper.ps1` carga la configuracion via `AppConfig` y delega cada paso a su clase correspondiente en `lib/`
2. `ApodClient` consulta la API NASA APOD con `System.Net.WebClient` y deserializa la respuesta
3. Si el APOD del dia es un video (no imagen), el proceso termina sin error
4. `ImageCache` descarga la imagen HD (o SD como fallback) al cache local y elimina entradas antiguas
5. `WallpaperSetter` aplica la imagen usando `SystemParametersInfo` (Win32 API via P/Invoke)
6. Si las notificaciones estan activas, `NotifierLauncher` ejecuta `notify.ps1` como proceso hijo independiente
7. `Logger` registra el resultado (o el error) en `wallpaper.log`
