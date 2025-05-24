import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  debugPrint('ðŸ” AnÃ¡lisis simple de HTML...\n');

  final testUrls = ['https://www.instagram.com/', 'https://www.tiktok.com/'];

  for (final url in testUrls) {
    debugPrint('ðŸ”— Analizando: $url');

    try {
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('  ðŸ“„ HTML length: ${html.length} caracteres');

        // Buscar scripts
        final scriptCount = RegExp(r'<script').allMatches(html).length;
        debugPrint('  ðŸŸ¨ Scripts encontrados: $scriptCount');

        // Buscar imÃ¡genes
        final imagePattern = RegExp(
          r'https?://[^\s"]+\.(jpg|jpeg|png|gif|webp)',
        );
        final images = imagePattern.allMatches(html);
        debugPrint('  ðŸ–¼ï¸  URLs de imÃ¡genes: ${images.length}');

        for (final match in images.take(3)) {
          debugPrint('    - ${match.group(0)}');
        }

        // Buscar meta tags
        final ogImage = RegExp(r'og:image').allMatches(html).length;
        final twitterImage = RegExp(r'twitter:image').allMatches(html).length;
        debugPrint('  ðŸ“Š og:image: $ogImage, twitter:image: $twitterImage');

        // Mostrar inicio del HTML
        debugPrint('  ðŸ“ Inicio del HTML:');
        final sample = html.length > 300 ? html.substring(0, 300) : html;
        debugPrint('    $sample...');
      } else {
        debugPrint('  âŒ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('  âŒ Error: $e');
    }

    debugPrint('${'â”€' * 60}\n');
  }

  debugPrint('ðŸ AnÃ¡lisis completado.');
}
