import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Servicio mejorado para extracción de Instagram con múltiples estrategias
class InstagramExtractionServiceImproved {
  /// Obtiene diferentes User-Agents para evitar bloqueos
  static List<String> _getUserAgents() {
    return [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
    ];
  }

  /// Genera URLs de imagen fallback basadas en el ID del post
  static List<String> _generateFallbackImageUrls(
    String postId,
    String? username,
  ) {
    final fallbacks = <String>[];

    if (postId.isNotEmpty) {
      // Formatos conocidos de Instagram para thumbnails
      fallbacks.addAll([
        'https://scontent.cdninstagram.com/v/t51.2885-15/$postId.jpg?stp=dst-jpg_e35_p1080x1080&_nc_ht=scontent.cdninstagram.com',
        'https://scontent.cdninstagram.com/v/t51.2885-15/$postId.webp?stp=dst-webp_e35_p1080x1080',
        'https://instagram.com/p/$postId/media/?size=m',
        'https://scontent-lga3-1.cdninstagram.com/v/t51.2885-15/$postId.jpg',
      ]);
    }

    return fallbacks;
  }

  /// Intenta múltiples estrategias para obtener información
  static Future<Map<String, String>?> getInstagramInfo(String url) async {
    debugPrint('🔍 Instagram: Iniciando extracción para $url');

    try {
      // Extraer información base del URL
      final postInfo = _extractPostInfo(url);
      if (postInfo == null) {
        debugPrint('❌ Instagram: No se pudo extraer información del URL');
        return null;
      }

      // Estrategia 1: Intentar acceso directo con diferentes headers
      final result = await _tryDirectAccess(url);
      if (result != null && result['thumbnail']?.isNotEmpty == true) {
        debugPrint('✅ Instagram: Extracción exitosa con acceso directo');
        return result;
      }

      // Estrategia 2: Usar URLs de fallback generadas
      final fallbackResult = await _tryFallbackUrls(postInfo);
      if (fallbackResult != null) {
        debugPrint('✅ Instagram: Extracción exitosa con URLs de fallback');
        return fallbackResult;
      }

      // Estrategia 3: Intentar acceso al perfil del usuario
      if (postInfo['username']?.isNotEmpty == true) {
        final profileResult = await _tryProfileAccess(
          postInfo['username']!,
          url,
        );
        if (profileResult != null) {
          debugPrint('✅ Instagram: Extracción exitosa desde perfil');
          return profileResult;
        }
      }

      debugPrint('❌ Instagram: Todas las estrategias fallaron');
      return null;
    } catch (e) {
      debugPrint('❌ Instagram: Error general: $e');
      return null;
    }
  }

