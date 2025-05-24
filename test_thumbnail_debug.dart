import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'lib/services/thumbnail_service.dart';
import 'lib/services/url_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🔍 Prueba de debugging específica para miniaturas...\n');

  // URLs de prueba específicas
  final testUrls = [
    {
      'platform': 'Instagram',
      'url': 'https://www.instagram.com/p/ABC123/',
      'description': 'Post de Instagram de prueba',
    },
    {
      'platform': 'Facebook',
      'url': 'https://www.facebook.com/watch/?v=123456789',
      'description': 'Video de Facebook de prueba',
    },
    {
      'platform': 'TikTok',
      'url': 'https://www.tiktok.com/@username/video/123456789',
      'description': 'Video de TikTok de prueba',
    },
    {
      'platform': 'Twitter',
      'url': 'https://twitter.com/username/status/123456789',
      'description': 'Tweet de prueba',
    },
  ];

  final urlService = UrlService();

  for (final testCase in testUrls) {
    debugPrint('🔗 Probando ${testCase['platform']}: ${testCase['url']}');

    try {
      // Detectar plataforma
      final platform = urlService.detectPlatform(testCase['url']!);
      debugPrint('  ✅ Plataforma detectada: $platform');

      // Paso 1: Intentar obtener con ThumbnailService.getBestThumbnail
      debugPrint('  🖼️  Paso 1: ThumbnailService.getBestThumbnail...');
      final thumbnail1 = await ThumbnailService.getBestThumbnail(
        testCase['url']!,
        platform,
      );

      if (thumbnail1 != null && thumbnail1.isNotEmpty) {
        debugPrint('  ✅ Miniatura encontrada: $thumbnail1');

        // Verificar si la URL es accesible
        try {
          final response = await http.head(Uri.parse(thumbnail1));
          debugPrint('  📊 Status HTTP: ${response.statusCode}');
          debugPrint('  📊 Content-Type: ${response.headers['content-type']}');
          debugPrint(
            '  📊 Content-Length: ${response.headers['content-length']}',
          );
        } catch (e) {
          debugPrint('  ❌ Error verificando URL: $e');
        }
      } else {
        debugPrint('  ❌ No se obtuvo miniatura con getBestThumbnail');
      }

      // Paso 2: Intentar con extracción HTML directa
      debugPrint('  🌐 Paso 2: Extracción HTML directa...');
      final thumbnail2 = await ThumbnailService.extractThumbnailFromHtml(
        testCase['url']!,
        platform,
      );

      if (thumbnail2 != null && thumbnail2.isNotEmpty) {
        debugPrint('  ✅ Miniatura HTML: $thumbnail2');
      } else {
        debugPrint('  ❌ No se obtuvo miniatura con extracción HTML');
      }

      // Paso 3: Obtener información completa
      debugPrint('  📋 Paso 3: Información completa...');
      final info = await ThumbnailService.getCompleteInfo(
        testCase['url']!,
        platform,
      );

      if (info != null) {
        debugPrint('  ✅ Información completa obtenida:');
        info.forEach((key, value) {
          if (value.isNotEmpty) {
            final displayValue = value.length > 100
                ? '${value.substring(0, 100)}...'
                : value;
            debugPrint('     $key: $displayValue');
          }
        });
      } else {
        debugPrint('  ❌ No se obtuvo información completa');
      }
    } catch (e, stackTrace) {
      debugPrint('  ❌ Error durante la prueba: $e');
      debugPrint('  🔧 Stack trace: $stackTrace');
    }

    debugPrint('${'─' * 80}\n');
  }

  // Prueba específica de headers por plataforma
  debugPrint('🌐 Probando headers específicos por plataforma...\n');

  final realUrls = [
    'https://www.instagram.com/p/CwXYZ123456/',
    'https://www.tiktok.com/@test/video/7123456789012345678',
  ];
  for (final url in realUrls) {
    debugPrint('🔗 Probando headers para: $url');

    try {
      // Usar headers genéricos para la prueba
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
      };

      debugPrint('  📋 Headers enviados:');
      headers.forEach((key, value) {
        debugPrint('     $key: $value');
      });

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('  📊 Respuesta HTTP: ${response.statusCode}');
      debugPrint('  📊 Content-Type: ${response.headers['content-type']}');
      debugPrint('  📊 Content-Length: ${response.headers['content-length']}');

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('  📄 HTML Length: ${html.length} caracteres');

        // Buscar meta tags específicos
        final ogImageMatches = RegExp(
          r'<meta[^>]+property="og:image"[^>]+content="([^"]*)"',
        ).allMatches(html);
        final twitterImageMatches = RegExp(
          r'<meta[^>]+name="twitter:image"[^>]+content="([^"]*)"',
        ).allMatches(html);

        debugPrint(
          '  🏷️  Meta tags og:image encontrados: ${ogImageMatches.length}',
        );
        for (final match in ogImageMatches.take(3)) {
          debugPrint('     ${match.group(1)}');
        }

        debugPrint(
          '  🏷️  Meta tags twitter:image encontrados: ${twitterImageMatches.length}',
        );
        for (final match in twitterImageMatches.take(3)) {
          debugPrint('     ${match.group(1)}');
        }
      }
    } catch (e) {
      debugPrint('  ❌ Error probando headers: $e');
    }

    debugPrint('${'─' * 60}\n');
  }

  debugPrint('🏁 Debugging de miniaturas completado.');
}
