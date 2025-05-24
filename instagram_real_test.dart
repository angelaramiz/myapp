import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  debugPrint('ðŸ” Test especÃ­fico de Instagram con URLs reales...\n');

  // URLs reales de Instagram conocidas
  final testUrls = [
    'https://www.instagram.com/p/CwX1234567/', // Post genÃ©rico
    'https://www.instagram.com/reel/CwY7890123/', // Reel genÃ©rico
    'https://www.instagram.com/nasa/', // Perfil verificado
  ];

  for (final url in testUrls) {
    debugPrint('ðŸ”— Probando URL: $url');

    try {
      // Headers exactos que usa nuestro servicio
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
        'Cache-Control': 'max-age=0',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'Referer': 'https://www.google.com/',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('  ðŸ“Š Status HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('  ðŸ“„ HTML length: ${html.length} caracteres');

        // BÃºsqueda exacta de meta tags como en nuestro servicio
        final ogImagePattern = RegExp(
          r'<meta\s+property="og:image"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final ogImageMatches = ogImagePattern.allMatches(html);
        debugPrint(
          '  ðŸ–¼ï¸  Meta og:image encontrados: ${ogImageMatches.length}',
        );

        for (final match in ogImageMatches) {
          final imageUrl = match.group(1);
          debugPrint('    - $imageUrl');

          // Verificar si la imagen es accesible
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              final imgResponse = await http
                  .head(Uri.parse(imageUrl))
                  .timeout(const Duration(seconds: 5));
              debugPrint(
                '      âœ… Imagen verificada: ${imgResponse.statusCode}',
              );
            } catch (e) {
              debugPrint('      âŒ Error verificando imagen: $e');
            }
          }
        }

        // Buscar tÃ­tulo
        final ogTitlePattern = RegExp(
          r'<meta\s+property="og:title"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final ogTitleMatch = ogTitlePattern.firstMatch(html);
        if (ogTitleMatch != null) {
          debugPrint('  ðŸ“ TÃ­tulo: ${ogTitleMatch.group(1)}');
        }

        // Buscar descripciÃ³n
        final descPattern = RegExp(
          r'<meta\s+name="description"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final descMatch = descPattern.firstMatch(html);
        if (descMatch != null) {
          debugPrint('  ðŸ“„ DescripciÃ³n: ${descMatch.group(1)}');
        }

        // Verificar si hay redirecciÃ³n de login
        if (html.contains('login') || html.contains('Log in')) {
          debugPrint(
            '  âš ï¸  ALERTA: Posible redirecciÃ³n a login detectada',
          );
        }

        // Verificar contenido dinÃ¡mico
        if (html.contains('window._sharedData')) {
          debugPrint('  ðŸ“Š Datos dinÃ¡micos (_sharedData) encontrados');
        }
      } else if (response.statusCode == 302 || response.statusCode == 301) {
        debugPrint(
          '  ðŸ”„ RedirecciÃ³n detectada: ${response.headers['location']}',
        );
      } else {
        debugPrint('  âŒ Error HTTP: ${response.statusCode}');
        debugPrint('  ðŸ“ Headers de respuesta:');
        response.headers.forEach((key, value) {
          debugPrint('    $key: $value');
        });
      }
    } catch (e) {
      debugPrint('  âŒ Error: $e');
    }

    debugPrint('${'â”€' * 70}\n');
  }

  debugPrint('ðŸ Test de Instagram completado.');
}
