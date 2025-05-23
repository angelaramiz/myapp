import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'extraction_helper.dart';

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
      if (baseInfo == null) return null;      // Obtener datos de la página con headers mejorados
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'Referer': 'https://www.google.com/',  // Algunos sitios verifican el referer
      };
      
      // TikTok puede requerir seguir redirecciones
      final response = await http.get(
        Uri.parse(url), 
        headers: headers,
        // Configuración adicional que podría ser necesaria en el cliente http
      );
      if (response.statusCode == 200) {
        final document = response.body;        // Extraer título con métodos más robustos
        String title = '';
        String description = '';
        
        // Método 1: Extraer desde meta keywords (a veces contiene descripción real)
        final keywordsRegExp = RegExp(
          r'<meta\s+name="keywords"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final keywordsMatch = keywordsRegExp.firstMatch(document);
        if (keywordsMatch != null && keywordsMatch.groupCount >= 1) {
          final keywords = keywordsMatch.group(1) ?? '';
          if (keywords.length > 20 && !keywords.contains('tiktok') && !keywords.contains(',')) {
            title = keywords;
            debugPrint('TikTok: Texto extraído de keywords: $title');
          }
        }
        
        // Método 2: Extraer desde og:title (más fiable)
        if (title.isEmpty) {
          final ogTitleRegExp = RegExp(
            r'<meta\s+property="og:title"\s+content="([^"]*)"',
            caseSensitive: false,
          );
          final ogTitleMatch = ogTitleRegExp.firstMatch(document);
          if (ogTitleMatch != null && ogTitleMatch.groupCount >= 1) {
            title = ogTitleMatch.group(1) ?? '';
            debugPrint('TikTok: Título extraído de og:title: $title');
          }
        }
        
        // Método 3: Extraer desde description (suele contener el texto real del video)
        final descRegExp = RegExp(
          r'<meta\s+name="description"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final descMatch = descRegExp.firstMatch(document);
        if (descMatch != null && descMatch.groupCount >= 1) {
          description = descMatch.group(1) ?? '';
          debugPrint('TikTok: Descripción extraída: $description');
          
          // Si la descripción contiene contenido real del video y es más significativa que el título
          if (description.length > 20 && 
              (title.isEmpty || 
               (description.length > title.length && !description.startsWith("Discover ")))) {
            title = description;
            debugPrint('TikTok: Usando descripción como título por ser más completa');
          }
        }
        
        // Método 4: Extraer desde twitter:description (alternativa)
        if (title.isEmpty) {
          final twitterDescRegExp = RegExp(
            r'<meta\s+name="twitter:description"\s+content="([^"]*)"',
            caseSensitive: false,
          );
          final twitterDescMatch = twitterDescRegExp.firstMatch(document);
          if (twitterDescMatch != null && twitterDescMatch.groupCount >= 1) {
            final twitterDesc = twitterDescMatch.group(1) ?? '';
            if (twitterDesc.length > 20) {
              title = twitterDesc;
              debugPrint('TikTok: Texto extraído de twitter:description: $title');
            }
          }
        }
        
        // Método 5: Título regular como último recurso
        if (title.isEmpty) {
          final titleRegExp = RegExp(
            r'<title>(.*?)<\/title>',
            caseSensitive: false,
          );
          final titleMatch = titleRegExp.firstMatch(document);
          if (titleMatch != null && titleMatch.groupCount >= 1) {
            title = titleMatch.group(1) ?? '';
            debugPrint('TikTok: Título extraído de title: $title');
          }
        }
        
        // Limpieza adicional del título
        if (title.contains(' | TikTok')) {
          title = title.split(' | TikTok')[0].trim();
        } else if (title.contains('#')) {
          // Extraer hashtags si hay
          final hashtags = RegExp(r'#\w+').allMatches(title).map((m) => m.group(0)).join(' ');
          if (hashtags.isNotEmpty && hashtags.length < title.length) {
            debugPrint('TikTok: Hashtags encontrados: $hashtags');
            // Si los hashtags son la parte más importante, usarlos
            if (title.trim().startsWith('#') && hashtags.length > 10) {
              title = hashtags;
            }
          }
        }
        
        // Extraer el texto real del video (más limpio)
        final videoTextRegExp = RegExp(
          r'"text":"([^"]+)"',
          caseSensitive: false,
        );
        final videoTextMatch = videoTextRegExp.firstMatch(document);
        if (videoTextMatch != null && videoTextMatch.groupCount >= 1) {
          final videoText = videoTextMatch.group(1) ?? '';
          if (videoText.length > 10) {
            title = videoText;
            debugPrint('TikTok: Texto real del video extraído: $title');
          }
        }        // Extraer miniatura con métodos más robustos
        String thumbnailUrl = '';
        
        // Método 1: Extraer desde og:image (método estándar)
        final thumbnailRegExp = RegExp(
          r'<meta\s+property="og:image"\s+content="([^"]*)"',
          caseSensitive: false,
        );
        final thumbnailMatch = thumbnailRegExp.firstMatch(document);
        if (thumbnailMatch != null && thumbnailMatch.groupCount >= 1) {
          thumbnailUrl = thumbnailMatch.group(1) ?? '';
          debugPrint('TikTok: Miniatura extraída de og:image: $thumbnailUrl');
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
            debugPrint('TikTok: Miniatura extraída de twitter:image: $thumbnailUrl');
          }
        }
        
        // Método 3: Buscar en datos JSON incrustados
        if (thumbnailUrl.isEmpty) {
          // TikTok suele incluir las imágenes en un objeto JSON
          final jsonImageRegExp = RegExp(
            r'"thumbnailUrl":"([^"]+\.(?:jpg|jpeg|png))"',
            caseSensitive: false,
          );
          final jsonImageMatch = jsonImageRegExp.firstMatch(document);
          if (jsonImageMatch != null && jsonImageMatch.groupCount >= 1) {
            thumbnailUrl = jsonImageMatch.group(1) ?? '';
            thumbnailUrl = thumbnailUrl.replaceAll(r'\/', '/');
            debugPrint('TikTok: Miniatura extraída de JSON: $thumbnailUrl');
          }
        }
        
        // Método 4: Buscar por patrón de imagen de alta calidad 
        if (thumbnailUrl.isEmpty) {
          final patternImgRegExp = RegExp(
            r'<img[^>]+src="([^"]+\.(?:jpg|jpeg|png)[^"]*)"[^>]*\bclass="[^"]*poster[^"]*"',
            caseSensitive: false,
          );
          final patternImgMatch = patternImgRegExp.firstMatch(document);
          if (patternImgMatch != null && patternImgMatch.groupCount >= 1) {
            thumbnailUrl = patternImgMatch.group(1) ?? '';
            debugPrint('TikTok: Miniatura extraída de elemento img: $thumbnailUrl');
          }
        }
        
        // Método 5: Cualquier URL que parezca de imagen
        if (thumbnailUrl.isEmpty) {
          final imgUrlRegExp = RegExp(
            r'https?://[^\s"]+\.(?:jpg|jpeg|png|webp)(?:[^\s">]*)',
            caseSensitive: false,
          );
          final imgUrlMatch = imgUrlRegExp.firstMatch(document);
          if (imgUrlMatch != null) {
            thumbnailUrl = imgUrlMatch.group(0) ?? '';
            debugPrint('TikTok: Miniatura extraída de URL genérica: $thumbnailUrl');
          }
        }

        // Si no tenemos un título pero tenemos username, usar un título genérico
        if (title.isEmpty && baseInfo['username']?.isNotEmpty == true) {
          title = "Video de @${baseInfo['username']}";
        } else if (title.isEmpty) {
          title = "Video de TikTok";
        }
        
        // Limpiar y normalizar título y miniatura
        title = ExtractionHelper.cleanupTitle(title);
        thumbnailUrl = ExtractionHelper.normalizeImageUrl(thumbnailUrl, url);

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