  /// Extrae información básica del URL
  static Map<String, String>? _extractPostInfo(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      String? username;
      String? postId;
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
      debugPrint('Error extrayendo información básica de Instagram: $e');
      return null;
    }
  }

  /// Estrategia 1: Acceso directo con múltiples User-Agents
  static Future<Map<String, String>?> _tryDirectAccess(String url) async {
    final userAgents = _getUserAgents();

    for (int attempt = 0; attempt < userAgents.length; attempt++) {
      try {
        final headers = {
          'User-Agent': userAgents[attempt],
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
          'Accept-Encoding': 'gzip, deflate, br',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': attempt == 0 ? 'none' : 'cross-site',
          'Sec-Fetch-User': '?1',
          'Upgrade-Insecure-Requests': '1',
          'Referer': attempt == 0 ? 'https://www.google.com/' : 'https://t.co/',
        };

        debugPrint(
          'Instagram: Intento ${attempt + 1} con User-Agent: ${userAgents[attempt].substring(0, 50)}...',
        );

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final html = response.body;

          // Verificar si hay bloqueo de login
          if (html.contains('loginForm') ||
              html.contains('Log in to Instagram')) {
            debugPrint(
              '⚠️ Instagram: Bloqueo de login detectado en intento ${attempt + 1}',
            );
            continue;
          }

          final result = _extractDataFromHtml(html, url);
          if (result != null && result['thumbnail']?.isNotEmpty == true) {
            return result;
          }
        } else {
          debugPrint(
            '⚠️ Instagram: Status ${response.statusCode} en intento ${attempt + 1}',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Instagram: Error en intento ${attempt + 1}: $e');
      }

      // Esperar un poco entre intentos
      if (attempt < userAgents.length - 1) {
        await Future.delayed(Duration(milliseconds: 500 + (attempt * 200)));
      }
    }

    return null;
  }

  /// Estrategia 2: URLs de fallback generadas
  static Future<Map<String, String>?> _tryFallbackUrls(
    Map<String, String> postInfo,
  ) async {
    final postId = postInfo['postId'];
    final username = postInfo['username'];

    if (postId?.isEmpty != false) return null;

    final fallbackUrls = _generateFallbackImageUrls(postId!, username);

    for (final imageUrl in fallbackUrls) {
      try {
        final response = await http
            .head(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint('✅ Instagram: URL de fallback válida: $imageUrl');
          return {
            'title': username?.isNotEmpty == true
                ? 'Post de @$username'
                : 'Post de Instagram',
            'description': 'Contenido de Instagram',
            'thumbnail': imageUrl,
            'url': postInfo['url'] ?? '',
          };
        }
      } catch (e) {
        debugPrint('⚠️ Instagram: Error verificando fallback $imageUrl: $e');
      }
    }

    return null;
  }

  /// Estrategia 3: Acceso al perfil del usuario
  static Future<Map<String, String>?> _tryProfileAccess(
    String username,
    String originalUrl,
  ) async {
    try {
      final profileUrl = 'https://www.instagram.com/$username/';

      final headers = {
        'User-Agent': _getUserAgents()[0],
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
        'Referer': 'https://www.google.com/',
      };

      final response = await http
          .get(Uri.parse(profileUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final html = response.body;
        final result = _extractDataFromHtml(html, originalUrl);

        if (result != null) {
          // Personalizar el título para indicar que es del perfil
          result['title'] = 'Contenido de @$username en Instagram';
          return result;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Instagram: Error accediendo al perfil: $e');
    }

    return null;
  }

  /// Extrae datos del HTML usando múltiples métodos
  static Map<String, String>? _extractDataFromHtml(String html, String url) {
    String title = '';
    String description = '';
    String thumbnailUrl = '';

    // Extraer thumbnail
    final ogImagePattern = RegExp(
      r'<meta\s+property="og:image"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final ogImageMatch = ogImagePattern.firstMatch(html);
    if (ogImageMatch != null) {
      thumbnailUrl = ogImageMatch.group(1) ?? '';
    }

    // Extraer título
    final ogTitlePattern = RegExp(
      r'<meta\s+property="og:title"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final ogTitleMatch = ogTitlePattern.firstMatch(html);
    if (ogTitleMatch != null) {
      title = ogTitleMatch.group(1) ?? '';
    }

    // Extraer descripción
    final descPattern = RegExp(
      r'<meta\s+name="description"\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final descMatch = descPattern.firstMatch(html);
    if (descMatch != null) {
      description = descMatch.group(1) ?? '';
      if (description.isNotEmpty && title.isEmpty) {
        title = description;
      }
    }

    // Limpiar título
    if (title.contains(' en Instagram:')) {
      title = title.split(' en Instagram:')[0].trim();
    } else if (title.contains(' on Instagram:')) {
      title = title.split(' on Instagram:')[0].trim();
    }

    if (thumbnailUrl.isNotEmpty || title.isNotEmpty) {
      return {
        'title': title.isNotEmpty ? title : 'Post de Instagram',
        'description': description.isNotEmpty
            ? description
            : 'Contenido de Instagram',
        'thumbnail': thumbnailUrl,
        'url': url,
      };
    }

    return null;
  }
}
