import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart'; // Para usar debugPrint

void main() async {
  debugPrint('🔍 Test simple de conexión a URLs...\n');

  final testUrls = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://www.instagram.com/nasa/',
    'https://www.tiktok.com/@nasa',
  ];

  for (final url in testUrls) {
    debugPrint('🔗 Probando conectividad a: $url');

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      );

      final response = await request.close();
      debugPrint('✅ Status: ${response.statusCode}');
      debugPrint('📄 Content-Type: ${response.headers.contentType}');

      // Leer una parte del contenido
      final contents = await response.transform(utf8.decoder).take(1000).join();

      // Verificar si contiene meta tags
      if (contents.contains('<meta property="og:image"') ||
          contents.contains('<meta name="twitter:image"')) {
        debugPrint('🖼️ Meta tags de imagen encontrados');
      } else {
        debugPrint('❌ No se encontraron meta tags de imagen');
      }

      client.close();
    } catch (e) {
      debugPrint('❌ Error: $e');
    }

    debugPrint('─' * 50);
  }

  debugPrint('🏁 Test de conectividad completado.');
}
