import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/video_link.dart';
import 'youtube_extraction_service.dart';
import 'facebook_extraction_service.dart';
import 'instagram_extraction_service.dart';
import 'tiktok_extraction_service.dart';
import 'twitter_extraction_service.dart';

/// Servicio mejorado para obtener miniaturas de diferentes plataformas
class ThumbnailService {
  static const Duration _timeout = Duration(seconds: 10);

  /// Obtiene la miniatura de YouTube con diferentes calidades
  static Future<String?> getYouTubeThumbnail(String videoId) async {
    // Lista de URLs de miniatura en orden de calidad (de mayor a menor)
    final thumbnailUrls = [
      'https://img.youtube.com/vi/$videoId/maxresdefault.jpg', // 1280x720
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg', // 480x360
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg', // 320x180
      'https://img.youtube.com/vi/$videoId/default.jpg', // 120x90
      'https://img.youtube.com/vi/$videoId/0.jpg', // 480x360 (alternativo)
    ];

    for (String url in thumbnailUrls) {
      try {
        debugPrint('Verificando miniatura de YouTube: $url');
        final response = await http.head(Uri.parse(url)).timeout(_timeout);

        if (response.statusCode == 200) {
          // Verificar que el content-type es una imagen
          final contentType = response.headers['content-type'];
          if (contentType != null && contentType.startsWith('image/')) {
            debugPrint('Miniatura de YouTube encontrada: $url');
            return url;
          }
        }
      } catch (e) {
        debugPrint('Error verificando miniatura de YouTube $url: $e');
        continue;
      }
    }

    debugPrint('No se pudo obtener miniatura de YouTube para $videoId');
    return null;
  }

  /// Extrae miniatura de meta tags OG y Twitter
  static Future<String?> extractThumbnailFromHtml(
    String url,
    PlatformType platform,
  ) async {
    try {
      debugPrint('Extrayendo miniatura de $url para plataforma $platform');

      final headers = _getHeadersForPlatform(platform);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final html = response.body;

        // Priorizar diferentes meta tags según la plataforma
        final thumbnailUrls = _extractThumbnailUrls(html, platform);

        // Verificar cada URL encontrada
        for (String thumbnailUrl in thumbnailUrls) {
          final verifiedUrl = await _verifyThumbnailUrl(thumbnailUrl);
          if (verifiedUrl != null) {
            debugPrint('Miniatura verificada para $platform: $verifiedUrl');
            return verifiedUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('Error extrayendo miniatura de $url: $e');
    }

    return null;
  }

  /// Obtiene headers específicos para cada plataforma
  static Map<String, String> _getHeadersForPlatform(PlatformType platform) {
    final baseHeaders = {
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
      'Cache-Control': 'max-age=0',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Upgrade-Insecure-Requests': '1',
    };

    switch (platform) {
      case PlatformType.instagram:
        return {
          ...baseHeaders,
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1',
          'Referer': 'https://www.google.com/',
        };

      case PlatformType.facebook:
        return {
          ...baseHeaders,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        };

      case PlatformType.tiktok:
        return {
          ...baseHeaders,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.tiktok.com/',
        };

      case PlatformType.twitter:
        return {
          ...baseHeaders,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        };

      default:
        return {
          ...baseHeaders,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        };
    }
  }

  /// Extrae URLs de miniatura del HTML según la plataforma
  static List<String> _extractThumbnailUrls(
    String html,
    PlatformType platform,
  ) {
    final thumbnailUrls = <String>[];

    // Patrones ordenados por prioridad
    final patterns = [
      // Open Graph image (más común y confiable)
      RegExp(
        r'<meta\s+property="og:image"\s+content="([^"]*)"',
        caseSensitive: false,
      ),
      RegExp(
        r'<meta\s+property="og:image:url"\s+content="([^"]*)"',
        caseSensitive: false,
      ),

      // Twitter Cards
      RegExp(
        r'<meta\s+name="twitter:image"\s+content="([^"]*)"',
        caseSensitive: false,
      ),
      RegExp(
        r'<meta\s+name="twitter:image:src"\s+content="([^"]*)"',
        caseSensitive: false,
      ),

      // Específicos de plataforma
      if (platform == PlatformType.tiktok) ...[
        RegExp(
          r'<meta\s+name="twitter:player:image"\s+content="([^"]*)"',
          caseSensitive: false,
        ),
        RegExp(r'"cover":"([^"]*)"', caseSensitive: false),
      ],

      if (platform == PlatformType.instagram) ...[
        RegExp(
          r'<meta\s+property="al:android:url"\s+content="[^"]*"[^>]*>',
          caseSensitive: false,
        ),
        RegExp(r'"display_url":"([^"]*)"', caseSensitive: false),
      ],

      // Genéricos
      RegExp(r'<link\s+rel="image_src"\s+href="([^"]*)"', caseSensitive: false),
      RegExp(
        r'<meta\s+name="msapplication-TileImage"\s+content="([^"]*)"',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(html);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final url = match.group(1);
          if (url != null && url.isNotEmpty && _isValidImageUrl(url)) {
            thumbnailUrls.add(_cleanUrl(url));
          }
        }
      }
    }

    return thumbnailUrls;
  }

  /// Verifica que una URL sea una imagen válida
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    // Verificar que sea una URL válida
    try {
      final uri = Uri.parse(url);
      if (!uri.hasAbsolutePath || (!uri.scheme.startsWith('http'))) {
        return false;
      }
    } catch (e) {
      return false;
    }

    // Verificar extensiones de imagen comunes
    final lowerUrl = url.toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];

