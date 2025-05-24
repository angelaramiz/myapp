import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'extraction_helper.dart';

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

  /// Obtiene diferentes User-Agents para evitar bloqueos
  static List<String> _getUserAgents() {
    return [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/120.0',
    ];
  }

  /// Método principal para obtener información de un post de Instagram
  static Future<Map<String, String>?> getInstagramInfo(String url) async {
    try {
      // Extraer información base
      Map<String, String>? baseInfo = extractPostInfo(url);
      if (baseInfo == null) {
        return null;
      }

      final userAgents = _getUserAgents();

      // Intentar con diferentes user agents si el primero falla
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
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-User': '?1',
            'Upgrade-Insecure-Requests': '1',
            'Referer': attempt == 0
                ? 'https://www.google.com/'
                : 'https://t.co/',
          };

          debugPrint(
            'Instagram: Intento ${attempt + 1} con User-Agent: ${userAgents[attempt].substring(0, 50)}...',
          );

          final response = await http.get(Uri.parse(url), headers: headers);
          if (response.statusCode == 200) {
            final document = response.body;

            // Extraer título con métodos más robustos
            String title = '';
            String description = '';

            // Método 1: Extraer desde og:title
            final ogTitleRegExp = RegExp(
              r'<meta\s+property="og:title"\s+content="([^"]*)"',
              caseSensitive: false,
            );
            final ogTitleMatch = ogTitleRegExp.firstMatch(document);
            if (ogTitleMatch != null && ogTitleMatch.groupCount >= 1) {
              title = ogTitleMatch.group(1) ?? '';
              debugPrint('Instagram: Título extraído de og:title: $title');
            }

            // Método 2: Extraer desde meta description que suele contener el contenido real
            final descRegExp = RegExp(
              r'<meta\s+name="description"\s+content="([^"]*)"',
              caseSensitive: false,
            );
            final descMatch = descRegExp.firstMatch(document);
            if (descMatch != null && descMatch.groupCount >= 1) {
              description = descMatch.group(1) ?? '';
              debugPrint('Instagram: Descripción extraída: $description');

              // Si la descripción es más larga que el título actual y contiene texto real
              // (normalmente contiene la descripción del post/reel)
              if (description.length > 20 &&
                  (title.isEmpty || description.length > title.length)) {
                // Usamos la descripción como título si parece más informativa
                title = description;
              }
            }

            // Método 3: Título normal
            if (title.isEmpty) {
              final titleRegExp = RegExp(
                r'<title>(.*?)<\/title>',
                caseSensitive: false,
              );
              final titleMatch = titleRegExp.firstMatch(document);
              if (titleMatch != null && titleMatch.groupCount >= 1) {
                title = titleMatch.group(1) ?? '';
                debugPrint('Instagram: Título extraído de title: $title');
              }
            }

            // Limpieza adicional del título
            if (title.contains(' en Instagram:')) {
              title = title.split(' en Instagram:')[0].trim();
            } else if (title.contains(' on Instagram:')) {
              title = title.split(' on Instagram:')[0].trim();
            } else if (title.contains(' (@')) {
              title = title.split(' (@')[0].trim();
            } else if (title.contains(' shared a ')) {
              // Extraer el contenido real del título
              title = title
                  .replaceAll(
                    RegExp(r'.*shared a (post|reel|photo|video):\s*'),
                    '',
                  )
                  .trim();
            }

            // Extraer miniatura con métodos más robustos
            String thumbnailUrl = '';

            // Método 1: Extraer desde og:image (método estándar)
            final thumbnailRegExp = RegExp(
              r'<meta\s+property="og:image"\s+content="([^"]*)"',
              caseSensitive: false,
            );
            final thumbnailMatch = thumbnailRegExp.firstMatch(document);
            if (thumbnailMatch != null && thumbnailMatch.groupCount >= 1) {
              thumbnailUrl = thumbnailMatch.group(1) ?? '';
              debugPrint(
                'Instagram: Miniatura extraída de og:image: $thumbnailUrl',
              );
            }

            // Método 2: Extraer desde twitter:image
            if (thumbnailUrl.isEmpty) {
              final altThumbnailRegExp = RegExp(
                r'<meta\s+name="twitter:image"\s+content="([^"]*)"',
                caseSensitive: false,
              );
              final altThumbnailMatch = altThumbnailRegExp.firstMatch(document);
              if (altThumbnailMatch != null &&
                  altThumbnailMatch.groupCount >= 1) {
                thumbnailUrl = altThumbnailMatch.group(1) ?? '';
                debugPrint(
                  'Instagram: Miniatura extraída de twitter:image: $thumbnailUrl',
                );
              }
            }

            // Método 3: Buscar en el HTML por URLs de imágenes específicas de Instagram
            if (thumbnailUrl.isEmpty) {
              // Buscar URLs de imagen en el formato común de Instagram
              final imgUrlRegExp = RegExp(
                r'"display_url":"([^"]+)"',
                caseSensitive: false,
              );
              final imgUrlMatch = imgUrlRegExp.firstMatch(document);
              if (imgUrlMatch != null && imgUrlMatch.groupCount >= 1) {
                thumbnailUrl = imgUrlMatch.group(1) ?? '';
                // Reemplazar secuencias unicode
                thumbnailUrl = thumbnailUrl
                    .replaceAll(r'\u0025', '%')
                    .replaceAll(r'\/', '/');
                debugPrint(
                  'Instagram: Miniatura extraída del código JSON: $thumbnailUrl',
                );
              }
            }

            // Método 4: Buscar por patrón en atributo content
            if (thumbnailUrl.isEmpty) {
              final contentImgRegExp = RegExp(
                r'content="(https:\/\/[^"]*instagram[^"]*\.(?:jpg|jpeg|png))"',
                caseSensitive: false,
              );
              final contentImgMatches = contentImgRegExp.allMatches(document);
              for (var match in contentImgMatches) {
                if (match.groupCount >= 1) {
                  thumbnailUrl = match.group(1) ?? '';
                  if (thumbnailUrl.isNotEmpty) {
                    debugPrint(
                      'Instagram: Miniatura extraída de atributo content: $thumbnailUrl',
                    );
                    break;
                  }
                }
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

            // Limpiar y normalizar título y miniatura
            title = ExtractionHelper.cleanupTitle(title);
            thumbnailUrl = ExtractionHelper.normalizeImageUrl(
              thumbnailUrl,
              url,
            );

            return {
              'title': title,
              'thumbnailUrl': thumbnailUrl,
              'username': baseInfo['username'] ?? '',
              'postId': baseInfo['postId'] ?? '',
              'isReel': baseInfo['isReel'] ?? 'false',
            };
          }
        } catch (e) {
          debugPrint('Error en intento ${attempt + 1} de Instagram: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo información de Instagram: $e');
    }
    return null;
  }
}
