# Script para reemplazar print con debugPrint y agregar imports necesarios
Write-Host "🔧 Corrigiendo archivos de prueba..." -ForegroundColor Yellow

# Lista de archivos de prueba a corregir
$testFiles = @(
    "html_analysis_test.dart",
    "instagram_real_test.dart", 
    "simple_html_test.dart",
    "simple_thumbnail_test.dart",
    "test_instagram_improved.dart",
    "test_simple_verify.dart",
    "test_smart_thumbnails.dart"
)

foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Write-Host "📝 Corrigiendo $file..." -ForegroundColor Cyan
        
        # Leer contenido
        $content = Get-Content $file -Raw
        
        # Reemplazar print con debugPrint
        $content = $content -replace '\bprint\(', 'debugPrint('
        
        # Agregar import de Flutter si no existe
        if ($content -notmatch "import 'package:flutter/material\.dart';") {
            # Buscar línea después de imports dart:
            if ($content -match "(import 'dart:[^']+';[\r\n]+)") {
                $content = $content -replace "(import 'dart:[^']+';[\r\n]+)", "`$1import 'package:flutter/material.dart';`n"
            } elseif ($content -match "(import 'package:[^']+';[\r\n]+)") {
                # Si hay imports de package, agregar después del primero
                $content = $content -replace "(import 'package:[^']+';[\r\n]+)", "import 'package:flutter/material.dart';`n`$1"
            } else {
                # Agregar al principio
                $content = "import 'package:flutter/material.dart';`n" + $content
            }
        }
        
        # Remover import dart:async si no se usa
        if ($content -notmatch '\b(Stream|Future|Timer|Completer|StreamController)\b' -and $content -match "import 'dart:async';") {
            $content = $content -replace "import 'dart:async';[\r\n]+", ""
        }
        
        # Guardar archivo corregido
        $content | Out-File -FilePath $file -Encoding utf8 -NoNewline
        Write-Host "✅ $file corregido" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $file no encontrado" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Corrección completada!" -ForegroundColor Green
