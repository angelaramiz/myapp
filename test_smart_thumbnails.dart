import 'package:flutter/material.dart';
import 'lib/services/thumbnail_service.dart';
import 'lib/models/video_link.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint(
    'ðŸ§ª Iniciando test de mÃ©todos inteligentes de extracciÃ³n de miniaturas\n',
  );

  // URLs de prueba para diferentes plataformas
  final testUrls = {
    'Instagram Post': 'https://www.instagram.com/p/C0ABC123DEF/',
    'Instagram Reel': 'https://www.instagram.com/reel/C1GHI456JKL/',
    'TikTok Video': 'https://www.tiktok.com/@usuario/video/1234567890123456789',
    'YouTube Video': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'Twitter Post': 'https://twitter.com/user/status/1234567890123456789',
  };

  for (final entry in testUrls.entries) {
    final name = entry.key;
    final url = entry.value;
    final platform = _getPlatformFromUrl(url);

    debugPrint('ðŸ” Probando $name: $url');
    debugPrint('   Plataforma detectada: $platform');

    try {
      // Usar el mÃ©todo getBestThumbnail que incluye las estrategias inteligentes
      final thumbnailUrl = await ThumbnailService.getBestThumbnail(
        url,
        platform,
      );

      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        debugPrint('   âœ… Miniatura encontrada: $thumbnailUrl');
      } else {
        debugPrint('   âŒ No se pudo obtener miniatura');
      }
    } catch (e) {
      debugPrint('   âŒ Error: $e');
    }

    debugPrint(''); // LÃ­nea en blanco para separar resultados
  }

  // Test especÃ­fico para los mÃ©todos inteligentes usando reflection-like approach
  debugPrint('ðŸŽ¯ Test especÃ­fico de mÃ©todos inteligentes:\n');

  // Test Instagram inteligente
  debugPrint('ðŸ” Test Instagram Smart Method:');
  try {
    final instagramUrl = 'https://www.instagram.com/p/C0ABC123DEF/';
    final result = await ThumbnailService.getBestThumbnail(
      instagramUrl,
      PlatformType.instagram,
    );
    debugPrint('   Resultado Instagram Smart: ${result ?? "null"}');
  } catch (e) {
    debugPrint('   Error Instagram Smart: $e');
  }

  debugPrint('');

  // Test TikTok inteligente
  debugPrint('ðŸ” Test TikTok Smart Method:');
  try {
    final tiktokUrl =
        'https://www.tiktok.com/@usuario/video/1234567890123456789';
    final result = await ThumbnailService.getBestThumbnail(
      tiktokUrl,
      PlatformType.tiktok,
    );
    debugPrint('   Resultado TikTok Smart: ${result ?? "null"}');
  } catch (e) {
    debugPrint('   Error TikTok Smart: $e');
  }

  debugPrint('\nðŸ Test completado');
}

PlatformType _getPlatformFromUrl(String url) {
  if (url.contains('youtube.com') || url.contains('youtu.be')) {
    return PlatformType.youtube;
  } else if (url.contains('instagram.com')) {
    return PlatformType.instagram;
  } else if (url.contains('tiktok.com')) {
    return PlatformType.tiktok;
  } else if (url.contains('twitter.com') || url.contains('x.com')) {
    return PlatformType.twitter;
  } else if (url.contains('facebook.com')) {
    return PlatformType.facebook;
  } else {
    return PlatformType.other;
  }
}