    // Si tiene extensión de imagen, es válida
    if (imageExtensions.any((ext) => lowerUrl.contains(ext))) {
      return true;
    }

    // Si no tiene extensión pero viene de un dominio conocido de imágenes, puede ser válida
    final imageDomains = [
      'img.youtube.com',
      'i.ytimg.com',
      'scontent-',
      'pbs.twimg.com',
      'abs.twimg.com',
      'p16-sign-sg.tiktokcdn.com',
      'p16-va.tiktokcdn.com',
      'external-',
    ];

    return imageDomains.any((domain) => lowerUrl.contains(domain));
  }

  /// Limpia y normaliza URLs
  static String _cleanUrl(String url) {
    // Decodificar entidades HTML
    var cleanedUrl = url
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/')
        .replaceAll('\\u0026', '&')
        .replaceAll('\\/', '/')
        .replaceAll('\\', '');

    // Asegurar protocolo HTTPS cuando sea posible
    if (cleanedUrl.startsWith('//')) {
      cleanedUrl = 'https:$cleanedUrl';
    } else if (cleanedUrl.startsWith('http://')) {
      cleanedUrl = cleanedUrl.replaceFirst('http://', 'https://');
    }

    return cleanedUrl;
  }

  /// Verifica que una URL de miniatura sea accesible
  static Future<String?> _verifyThumbnailUrl(String url) async {
    try {
      debugPrint('Verificando miniatura: $url');
      final response = await http.head(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.startsWith('image/')) {
          // Verificar que no sea una imagen de placeholder muy pequeña
          final contentLength = response.headers['content-length'];
          if (contentLength != null) {
            final size = int.tryParse(contentLength);
            if (size != null && size < 1000) {
              debugPrint(
                'Imagen muy pequeña, probablemente placeholder: $size bytes',
              );
              return null;
            }
          }
          return url;
        }
      }
    } catch (e) {
      debugPrint('Error verificando miniatura $url: $e');
    }

    return null;
  }

  /// Método principal para obtener miniatura según la plataforma
  static Future<String?> getThumbnail(String url, PlatformType platform) async {
    debugPrint('Obteniendo miniatura para $platform: $url');

    switch (platform) {
      case PlatformType.youtube:
        // Para YouTube, usar el método específico que es más confiable
        final videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          return await getYouTubeThumbnail(videoId);
        }
        break;

      default:
        // Para otras plataformas, extraer del HTML
        return await extractThumbnailFromHtml(url, platform);
    }

    return null;
  }

  /// Extrae el ID de video de YouTube de una URL
  static String? _extractYouTubeVideoId(String url) {
    try {
      final regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      final match = regExp.firstMatch(url);
      return match?.group(1);
    } catch (e) {
      debugPrint('Error extrayendo ID de YouTube: $e');
      return null;
    }
  }

  /// Obtiene información completa usando servicios específicos por plataforma
  static Future<Map<String, String>?> getCompleteInfo(
    String url,
    PlatformType platform,
  ) async {
    try {
      switch (platform) {
        case PlatformType.youtube:
          return await YouTubeExtractionService.getYouTubeVideoInfo(url);
        case PlatformType.facebook:
          return await FacebookExtractionService.getFacebookInfo(url);
        case PlatformType.instagram:
          return await InstagramExtractionService.getInstagramInfo(url);
        case PlatformType.tiktok:
          return await TikTokExtractionService.getTikTokInfo(url);
        case PlatformType.twitter:
          return await TwitterExtractionService.getTwitterInfo(url);
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error obteniendo información completa para $platform: $e');
      return null;
    }
  }

  /// Obtiene la mejor miniatura disponible combinando múltiples métodos
  static Future<String?> getBestThumbnail(
    String url,
    PlatformType platform,
  ) async {
    _logThumbnailExtraction(platform.toString(), url, null);
    String? thumbnailUrl;

    // Para Instagram y TikTok, usar estrategias especiales primero
    if (platform == PlatformType.instagram) {
      thumbnailUrl = await _getInstagramThumbnailSmart(url);
      if (thumbnailUrl != null) {
        _logThumbnailExtraction(platform.toString(), url, thumbnailUrl);
        return thumbnailUrl;
      }
    } else if (platform == PlatformType.tiktok) {
      thumbnailUrl = await _getTikTokThumbnailSmart(url);
      if (thumbnailUrl != null) {
        _logThumbnailExtraction(platform.toString(), url, thumbnailUrl);
        return thumbnailUrl;
      }
    }

    // Método 1: Usar ThumbnailService específico con timeout
    try {
      thumbnailUrl = await getThumbnailWithTimeout(url, platform);
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        final verifiedUrl = await _verifyThumbnailUrl(thumbnailUrl);
        if (verifiedUrl != null) {
          _logThumbnailExtraction(platform.toString(), url, verifiedUrl);
          return verifiedUrl;
        }
      }
    } catch (e) {
      _logThumbnailExtraction(
        platform.toString(),
        url,
        null,
        error: 'Timeout método específico: $e',
      );
    }

    // Método 2: Usar servicios de extracción completa
    try {
      final info = await getCompleteInfo(url, platform);
      thumbnailUrl = info?['thumbnailUrl'];
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        final verifiedUrl = await _verifyThumbnailUrl(thumbnailUrl);
        if (verifiedUrl != null) {
          _logThumbnailExtraction(platform.toString(), url, verifiedUrl);
          return verifiedUrl;
        }
      }
    } catch (e) {
      _logThumbnailExtraction(
        platform.toString(),
        url,
        null,
        error: 'Error servicio de extracción: $e',
      );
    }

    // Método 3: Extracción genérica HTML con timeout
    try {
      thumbnailUrl = await extractThumbnailFromHtml(
        url,
        platform,
      ).timeout(_getTimeoutForPlatform(platform));
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        final verifiedUrl = await _verifyThumbnailUrl(thumbnailUrl);
        if (verifiedUrl != null) {
          _logThumbnailExtraction(platform.toString(), url, verifiedUrl);
          return verifiedUrl;
        }
      }
    } catch (e) {
      _logThumbnailExtraction(
        platform.toString(),
        url,
        null,
        error: 'Error extracción HTML: $e',
      );
    }

    // Método 4: Intentar URLs de respaldo específicas por plataforma
    final fallbackUrls = _getFallbackThumbnailUrls(url, platform);
    for (final fallbackUrl in fallbackUrls) {
      try {
        final verifiedUrl = await _verifyThumbnailUrl(fallbackUrl);
        if (verifiedUrl != null) {
          _logThumbnailExtraction(
            platform.toString(),
            url,
            verifiedUrl,
            error: 'Usando URL de respaldo',
          );
          return verifiedUrl;
        }
      } catch (e) {
        debugPrint('Error con URL de respaldo $fallbackUrl: $e');
      }
    }

    _logThumbnailExtraction(platform.toString(), url, null);
    return null;
  }

  /// Logs detallados para debugging de extracción de miniaturas
  static void _logThumbnailExtraction(
    String platform,
    String url,
    String? result, {
    String? error,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    if (result != null) {
      debugPrint('[$timestamp] ✅ Miniatura $platform: $result');
    } else if (error != null) {
      debugPrint('[$timestamp] ❌ Error $platform: $error');
    } else {
      debugPrint('[$timestamp] ⚠️  No miniatura $platform para: $url');
    }
  }

  /// Obtiene miniatura con timeout específico por plataforma
  static Future<String?> getThumbnailWithTimeout(
    String url,
    PlatformType platform,
  ) async {
    final timeout = _getTimeoutForPlatform(platform);

    try {
      return await getThumbnail(url, platform).timeout(timeout);
    } catch (e) {
      _logThumbnailExtraction(
        platform.toString(),
        url,
        null,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Obtiene timeout específico según la plataforma
  static Duration _getTimeoutForPlatform(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return const Duration(seconds: 8); // YouTube suele ser rápido
      case PlatformType.instagram:
      case PlatformType.facebook:
        return const Duration(seconds: 15); // Meta platforms pueden ser lentas
      case PlatformType.tiktok:
        return const Duration(seconds: 12); // TikTok tiene protección anti-bot
      case PlatformType.twitter:
        return const Duration(seconds: 10); // Twitter/X es variable
      default:
        return const Duration(seconds: 10); // Timeout genérico
    }
  }

  /// Obtiene URLs de miniatura de respaldo para plataformas específicas
  static List<String> _getFallbackThumbnailUrls(
    String url,
    PlatformType platform,
  ) {
    final fallbackUrls = <String>[];

    switch (platform) {
      case PlatformType.instagram:
        // Para Instagram, intentar diferentes formatos de URL
        if (url.contains('/p/')) {
          final postId = url.split('/p/')[1].split('/')[0];
          fallbackUrls.addAll([
            // URLs de imagen directas más comunes
            'https://scontent.cdninstagram.com/v/t51.2885-15/s1080x1080/$postId.jpg?stp=dst-jpg_e35&_nc_ht=scontent.cdninstagram.com',
            'https://scontent.cdninstagram.com/v/t51.2885-15/$postId.jpg?stp=dst-jpg_e35_p1080x1080',
            'https://instagram.com/p/$postId/media/?size=l',
            'https://instagram.com/p/$postId/media/?size=m',
            'https://scontent-atl3-1.cdninstagram.com/v/t51.2885-15/s1080x1080/$postId.jpg',
            'https://scontent-lga3-1.cdninstagram.com/v/t51.2885-15/s640x640/$postId.jpg',
          ]);
        } else if (url.contains('/reel/')) {
          final reelId = url.split('/reel/')[1].split('/')[0];
          fallbackUrls.addAll([
            'https://scontent.cdninstagram.com/v/t51.2885-15/s1080x1080/$reelId.jpg?stp=dst-jpg_e35&_nc_ht=scontent.cdninstagram.com',
            'https://instagram.com/reel/$reelId/media/?size=l',
            'https://instagram.com/reel/$reelId/media/?size=m',
          ]);
        }
        // URLs genéricas como último recurso
        fallbackUrls.addAll([
          'https://static.cdninstagram.com/rsrc.php/v4/yI/r/VsNE-OHk_8a.png', // Logo oficial
          'https://upload.wikimedia.org/wikipedia/commons/a/a5/Instagram_icon.png',
        ]);
        break;

      case PlatformType.facebook:
        // Para Facebook, intentar diferentes API endpoints
        if (url.contains('facebook.com')) {
          fallbackUrls.addAll([
            'https://graph.facebook.com/me/picture?type=large',
            'https://external-content.duckduckgo.com/iu/?u=$url&f=1&nofb=1',
            'https://static.xx.fbcdn.net/rsrc.php/v3/yG/r/wrCiWd_JmQD.png', // Logo FB
          ]);
        }
        break;

      case PlatformType.tiktok:
        // Para TikTok, intentar diferentes CDNs y placeholders
        if (url.contains('tiktok.com')) {
          // Intentar extraer ID del video para construir URLs
          final videoIdRegex = RegExp(r'/video/(\d+)');
          final match = videoIdRegex.firstMatch(url);
          if (match != null) {
            final videoId = match.group(1);
            fallbackUrls.addAll([
              'https://p16-sign-sg.tiktokcdn.com/obj/tos-maliva-p-0068/$videoId.jpeg',
              'https://p16-sign-va.tiktokcdn.com/obj/tos-maliva-p-0068/$videoId.jpeg',
              'https://p16-va.tiktokcdn.com/img/tos-maliva-p-0068/$videoId~tplv-photomode-image.jpeg',
              'https://p77-va.tiktokcdn.com/img/tos-maliva-p-0068/$videoId~tplv-photomode-image.jpeg',
              'https://sf16-website-login.neutral.ttwstatic.com/obj/tiktok_web_login_static/tiktok/webapp/main/webapp-desktop/$videoId.jpg',
            ]);
          }
          fallbackUrls.addAll([
            'https://p16-sign-sg.tiktokcdn.com/obj/tos-maliva-p-0068/placeholder.jpg',
            'https://sf16-website-login.neutral.ttwstatic.com/obj/tiktok_web_login_static/tiktok/webapp/main/webapp-desktop/placeholder.jpg',
            'https://upload.wikimedia.org/wikipedia/en/a/a9/TikTok_logo.svg', // Logo TikTok
          ]);
        }
        break;

      case PlatformType.twitter:
        // Para Twitter/X, intentar diferentes formatos
        if (url.contains('twitter.com') || url.contains('x.com')) {
          // Intentar extraer ID del tweet
          final tweetIdRegex = RegExp(r'/status/(\d+)');
          final match = tweetIdRegex.firstMatch(url);
          if (match != null) {
            final tweetId = match.group(1);
            fallbackUrls.addAll([
              'https://pbs.twimg.com/tweet_video_thumb/$tweetId.jpg',
              'https://pbs.twimg.com/media/$tweetId.jpg',
            ]);
          }
          fallbackUrls.addAll([
            'https://abs.twimg.com/icons/apple-touch-icon-192x192.png',
            'https://pbs.twimg.com/profile_images/placeholder.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/6/6f/Logo_of_Twitter.svg', // Logo Twitter
          ]);
        }
        break;

      default:
        break;
    }

    return fallbackUrls;
  }

  /// Método inteligente para obtener miniatura de Instagram con múltiples estrategias
  static Future<String?> _getInstagramThumbnailSmart(String url) async {
    debugPrint('🎯 Instagram Smart: Iniciando extracción para $url');

    try {
      // Extraer información del post
      final postInfo = _extractInstagramPostInfo(url);
      if (postInfo == null) {
        debugPrint('❌ Instagram Smart: No se pudo extraer información del URL');
        return null;
      }

      // Estrategia 1: URLs de fallback generadas basadas en el post ID
      if (postInfo['postId']?.isNotEmpty == true) {
        final postId = postInfo['postId']!;
        final fallbackUrls = [
          'https://scontent.cdninstagram.com/v/t51.2885-15/$postId.jpg?stp=dst-jpg_e35_p1080x1080&_nc_ht=scontent.cdninstagram.com',
          'https://scontent.cdninstagram.com/v/t51.2885-15/$postId.webp?stp=dst-webp_e35_p1080x1080',
          'https://instagram.com/p/$postId/media/?size=m',
          'https://scontent-lga3-1.cdninstagram.com/v/t51.2885-15/$postId.jpg',
          'https://scontent-atl3-1.cdninstagram.com/v/t51.2885-15/s640x640/$postId.jpg',
        ];

        for (final fallbackUrl in fallbackUrls) {
          final verifiedUrl = await _verifyThumbnailUrl(fallbackUrl);
          if (verifiedUrl != null) {
            debugPrint(
              '✅ Instagram Smart: URL de fallback exitosa: $verifiedUrl',
            );
            return verifiedUrl;
          }
        }
      }

      // Estrategia 2: Acceso directo con headers rotativos
      final userAgents = [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ];

      for (final userAgent in userAgents) {
        try {
          final headers = {
            'User-Agent': userAgent,
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
            'Referer': 'https://www.google.com/',
            'Cache-Control': 'max-age=0',
          };

          final response = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final thumbnailUrls = _extractThumbnailUrls(
              response.body,
              PlatformType.instagram,
            );
            for (final thumbnailUrl in thumbnailUrls) {
              final verifiedUrl = await _verifyThumbnailUrl(thumbnailUrl);
              if (verifiedUrl != null) {
                debugPrint(
                  '✅ Instagram Smart: Extracción HTML exitosa: $verifiedUrl',
                );
                return verifiedUrl;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Instagram Smart: Error con User-Agent $userAgent: $e');
          continue;
        }
      }

      debugPrint('❌ Instagram Smart: Todas las estrategias fallaron');
      return null;
    } catch (e) {
      debugPrint('❌ Instagram Smart: Error general: $e');
      return null;
    }
  }

  /// Método inteligente para obtener miniatura de TikTok con estrategias CDN
  static Future<String?> _getTikTokThumbnailSmart(String url) async {
    debugPrint('🎯 TikTok Smart: Iniciando extracción para $url');

    try {
      // Extraer información del video
      final videoInfo = _extractTikTokVideoInfo(url);
      if (videoInfo == null) {
        debugPrint('❌ TikTok Smart: No se pudo extraer información del URL');
        return null;
      }

      // Estrategia 1: URLs de CDN basadas en el video ID
      if (videoInfo['videoId']?.isNotEmpty == true) {
        final videoId = videoInfo['videoId']!;
        final cdnUrls = [
          'https://p16-sign-sg.tiktokcdn.com/obj/tos-maliva-p-0068/$videoId.jpeg',
          'https://p16-sign-va.tiktokcdn.com/obj/tos-maliva-p-0068/$videoId.jpeg',
          'https://p16-va.tiktokcdn.com/img/tos-maliva-p-0068/$videoId~tplv-photomode-image.jpeg',
          'https://p77-va.tiktokcdn.com/img/tos-maliva-p-0068/$videoId~tplv-photomode-image.jpeg',
          'https://sf16-website-login.neutral.ttwstatic.com/obj/tiktok_web_login_static/tiktok/webapp/main/webapp-desktop/$videoId.jpg',
        ];

        for (final cdnUrl in cdnUrls) {
          final verifiedUrl = await _verifyThumbnailUrl(cdnUrl);
          if (verifiedUrl != null) {
            debugPrint('✅ TikTok Smart: URL de CDN exitosa: $verifiedUrl');
            return verifiedUrl;
          }
        }
      }

      // Estrategia 2: Acceso directo con headers específicos para TikTok
      try {
        final headers = {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://www.tiktok.com/',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'same-origin',
        };

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final thumbnailUrls = _extractThumbnailUrls(
            response.body,
            PlatformType.tiktok,
          );
          for (final thumbnailUrl in thumbnailUrls) {
            final verifiedUrl = await _verifyThumbnailUrl(thumbnailUrl);
            if (verifiedUrl != null) {
              debugPrint(
                '✅ TikTok Smart: Extracción HTML exitosa: $verifiedUrl',
              );
              return verifiedUrl;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ TikTok Smart: Error en acceso directo: $e');
      }

      // Estrategia 3: URLs genéricas de placeholder
      final placeholderUrls = [
        'https://sf16-website-login.neutral.ttwstatic.com/obj/tiktok_web_login_static/tiktok/webapp/main/webapp-desktop/placeholder.jpg',
        'https://p16-sign-sg.tiktokcdn.com/obj/tos-maliva-p-0068/placeholder.jpg',
      ];

      for (final placeholderUrl in placeholderUrls) {
        final verifiedUrl = await _verifyThumbnailUrl(placeholderUrl);
        if (verifiedUrl != null) {
          debugPrint(
            '✅ TikTok Smart: URL de placeholder exitosa: $verifiedUrl',
          );
          return verifiedUrl;
        }
      }

      debugPrint('❌ TikTok Smart: Todas las estrategias fallaron');
      return null;
    } catch (e) {
      debugPrint('❌ TikTok Smart: Error general: $e');
      return null;
    }
  }

  /// Extrae información básica del post de Instagram
  static Map<String, String>? _extractInstagramPostInfo(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      String? postId;
      String? username;
      bool isReel = false;

      if (pathSegments.contains('p') &&
          pathSegments.length > pathSegments.indexOf('p') + 1) {
        int pIndex = pathSegments.indexOf('p');
        postId = pathSegments[pIndex + 1];
        if (pIndex > 0) username = pathSegments[0];
      } else if (pathSegments.contains('reel') &&
          pathSegments.length > pathSegments.indexOf('reel') + 1) {
        int reelIndex = pathSegments.indexOf('reel');
        postId = pathSegments[reelIndex + 1];
        isReel = true;
        if (reelIndex > 0) username = pathSegments[0];
      } else if (pathSegments.isNotEmpty) {
        username = pathSegments[0];
      }

      return {
        'postId': postId ?? '',
        'username': username ?? '',
        'isReel': isReel.toString(),
        'url': url,
      };
    } catch (e) {
      debugPrint('Error extrayendo información de Instagram: $e');
      return null;
    }
  }

  /// Extrae información básica del video de TikTok
  static Map<String, String>? _extractTikTokVideoInfo(String url) {
    try {
      final Uri uri = Uri.parse(url);
      String? videoId;
      String? username;

      // Extraer ID del video desde diferentes formatos de URL
      final videoIdRegex = RegExp(r'/video/(\d+)');
      final match = videoIdRegex.firstMatch(url);
      if (match != null) {
        videoId = match.group(1);
      }

      // Extraer username si está en la URL
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty && pathSegments[0].startsWith('@')) {
        username = pathSegments[0].substring(1); // Remover @
      }

      return {'videoId': videoId ?? '', 'username': username ?? '', 'url': url};
    } catch (e) {
      debugPrint('Error extrayendo información de TikTok: $e');
      return null;
    }
  }
}
