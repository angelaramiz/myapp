import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  debugPrint('ðŸ” Test simple de miniaturas...\n');

  // URLs de prueba simples
  final testUrls = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://www.instagram.com/p/ABC123/',
    'https://www.tiktok.com/@test/video/123456789',
  ];

  for (final url in testUrls) {
    debugPrint('ðŸ”— Probando: $url');

    try {
      // Headers bÃ¡sicos que imitan un navegador
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
      };

      debugPrint('  ðŸ“¡ Enviando peticiÃ³n HTTP...');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('  ðŸ“Š Status: ${response.statusCode}');
      debugPrint('  ðŸ“Š Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('  ðŸ“„ HTML obtenido: ${html.length} caracteres');

        // Buscar meta tags de imagen
        final ogImagePattern = RegExp(
          r'<meta[^>]+property="og:image"[^>]+content="([^"]+)"',
          caseSensitive: false,
        );
        final twitterImagePattern = RegExp(
          r'<meta[^>]+name="twitter:image"[^>]+content="([^"]+)"',
          caseSensitive: false,
        );

        final ogMatches = ogImagePattern.allMatches(html);
        final twitterMatches = twitterImagePattern.allMatches(html);

        debugPrint('  ðŸ–¼ï¸  og:image encontrados: ${ogMatches.length}');
        for (final match in ogMatches.take(2)) {
          final imageUrl = match.group(1);
          debugPrint('    - $imageUrl');

          // Verificar si la imagen es accesible
          try {
            final imgResponse = await http
                .head(Uri.parse(imageUrl!))
                .timeout(const Duration(seconds: 5));
            debugPrint(
              '      âœ… Imagen verificada: ${imgResponse.statusCode}',
            );
          } catch (e) {
            debugPrint('      âŒ Error verificando imagen: $e');
          }
        }

        debugPrint(
          '  ðŸ¦ twitter:image encontrados: ${twitterMatches.length}',
        );
        for (final match in twitterMatches.take(2)) {
          final imageUrl = match.group(1);
          debugPrint('    - $imageUrl');
        }

        if (ogMatches.isEmpty && twitterMatches.isEmpty) {
          debugPrint(
            '  âš ï¸  No se encontraron meta tags de imagen estÃ¡ndar',
          );

          // Buscar otros patrones posibles
          final imgPattern = RegExp(
            r'<img[^>]+src="([^"]+)"',
            caseSensitive: false,
          );
          final imgMatches = imgPattern.allMatches(html);
          debugPrint('  ðŸ” Tags <img> encontrados: ${imgMatches.length}');

          for (final match in imgMatches.take(3)) {
            debugPrint('    - ${match.group(1)}');
          }
        }
      } else {
        debugPrint('  âŒ Error HTTP: ${response.statusCode}');
        debugPrint(
          '  ðŸ“ Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );
      }
    } catch (e) {
      debugPrint('  âŒ Error: $e');
    }

    debugPrint('${'â”€' * 80}\n');
  }

  debugPrint('ðŸ Test completado.');
}
