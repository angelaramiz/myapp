import 'package:flutter/material.dart';

void main() async {
  debugPrint('🔍 Test de patrones de thumbnail fallback...\n');

  // Simular extracción de IDs de diferentes plataformas
  final testCases = [
    {
      'platform': 'Instagram',
      'url': 'https://www.instagram.com/p/CwX1234567/',
      'expectedPattern': 'instagram.com',
    },
    {
      'platform': 'TikTok',
      'url': 'https://www.tiktok.com/@user/video/1234567890',
      'expectedPattern': 'tiktok.com',
    },
    {
      'platform': 'Facebook',
      'url': 'https://www.facebook.com/watch/?v=1234567890',
      'expectedPattern': 'facebook.com',
    },
    {
      'platform': 'Twitter',
      'url': 'https://twitter.com/user/status/1234567890',
      'expectedPattern': 'twitter.com',
    },
  ];
  for (final testCase in testCases) {
    debugPrint('🔗 Probando: ${testCase['platform']} - ${testCase['url']}');

    // Simular extracción de ID (esto sería parte del ThumbnailService)
    String? extractedId = _extractId(testCase['url']!, testCase['platform']!);

    if (extractedId != null) {
      debugPrint('✅ ID extraído: $extractedId');

      // Generar URLs de fallback
      List<String> fallbackUrls = _generateFallbackUrls(
        testCase['platform']!,
        extractedId,
      );

      debugPrint('🖼️ URLs de fallback generadas:');
      for (int i = 0; i < fallbackUrls.length; i++) {
        debugPrint('   ${i + 1}. ${fallbackUrls[i]}');
      }
    } else {
      debugPrint('❌ No se pudo extraer ID');
    }
    debugPrint('─' * 60);
  }

  debugPrint('🏁 Test de patrones completado.');
}

String? _extractId(String url, String platform) {
  switch (platform) {
    case 'Instagram':
      final match = RegExp(r'/p/([^/]+)').firstMatch(url);
      return match?.group(1);
    case 'TikTok':
      final match = RegExp(r'/video/(\d+)').firstMatch(url);
      return match?.group(1);
    case 'Facebook':
      final match = RegExp(r'[?&]v=(\d+)').firstMatch(url);
      return match?.group(1);
    case 'Twitter':
      final match = RegExp(r'/status/(\d+)').firstMatch(url);
      return match?.group(1);
    default:
      return null;
  }
}

List<String> _generateFallbackUrls(String platform, String id) {
  switch (platform) {
    case 'Instagram':
      return [
        'https://scontent-instagram.com/instagram/p/$id/media/?size=m',
        'https://instagram.com/p/$id/media/?size=l',
        'https://instagramimages.com/$id.jpg',
      ];
    case 'TikTok':
      return [
        'https://p16-sign-va.tiktokcdn.com/obj/tos-maliva-p-0068/$id~tplv-photomode-image.image',
        'https://sf16-ies-music-va.tiktokcdn.com/obj/$id',
        'https://tiktok.com/api/img/$id',
      ];
    case 'Facebook':
      return [
        'https://scontent.facebook.com/v/t39.30808-6/$id.jpg',
        'https://lookaside.fbsbx.com/lookaside/crawler/media/?media_id=$id',
      ];
    case 'Twitter':
      return [
        'https://pbs.twimg.com/media/$id.jpg',
        'https://pbs.twimg.com/media/$id:medium',
      ];
    default:
      return [];
  }
}
