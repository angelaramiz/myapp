import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Servicio dedicado para extraer información de posts de Instagram
class InstagramExtractionService {
  /// Extrae información clave de una URL de Instagram
  static Map<String, String>? extractPostInfo(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      String? username;
      String? postId;
      bool isReel = false;

      // Intentar extraer username y ID del post
      if (pathSegments.contains('p') &&
          pathSegments.length > pathSegments.indexOf('p') + 1) {
        int pIndex = pathSegments.indexOf('p');
        postId = pathSegments[pIndex + 1];

        // Intentar obtener el username si está disponible
        if (pIndex > 0) {
          username = pathSegments[0];
        }
        debugPrint('Instagram post: Usuario=$username, PostID=$postId');
      } else if (pathSegments.contains('reel') &&
          pathSegments.length > pathSegments.indexOf('reel') + 1) {
        int reelIndex = pathSegments.indexOf('reel');
        postId = pathSegments[reelIndex + 1];
        isReel = true;

        // Intentar obtener el username si está disponible
        if (reelIndex > 0) {
          username = pathSegments[0];
        }
        debugPrint('Instagram reel: Usuario=$username, PostID=$postId');
      } else if (pathSegments.isNotEmpty) {
        // Asumir que el primer segmento es un nombre de usuario
        username = pathSegments[0];
        debugPrint('Instagram profile: Usuario=$username');
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

  /// Método principal para obtener información de un post de Instagram
  static Future<Map<String, String>?> getInstagramInfo(String url) async {
    try {
      // Extraer información base
      Map<String, String>? baseInfo = extractPostInfo(url);
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
          // Limpiar título (Instagram suele incluir "en Instagram:" o similares)
          if (title.contains(' en Instagram:')) {
            title = title.split(' en Instagram:')[0];
          } else if (title.contains(' on Instagram:')) {
            title = title.split(' on Instagram:')[0];
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

        // Si no hay miniatura por og:image, intentar con twitter:image
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

        // Construir título si no se encontró
        if (title.isEmpty) {
          if (baseInfo['isReel'] == 'true') {
            title = baseInfo['username']?.isNotEmpty == true
                ? "Reel de @${baseInfo['username']}"
                : "Reel de Instagram";
          } else if (baseInfo['username']?.isNotEmpty == true) {
            title = "Post de @${baseInfo['username']}";
          } else {
            title = "Post de Instagram";
          }
        }

        return {
          'title': title,
          'thumbnailUrl': thumbnailUrl,
          'username': baseInfo['username'] ?? '',
          'postId': baseInfo['postId'] ?? '',
          'isReel': baseInfo['isReel'] ?? 'false',
        };
      }
    } catch (e) {
      debugPrint('Error obteniendo información de Instagram: $e');
    }
    return null;
  }
}
