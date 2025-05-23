// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'extraction_helper.dart';

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
      if (baseInfo == null) {
        return null; // Obtener datos de la página con headers mejorados
      }
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'Referer':
            'https://www.google.com/', // Twitter/X puede verificar el referer
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final document =
            response.body; // Extraer título con métodos más robustos
        String title = '';
        String description = '';

        // Método 1: Extraer desde og:description (suele contener el texto completo del tweet)
        final ogDescRegExp = RegExp(
          r'<meta\s+property="og:description"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final ogDescMatch = ogDescRegExp.firstMatch(document);
        if (ogDescMatch != null && ogDescMatch.groupCount >= 1) {
          description = ogDescMatch.group(1) ?? '';
          if (description.isNotEmpty && description.length > 15) {
            title = description;
            debugPrint(
              'Twitter: Texto del tweet extraído de og:description: $title',
            );
          }
        }

        // Método 2: Extraer desde description (alternativa)
        if (title.isEmpty) {
          final descRegExp = RegExp(
            r'<meta\s+name="description"\s+content="([^"]*)"',
            caseSensitive: false,
          );
          final descMatch = descRegExp.firstMatch(document);
          if (descMatch != null && descMatch.groupCount >= 1) {
            description = descMatch.group(1) ?? '';
            if (description.isNotEmpty &&
                description.length > 15 &&
                !description.startsWith("Log in") &&
                !description.startsWith("Sign in")) {
              title = description;
              debugPrint(
                'Twitter: Texto del tweet extraído de description: $title',
              );
            }
          }
        }

        // Método 3: Extraer desde datos JSON incrustados (mejor para obtener el texto real)
        final tweetTextRegExp = RegExp(
          r'"text":"([^"]+)"',
          caseSensitive: false,
        );
        final tweetTextMatch = tweetTextRegExp.firstMatch(document);
        if (tweetTextMatch != null && tweetTextMatch.groupCount >= 1) {
          final tweetText = tweetTextMatch.group(1) ?? '';
          if (tweetText.length > 5) {
            title = tweetText.replaceAll(r'\"', '"').replaceAll(r'\n', ' ');
            debugPrint('Twitter: Texto real del tweet extraído: $title');
          }
        }

        // Método 4: Extraer desde og:title
        if (title.isEmpty) {
          final ogTitleRegExp = RegExp(
            r'<meta\s+property="og:title"\s+content="([^"]*)"',
            caseSensitive: false,
          );
          final ogTitleMatch = ogTitleRegExp.firstMatch(document);
          if (ogTitleMatch != null && ogTitleMatch.groupCount >= 1) {
            title = ogTitleMatch.group(1) ?? '';
            debugPrint('Twitter: Título extraído de og:title: $title');
          }
        }

        // Método 5: Título normal como último recurso
        if (title.isEmpty) {
          final titleRegExp = RegExp(
            r'<title>(.*?)<\/title>',
            caseSensitive: false,
          );
          final titleMatch = titleRegExp.firstMatch(document);
          if (titleMatch != null && titleMatch.groupCount >= 1) {
            title = titleMatch.group(1) ?? '';
            debugPrint('Twitter: Título extraído de title: $title');
          }
        }

        // Limpieza adicional del título
        if (title.contains(' / X')) {
          title = title.split(' / X')[0].trim();
        } else if (title.contains(' / Twitter')) {
          title = title.split(' / Twitter')[0].trim();
        } else if (title.contains(': "')) {
          // Extraer solo el contenido del tweet
          title = title
              .replaceAll(RegExp(r'^.*?: "'), '')
              .replaceAll(RegExp(r'"$'), ''); // Corregido RegExp
        } // Extraer miniatura con métodos más robustos
        String thumbnailUrl = '';

        // Método 1: Extraer desde og:image (método estándar)
        final thumbnailRegExp = RegExp(
          r'<meta\s+property="og:image"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final thumbnailMatch = thumbnailRegExp.firstMatch(document);
        if (thumbnailMatch != null && thumbnailMatch.groupCount >= 1) {
          thumbnailUrl = thumbnailMatch.group(1) ?? '';
          debugPrint('Twitter: Miniatura extraída de og:image: $thumbnailUrl');
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
              'Twitter: Miniatura extraída de twitter:image: $thumbnailUrl',
            );
          }
        }

        // Método 3: Buscar imágenes en formato JSON
        if (thumbnailUrl.isEmpty) {
          final jsonImageRegExp = RegExp(
            r'"image_url":"([^"]+\.(?:jpg|jpeg|png)(?:\\u00[0-9a-f]{2})*)"',
            caseSensitive: false,
          );
          final jsonImageMatch = jsonImageRegExp.firstMatch(document);
          if (jsonImageMatch != null && jsonImageMatch.groupCount >= 1) {
            thumbnailUrl = jsonImageMatch.group(1) ?? '';
            // Reemplazar secuencias unicode
            thumbnailUrl = thumbnailUrl
                .replaceAll(r'\u0025', '%')
                .replaceAll(r'\u002F', '/')
                .replaceAll(r'\u003A', ':')
                .replaceAll(r'\u003F', '?')
                .replaceAll(r'\u003D', '=')
                .replaceAll(r'\u0026', '&');
            debugPrint('Twitter: Miniatura extraída de JSON: $thumbnailUrl');
          }
        }

        // Método 4: Buscar URLs de imágenes específicas de Twitter/X
        if (thumbnailUrl.isEmpty) {
          final imgUrlRegExp = RegExp(
            r'https?://pbs\\.twimg\\.com/[^?#\\s]+\\.(?:jpg|jpeg|png|gif)(?:[?#][^\\s]*)?', // RegExp simplificada y corregida
            caseSensitive: false,
          );
          final matches = imgUrlRegExp.allMatches(
            document,
          ); // Corregido: usar 'document' directamente
          if (matches.isNotEmpty) {
            // Elegir la imagen que parece tener mejor resolución o es media_img
            for (final match in matches) {
              final url = match.group(0) ?? '';
              if (url.contains('media_img')) {
                thumbnailUrl = url;
                debugPrint(
                  'Twitter: Miniatura de media_img encontrada: $thumbnailUrl',
                );
                break;
              }
            }

            // Si no encontramos media_img, usar la primera imagen
            if (thumbnailUrl.isEmpty) {
              thumbnailUrl = matches.first.group(0) ?? '';
              debugPrint(
                'Twitter: Miniatura extraída de URL genérica: $thumbnailUrl',
              );
            }
          }
        } // Si no tenemos título pero tenemos username, usar título genérico
        if (title.isEmpty && baseInfo['username']?.isNotEmpty == true) {
          title = "Tweet de @${baseInfo['username']}";
        } else if (title.isEmpty) {
          title = "Tweet";
        }

        // Limpiar y normalizar título y miniatura
        title = ExtractionHelper.cleanupTitle(title);
        thumbnailUrl = ExtractionHelper.normalizeImageUrl(thumbnailUrl, url);

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
