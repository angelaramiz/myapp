import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'extraction_helper.dart';

/// Servicio dedicado para extraer información de videos de Facebook
class FacebookExtractionService {
  /// Extrae el ID o información clave de una URL de Facebook
  static Map<String, String>? extractVideoInfo(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      String? postId;
      String? username;

      // Intentar extraer ID del post o usuario
      if (pathSegments.contains('posts')) {
        int index = pathSegments.indexOf('posts');
        if (index > 0 && index + 1 < pathSegments.length) {
          username = pathSegments[index - 1];
          postId = pathSegments[index + 1];
          debugPrint('Facebook: Usuario=$username, PostID=$postId');
        }
      } else if (pathSegments.contains('videos')) {
        int index = pathSegments.indexOf('videos');
        if (index > 0 && index + 1 < pathSegments.length) {
          username = pathSegments[index - 1];
          postId = pathSegments[index + 1];
          debugPrint('Facebook: Usuario=$username, VideoID=$postId');
        }
      } else if (pathSegments.contains('watch')) {
        final videoId = uri.queryParameters['v'];
        if (videoId != null) {
          postId = videoId;
          debugPrint('Facebook Watch: VideoID=$videoId');
        }
      }

      return {'postId': postId ?? '', 'username': username ?? '', 'url': url};
    } catch (e) {
      debugPrint('Error extrayendo información de Facebook: $e');
      return null;
    }
  }

  /// Método principal para obtener información de un post/video de Facebook
  static Future<Map<String, String>?> getFacebookInfo(String url) async {
    try {
      // Extraer información base
      Map<String, String>? baseInfo = extractVideoInfo(url);
      if (baseInfo == null) {
        return null; // Obtener datos de la página con headers mejorados
      }
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
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final document =
            response.body; // Extraer título con métodos más robustos
        String title = '';

        // Método 1: Extraer desde og:title (más fiable para Facebook)
        final ogTitleRegExp = RegExp(
          r'<meta\s+property="og:title"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final ogTitleMatch = ogTitleRegExp.firstMatch(document);
        if (ogTitleMatch != null && ogTitleMatch.groupCount >= 1) {
          title = ogTitleMatch.group(1) ?? '';
          debugPrint('Facebook: Título extraído de og:title: $title');
        }

        // Método 2: Si no hay og:title, intentar con title normal
        if (title.isEmpty) {
          final titleRegExp = RegExp(
            r'<title>(.*?)<\/title>',
            caseSensitive: false,
          );
          final titleMatch = titleRegExp.firstMatch(document);
          if (titleMatch != null && titleMatch.groupCount >= 1) {
            title = titleMatch.group(1) ?? '';
            debugPrint('Facebook: Título extraído de title: $title');
          }
        }

        // Método 3: Extraer desde twitter:title
        if (title.isEmpty) {
          final twitterTitleRegExp = RegExp(
            r'<meta\s+name="twitter:title"\s+content="([^"]*)"',
            caseSensitive: false,
          );
          final twitterTitleMatch = twitterTitleRegExp.firstMatch(document);
          if (twitterTitleMatch != null && twitterTitleMatch.groupCount >= 1) {
            title = twitterTitleMatch.group(1) ?? '';
            debugPrint('Facebook: Título extraído de twitter:title: $title');
          }
        }

        // Limpiar el título
        if (title.contains(' | Facebook')) {
          title = title.replaceAll(' | Facebook', '');
        } else if (title.contains(' - Facebook')) {
          title = title.replaceAll(' - Facebook', '');
        } // Extraer miniatura con métodos más robustos
        String thumbnailUrl = '';

        // Método 1: Extraer desde og:image (más común)
        final thumbnailRegExp = RegExp(
          r'<meta\s+property="og:image"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final thumbnailMatch = thumbnailRegExp.firstMatch(document);
        if (thumbnailMatch != null && thumbnailMatch.groupCount >= 1) {
          thumbnailUrl = thumbnailMatch.group(1) ?? '';
          debugPrint('Facebook: Miniatura extraída de og:image: $thumbnailUrl');
        }

        // Método 2: Extraer desde twitter:image
        if (thumbnailUrl.isEmpty) {
          final altThumbnailRegExp = RegExp(
            r'<meta\s+name="twitter:image"\s+content="([^"]*)"',
            caseSensitive: false,
          );
          final altThumbnailMatch = altThumbnailRegExp.firstMatch(document);
          if (altThumbnailMatch != null && altThumbnailMatch.groupCount >= 1) {
            thumbnailUrl = altThumbnailMatch.group(1) ?? '';
            debugPrint(
              'Facebook: Miniatura extraída de twitter:image: $thumbnailUrl',
            );
          }
        }

        // Método 3: Buscar image_src
        if (thumbnailUrl.isEmpty) {
          final linkImageRegExp = RegExp(
            r'<link\s+rel="image_src"\s+href="([^"]*)"',
            caseSensitive: false,
          );
          final linkImageMatch = linkImageRegExp.firstMatch(document);
          if (linkImageMatch != null && linkImageMatch.groupCount >= 1) {
            thumbnailUrl = linkImageMatch.group(1) ?? '';
            debugPrint(
              'Facebook: Miniatura extraída de image_src: $thumbnailUrl',
            );
          }
        }

        // Método 4: Buscar imágenes específicas de Facebook
        if (thumbnailUrl.isEmpty) {
          final fbImageRegExp = RegExp(
            r'"image":"([^"]+\.(?:jpg|jpeg|png|gif)(?:\\u00[0-9a-f]{2})*)"',
            caseSensitive: false,
          );
          final fbImageMatch = fbImageRegExp.firstMatch(document);
          if (fbImageMatch != null && fbImageMatch.groupCount >= 1) {
            thumbnailUrl = fbImageMatch.group(1) ?? '';
            // Reemplazar secuencias unicode
            thumbnailUrl = thumbnailUrl
                .replaceAll(r'\u0025', '%')
                .replaceAll(r'\u002F', '/')
                .replaceAll(r'\u003A', ':')
                .replaceAll(r'\u003F', '?')
                .replaceAll(r'\u003D', '=')
                .replaceAll(r'\u0026', '&');
            debugPrint('Facebook: Miniatura extraída de JSON: $thumbnailUrl');
          }
        } // Construir un título si no se encontró
        if (title.isEmpty && baseInfo['username']?.isNotEmpty == true) {
          title = "Video de ${baseInfo['username']}";
        } else if (title.isEmpty) {
          title = "Video de Facebook";
        }

        // Limpiar y normalizar el título y la miniatura
        title = ExtractionHelper.cleanupTitle(title);
        thumbnailUrl = ExtractionHelper.normalizeImageUrl(thumbnailUrl, url);

        return {
          'title': title,
          'thumbnailUrl': thumbnailUrl,
          'username': baseInfo['username'] ?? '',
          'postId': baseInfo['postId'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error obteniendo información de Facebook: $e');
    }
    return null;
  }
}
