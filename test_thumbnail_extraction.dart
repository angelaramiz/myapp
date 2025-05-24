import 'package:flutter/material.dart';
import 'lib/services/thumbnail_service.dart';
import 'lib/services/facebook_extraction_service.dart';
import 'lib/services/instagram_extraction_service.dart';
import 'lib/services/tiktok_extraction_service.dart';
import 'lib/services/twitter_extraction_service.dart';
import 'lib/services/youtube_extraction_service.dart';
import 'lib/services/url_service.dart';
import 'lib/models/video_link.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🔍 Iniciando pruebas de extracción de miniaturas...\n');

  // URLs de prueba
  final testUrls = [
    {
      'platform': 'YouTube',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'description': 'Video popular de YouTube',
    },
    {
      'platform': 'YouTube',
      'url': 'https://youtu.be/dQw4w9WgXcQ',
      'description': 'URL corta de YouTube',
    },
    {
      'platform': 'Facebook',
      'url': 'https://www.facebook.com/watch/?v=123456789',
      'description': 'Video de Facebook',
    },
    {
      'platform': 'Instagram',
      'url': 'https://www.instagram.com/p/ABC123/',
      'description': 'Post de Instagram',
    },
    {
      'platform': 'TikTok',
      'url': 'https://www.tiktok.com/@username/video/123456789',
      'description': 'Video de TikTok',
    },
    {
      'platform': 'Twitter',
      'url': 'https://twitter.com/username/status/123456789',
      'description': 'Tweet con media',
    },
  ];

  final urlService = UrlService();
  for (final testCase in testUrls) {
    debugPrint(
      '📱 Probando ${testCase['platform']}: ${testCase['description']}',
    );
    debugPrint('🔗 URL: ${testCase['url']}');

    try {
      // Detectar plataforma
      final platform = urlService.detectPlatform(testCase['url']!);
      debugPrint('✅ Plataforma detectada: $platform');

      // Probar extracción de miniatura con ThumbnailService
      debugPrint('🖼️  Extrayendo miniatura con ThumbnailService...');
      final thumbnail = await ThumbnailService.getThumbnail(
        testCase['url']!,
        platform,
      );
      if (thumbnail != null && thumbnail.isNotEmpty) {
        debugPrint('✅ Miniatura obtenida: $thumbnail');
      } else {
        debugPrint('❌ No se pudo obtener miniatura con ThumbnailService');
      }

      // Probar extracción específica por plataforma
      Map<String, String>? extractedInfo;

      switch (platform) {
        case PlatformType.youtube:
          debugPrint(
            '🎥 Extrayendo información con YouTubeExtractionService...',
          );
          extractedInfo = await YouTubeExtractionService.getYouTubeVideoInfo(
            testCase['url']!,
          );
          break;
        case PlatformType.facebook:
          debugPrint(
            '📘 Extrayendo información con FacebookExtractionService...',
          );
          extractedInfo = await FacebookExtractionService.getFacebookInfo(
            testCase['url']!,
          );
          break;
        case PlatformType.instagram:
          debugPrint(
            '📷 Extrayendo información con InstagramExtractionService...',
          );
          extractedInfo = await InstagramExtractionService.getInstagramInfo(
            testCase['url']!,
          );
          break;
        case PlatformType.tiktok:
          debugPrint(
            '🎵 Extrayendo información con TikTokExtractionService...',
          );
          extractedInfo = await TikTokExtractionService.getTikTokInfo(
            testCase['url']!,
          );
          break;
        case PlatformType.twitter:
          debugPrint(
            '🐦 Extrayendo información con TwitterExtractionService...',
          );
          extractedInfo = await TwitterExtractionService.getTwitterInfo(
            testCase['url']!,
          );
          break;
        default:
          debugPrint('🔍 Extrayendo información con UrlService genérico...');
          extractedInfo = await urlService.getOtherPlatformInfo(
            testCase['url']!,
            platform,
          );
      }
      if (extractedInfo != null) {
        debugPrint('✅ Información extraída exitosamente:');
        extractedInfo.forEach((key, value) {
          if (value.isNotEmpty) {
            if (key == 'thumbnailUrl') {
              debugPrint('   📷 $key: $value');
            } else {
              debugPrint(
                '   📝 $key: ${value.length > 50 ? '${value.substring(0, 50)}...' : value}',
              );
            }
          }
        });
      } else {
        debugPrint('❌ No se pudo extraer información específica');
      }
    } catch (e) {
      debugPrint('❌ Error durante la extracción: $e');
    }

    debugPrint('${'─' * 60}\n');
  }

  debugPrint('🏁 Pruebas completadas.');
  debugPrint('\n📊 Resumen de recomendaciones:');
  debugPrint(
    '• Para YouTube: Usar ThumbnailService + YouTubeExtractionService',
  );
  debugPrint(
    '• Para otras plataformas: Usar servicios específicos como respaldo',
  );
  debugPrint('• El ThumbnailService debe intentar múltiples calidades');
  debugPrint('• Implementar timeout y manejo de errores robusto');
  debugPrint('• Verificar URLs de miniatura antes de mostrarlas');
}
