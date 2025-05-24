import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  debugPrint('🔍 Análisis detallado del HTML de Instagram y TikTok...\n');

  final testUrls = [
    {
      'platform': 'Instagram',
      'url': 'https://www.instagram.com/',
      'description': 'Instagram homepage',
    },
    {
      'platform': 'TikTok',
      'url': 'https://www.tiktok.com/',
      'description': 'TikTok homepage',
    },
  ];

  for (final testCase in testUrls) {
    debugPrint('🔗 Analizando ${testCase['platform']}: ${testCase['url']}');

    try {
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en;q=0.5',
        'Referer': 'https://www.google.com/',
      };

      final response = await http
          .get(Uri.parse(testCase['url']!), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('  📄 HTML length: ${html.length} caracteres');

        // Verificar si contiene JavaScript
        final jsPattern = RegExp(
          r'<script[^>]*>(.*?)</script>',
          caseSensitive: false,
          dotAll: true,
        );
        final jsMatches = jsPattern.allMatches(html);
        debugPrint('  🟨 Scripts JavaScript encontrados: ${jsMatches.length}');

        // Buscar cualquier referencia a imágenes
        final anyImagePattern = RegExp(
          r'(https?://[^"\s]+\.(jpg|jpeg|png|gif|webp))',
          caseSensitive: false,
        );
        final imageMatches = anyImagePattern.allMatches(html);
        debugPrint('  🖼️ URLs de imágenes en HTML: ${imageMatches.length}');

        for (final match in imageMatches.take(5)) {
          debugPrint('    - ${match.group(0)}');
        }

        // Buscar datos JSON embebidos
        final jsonPattern = RegExp(
          r'window\._sharedData\s*=\s*({.*?});',
          caseSensitive: false,
        );
        final jsonMatches = jsonPattern.allMatches(html);
        debugPrint(
          '  📊 Datos JSON embebidos (_sharedData): ${jsonMatches.length}',
        );

        // Buscar otros patrones de datos
        final dataPattern = RegExp(
          r'window\.__INITIAL_STATE__\s*=\s*({.*?});',
          caseSensitive: false,
        );
        final dataMatches = dataPattern.allMatches(html);
        debugPrint(
          '  📊 Datos iniciales (__INITIAL_STATE__): ${dataMatches.length}',
        ); // Buscar cualquier mención de 'thumbnail', 'preview', 'image'
        final thumbnailRefs = RegExp(
          r'(thumbnail|preview|image_url|cover)',
          caseSensitive: false,
        );
        final thumbMatches = thumbnailRefs.allMatches(html);
        debugPrint('  🔍 Referencias a miniaturas: ${thumbMatches.length}');

        for (final match in thumbMatches.take(3)) {
          debugPrint('    - ${match.group(0)}');
        }

        // Verificar si el contenido parece ser una SPA (Single Page Application)
        final reactPattern = RegExp(
          r'(react|vue|angular)',
          caseSensitive: false,
        );
        final spaIndicators = reactPattern.allMatches(html);
        debugPrint('  ⚙️ Indicadores SPA/Framework: ${spaIndicators.length}');

        // Mostrar una muestra del contenido
        debugPrint(
          '  📝 Muestra del contenido HTML (primeros 500 caracteres):',
        );
        debugPrint(
          '    ${html.substring(0, html.length > 500 ? 500 : html.length)}...',
        );
      } else {
        debugPrint('  ❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('  ❌ Error: $e');
    }

    debugPrint('${'─' * 80}\n');
  }

  debugPrint('🏁 Análisis completado.');
}
