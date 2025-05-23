import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Servicio dedicado para extraer información de tweets
class TwitterExtractionService {
  /// Extrae información clave de una URL de Twitter/X
  static Map<String, String>? extractTweetInfo(String url) {
    try {
      String? username;
      String? tweetId;

      // Determinar si es Twitter o X.com
      RegExp usernameRegExp;
      RegExp tweetRegExp;

      if (url.contains('twitter.com')) {
        usernameRegExp = RegExp(r'twitter\.com\/([^\/\?]+)');
        tweetRegExp = RegExp(r'twitter\.com\/[^\/]+\/status\/(\d+)');
      } else if (url.contains('x.com')) {
        usernameRegExp = RegExp(r'x\.com\/([^\/\?]+)');
        tweetRegExp = RegExp(r'x\.com\/[^\/]+\/status\/(\d+)');
      } else {
        // URL corta de Twitter (t.co)
        return {'url': url};
      }

      // Extraer username
      final usernameMatch = usernameRegExp.firstMatch(url);
      if (usernameMatch != null && usernameMatch.groupCount >= 1) {
        username = usernameMatch.group(1);
        if (username == 'i' || username == 'share' || username == 'status') {
          username = null; // Estos no son nombres de usuario válidos
        }
      }

      // Extraer ID del tweet
      final tweetMatch = tweetRegExp.firstMatch(url);
      if (tweetMatch != null && tweetMatch.groupCount >= 1) {
        tweetId = tweetMatch.group(1);
      }

      debugPrint('Twitter: Usuario=@$username, TweetID=$tweetId');
      return {'username': username ?? '', 'tweetId': tweetId ?? '', 'url': url};
    } catch (e) {
      debugPrint('Error extrayendo información de Twitter: $e');
      return null;
    }
  }

  /// Método principal para obtener información de un tweet
  static Future<Map<String, String>?> getTwitterInfo(String url) async {
    try {
      // Extraer información base
      Map<String, String>? baseInfo = extractTweetInfo(url);
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
          // Limpiar el título (Twitter/X añade "/ X" o "/ Twitter" al final)
          if (title.contains(' / X')) {
            title = title.split(' / X')[0];
          } else if (title.contains(' / Twitter')) {
            title = title.split(' / Twitter')[0];
          }
        }

        // Extraer descripción (texto del tweet)
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

        // Si no tenemos título pero tenemos username, usar título genérico
        if (title.isEmpty && baseInfo['username']?.isNotEmpty == true) {
          title = "Tweet de @${baseInfo['username']}";
        } else if (title.isEmpty) {
          title = "Tweet";
        }

        return {
          'title': title,
          'description': description,
          'thumbnailUrl': thumbnailUrl,
          'username': baseInfo['username'] ?? '',
          'tweetId': baseInfo['tweetId'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error obteniendo información de Twitter: $e');
    }
    return null;
  }
}
