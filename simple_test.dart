import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🔍 Prueba simple de extracción de miniaturas...\n');

  // Probar YouTube
  final youtubeVideoId = 'dQw4w9WgXcQ';
  final youtubeThumbnails = [
    'https://img.youtube.com/vi/$youtubeVideoId/maxresdefault.jpg',
    'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg',
    'https://img.youtube.com/vi/$youtubeVideoId/mqdefault.jpg',
    'https://img.youtube.com/vi/$youtubeVideoId/default.jpg',
  ];
  debugPrint('📹 Probando miniaturas de YouTube:');
  for (final url in youtubeThumbnails) {
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          debugPrint('✅ $url - OK ($contentType)');
        } else {
          debugPrint('❌ $url - No es imagen ($contentType)');
        }
      } else {
        debugPrint('❌ $url - HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ $url - Error: $e');
    }
  }
  debugPrint('\n🌐 Probando extracción HTML genérica:');
  final testUrls = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://github.com/',
  ];

  for (final url in testUrls) {
    try {
      debugPrint('\n🔍 Extrayendo de: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final html = response.body;

        // Buscar og:image de manera simple
        if (html.contains('og:image')) {
          final startIndex = html.indexOf('og:image');
          final contentStart = html.indexOf('content=', startIndex);
          if (contentStart != -1) {
            debugPrint('✅ Encontrado meta tag og:image');
          }
        }

        // Buscar twitter:image
        if (html.contains('twitter:image')) {
          final startIndex = html.indexOf('twitter:image');
          final contentStart = html.indexOf('content=', startIndex);
          if (contentStart != -1) {
            debugPrint('✅ Encontrado meta tag twitter:image');
          }
        }

        if (!html.contains('og:image') && !html.contains('twitter:image')) {
          debugPrint('❌ No se encontraron meta tags de imagen');
        }
      } else {
        debugPrint('❌ HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  debugPrint('\n🏁 Prueba completada');
}
