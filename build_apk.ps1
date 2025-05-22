Write-Host "=== GENERADOR DE APK SIMPLIFICADO ===" -ForegroundColor Cyan
Write-Host "Comenzando el proceso de generación de APK..." -ForegroundColor Green

# Crear carpeta de destino
$apkDir = ".\apk"
if (-Not (Test-Path $apkDir)) {
    Write-Host "Creando directorio para APKs..."
    New-Item -ItemType Directory -Path $apkDir | Out-Null
}

# Generar la APK en modo release
Write-Host "Generando APK release..." -ForegroundColor Yellow
flutter build apk --release

# Buscar la APK generada
Write-Host "Buscando APK generada..." -ForegroundColor Yellow
$apkPath = ".\build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $apkPath) {
    # Copiar a la carpeta de destino
    Write-Host "APK encontrada, copiando a la carpeta $apkDir" -ForegroundColor Green
    Copy-Item -Path $apkPath -Destination "$apkDir\app-release.apk" -Force
    
    $fullPath = (Get-Item "$apkDir\app-release.apk").FullName
    Write-Host "=== ÉXITO! ===" -ForegroundColor Green
    Write-Host "La APK ha sido generada y copiada a:" -ForegroundColor Yellow
    Write-Host $fullPath -ForegroundColor Cyan
} else {
    Write-Host "No se encontró la APK en la ruta esperada. La compilación podría haber fallado." -ForegroundColor Red
    
    # Buscar cualquier APK generada
    Write-Host "Buscando APKs en todo el proyecto..." -ForegroundColor Yellow
    $apkFiles = Get-ChildItem -Path ".\build" -Recurse -Filter "*.apk"
    
    if ($apkFiles.Count -gt 0) {
        Write-Host "Se encontraron $($apkFiles.Count) archivos APK:" -ForegroundColor Green
        foreach ($apk in $apkFiles) {
            Write-Host $apk.FullName -ForegroundColor Cyan
            Copy-Item -Path $apk.FullName -Destination "$apkDir\$($apk.Name)" -Force
        }
        Write-Host "APKs copiadas al directorio: $apkDir" -ForegroundColor Green
    } else {
        Write-Host "No se encontraron archivos APK en ninguna ubicación." -ForegroundColor Red
    }
}
