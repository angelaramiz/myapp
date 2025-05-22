Write-Host "Limpiando compilaciones anteriores..." -ForegroundColor Green
flutter clean

Write-Host "Obteniendo dependencias..." -ForegroundColor Green
flutter pub get

Write-Host "Generando APK de depuración..." -ForegroundColor Green
flutter build apk --debug

Write-Host "Generando APK de lanzamiento..." -ForegroundColor Green
flutter build apk --release

Write-Host "Creando directorio para APKs..." -ForegroundColor Green
$apkDir = ".\apk"
if (-Not (Test-Path $apkDir)) {
    New-Item -ItemType Directory -Path $apkDir
}

Write-Host "Buscando APKs generadas..." -ForegroundColor Green
$apkFiles = Get-ChildItem -Path ".\build" -Recurse -Filter "*.apk"

if ($apkFiles.Count -eq 0) {
    Write-Host "No se encontraron archivos APK. La compilación podría haber fallado." -ForegroundColor Red
} else {
    Write-Host "Se encontraron $($apkFiles.Count) archivos APK:" -ForegroundColor Green
    
    foreach ($apk in $apkFiles) {
        Write-Host "Copiando: $($apk.FullName)" -ForegroundColor Cyan
        Copy-Item -Path $apk.FullName -Destination "$apkDir\$($apk.Name)" -Force
    }
    
    Write-Host "APKs copiadas al directorio: $apkDir" -ForegroundColor Green
    Get-ChildItem -Path $apkDir
}
