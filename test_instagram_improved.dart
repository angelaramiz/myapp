import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/instagram_extraction_service_improved.dart';

// Para ejecutar desde el directorio raíz del proyecto

void main() async {
  debugPrint('🔍 Test del servicio mejorado de Instagram...\n');
  debugPrint('Iniciando pruebas...');

  final testUrls = [
    'https://www.instagram.com/p/CwX1234567/', // Post que probablemente no existe
    'https://www.instagram.com/reel/CwY7890123/', // Reel que probablemente no existe
    'https://www.instagram.com/nasa/', // Perfil verificado real
  ];

  for (final url in testUrls) {
    debugPrint('🔗 Probando URL: $url');
    debugPrint('─' * 50);

    try {
      final result = await InstagramExtractionServiceImproved.getInstagramInfo(
        url,
      );

      if (result != null) {
        debugPrint('✅ ÉXITO:');
        debugPrint('  📝 Título: ${result['title']}');
        debugPrint('  📄 Descripción: ${result['description']}');
        debugPrint('  🖼️ Thumbnail: ${result['thumbnail']}');
        debugPrint('  🔗 URL: ${result['url']}');

        // Verificar si el thumbnail es accesible
        if (result['thumbnail']?.isNotEmpty == true) {
          try {
            final request = await HttpClient().headUrl(
              Uri.parse(result['thumbnail']!),
            );
            final response = await request.close();
            debugPrint('  ✅ Thumbnail verificado: ${response.statusCode}');
          } catch (e) {
            debugPrint('  ⚠️ Error verificando thumbnail: $e');
          }
        }
      } else {
        debugPrint('❌ FALLÓ: No se pudo extraer información');
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
    }

    debugPrint('\n${'═' * 70}\n');
  }

  debugPrint('🏁 Test completado.');
}
