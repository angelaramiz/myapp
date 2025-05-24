# Script para probar la extracción de miniaturas
# test_thumbnails.ps1

Write-Host "🔍 Iniciando pruebas de extracción de miniaturas..." -ForegroundColor Cyan
Write-Host ""

# Verificar que Flutter esté disponible
if (!(Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Ejecutar el test de extracción
Write-Host "🧪 Ejecutando test de extracción..." -ForegroundColor Yellow
try {
    flutter run test_thumbnail_extraction.dart --no-sound-null-safety
} catch {
    Write-Host "❌ Error ejecutando el test: $_" -ForegroundColor Red
    
    # Alternativa: ejecutar como archivo Dart simple
    Write-Host "🔄 Intentando ejecutar como archivo Dart..." -ForegroundColor Yellow
    dart test_thumbnail_extraction.dart
}

Write-Host ""
Write-Host "✅ Pruebas completadas" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Notas importantes:" -ForegroundColor Cyan
Write-Host "• Las pruebas verifican la extracción de miniaturas de diferentes plataformas"
Write-Host "• Se prueban múltiples métodos de extracción"
Write-Host "• Los resultados muestran qué URLs funcionan mejor"
Write-Host "• Revisa los logs para ver detalles de la extracción"
Write-Host ""
Write-Host "🚀 Para probar en la app real:"
Write-Host "1. Compila la app: flutter build apk"
Write-Host "2. Instala en dispositivo: flutter install"
Write-Host "3. Comparte enlaces desde otras apps"
Write-Host "4. Verifica que aparezcan las miniaturas en el modal"
