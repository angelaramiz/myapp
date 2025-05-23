import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      if (baseInfo == null) return null;

      // Obtener datos de la página
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final document = response.body;

        // Extraer título
        String title = '';
        final titleRegExp = RegExp(
          r'<title>(.*?)<\/title>',
          caseSensitive: false,
        );
        final titleMatch = titleRegExp.firstMatch(document);
        if (titleMatch != null && titleMatch.groupCount >= 1) {
          title = titleMatch.group(1) ?? '';

          // Limpiar el título
          if (title.contains(' | Facebook')) {
            title = title.replaceAll(' | Facebook', '');
          }
        }

        // Extraer miniatura
        String thumbnailUrl = '';
        final thumbnailRegExp = RegExp(
          r'<meta\s+property="og:image"\s+content="(.*?)"',
          caseSensitive: false,
        );
        final thumbnailMatch = thumbnailRegExp.firstMatch(document);
        if (thumbnailMatch != null && thumbnailMatch.groupCount >= 1) {
          thumbnailUrl = thumbnailMatch.group(1) ?? '';
        }

        // Si no se encontró una miniatura, intentar con otra etiqueta
        if (thumbnailUrl.isEmpty) {
          final altThumbnailRegExp = RegExp(
            r'<meta\s+name="twitter:image"\s+content="(.*?)"',
            caseSensitive: false,
          );
          final altThumbnailMatch = altThumbnailRegExp.firstMatch(document);
          if (altThumbnailMatch != null && altThumbnailMatch.groupCount >= 1) {
            thumbnailUrl = altThumbnailMatch.group(1) ?? '';
          }
        }

        // Construir un título si no se encontró
        if (title.isEmpty && baseInfo['username']?.isNotEmpty == true) {
          title = "Video de ${baseInfo['username']}";
        } else if (title.isEmpty) {
          title = "Video de Facebook";
        }

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
