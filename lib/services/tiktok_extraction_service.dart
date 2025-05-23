import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Servicio dedicado para extraer información de videos de TikTok
class TikTokExtractionService {
  /// Extrae información clave de una URL de TikTok
  static Map<String, String>? extractVideoInfo(String url) {
    try {
      String? username;
      String? videoId;

      // Extraer username para URLs normales
      final usernameRegExp = RegExp(r'tiktok\.com\/@([^\/\?]+)');
      final usernameMatch = usernameRegExp.firstMatch(url);
      if (usernameMatch != null && usernameMatch.groupCount >= 1) {
        username = usernameMatch.group(1);
      }

      // Extraer ID del video
      final videoRegExp = RegExp(r'tiktok\.com\/@[^\/]+\/video\/(\d+)');
      final videoMatch = videoRegExp.firstMatch(url);
      if (videoMatch != null && videoMatch.groupCount >= 1) {
        videoId = videoMatch.group(1);
      }

      // Extraer ID del video para URLs cortas (vm.tiktok.com)
      if (url.contains('vm.tiktok.com')) {
        final shortUrlRegExp = RegExp(r'vm\.tiktok\.com\/([^\/\?]+)');
        final shortUrlMatch = shortUrlRegExp.firstMatch(url);
        if (shortUrlMatch != null && shortUrlMatch.groupCount >= 1) {
          videoId = shortUrlMatch.group(
            1,
          ); // Este no es el ID real, solo un código corto
        }
      }

      debugPrint('TikTok: Usuario=@$username, VideoID=$videoId');
      return {'username': username ?? '', 'videoId': videoId ?? '', 'url': url};
    } catch (e) {
      debugPrint('Error extrayendo información de TikTok: $e');
      return null;
    }
  }

  /// Método principal para obtener información de un video de TikTok
  static Future<Map<String, String>?> getTikTokInfo(String url) async {
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
          // Limpiar el título (TikTok suele añadir texto extra)
          if (title.contains(' | TikTok')) {
            title = title.split(' | TikTok')[0];
          }
        }

        // Extraer descripción
        String description = '';
        final descRegExp = RegExp(
          r'<meta\s+name="description"\s+content="(.*?)"',
          caseSensitive: false,
        );
        final descMatch = descRegExp.firstMatch(document);
        if (descMatch != null && descMatch.groupCount >= 1) {
          description = descMatch.group(1) ?? '';
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

        // Si no tenemos un título pero tenemos username, usar un título genérico
        if (title.isEmpty && baseInfo['username']?.isNotEmpty == true) {
          title = "Video de @${baseInfo['username']}";
        } else if (title.isEmpty) {
          title = "Video de TikTok";
        }

        return {
          'title': title,
          'description': description,
          'thumbnailUrl': thumbnailUrl,
          'username': baseInfo['username'] ?? '',
          'videoId': baseInfo['videoId'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error obteniendo información de TikTok: $e');
    }
    return null;
  }
}
