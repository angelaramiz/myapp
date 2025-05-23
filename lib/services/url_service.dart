import 'package:flutter/material.dart';
import '../models/video_link.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:http/http.dart' as http;

class UrlService {
  // Función para obtener información de una URL de YouTube
  Future<Map<String, String>?> getYouTubeInfo(String url) async {
    try {
      // Extraer ID de video de YouTube
      RegExp regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      RegExpMatch? match = regExp.firstMatch(url);

      if (match != null && match.groupCount >= 1) {
        String videoId = match.group(1)!;

        // Log para depuración
        debugPrint('ID de video de YouTube extraído: $videoId');

        // Este es un enfoque simplificado. En una app real, deberías usar la API de YouTube
        // con una clave API apropiada para obtener esta información.
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

        // Intentar extraer el título del video usando petición HTTP para obtener el contenido
        String title = "";

        // Primero, intentamos extraerlo de la URL si contiene el parámetro title
        RegExp titleRegExp = RegExp(r'(?:title=)([^&]+)');
        RegExpMatch? titleMatch = titleRegExp.firstMatch(url);
        if (titleMatch != null && titleMatch.groupCount >= 1) {
          // Decodificar el título de la URL
          title = Uri.decodeComponent(
            titleMatch.group(1)!.replaceAll('+', ' '),
          );
          debugPrint('Título extraído de la URL: $title');
        }

        // Si no se encontró un título en la URL, intentamos obtenerlo desde el contenido de la página
        if (title.isEmpty) {
          try {
            debugPrint(
              'Intentando obtener título desde contenido de la página...',
            );

            // Usamos un User-Agent para evitar bloqueos
            final headers = {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
            };

            final response = await http.get(
              Uri.parse('https://www.youtube.com/watch?v=$videoId'),
              headers: headers,
            );

            if (response.statusCode == 200) {
              // Extraer el título de la etiqueta <title>
              final htmlContent = response.body;
              debugPrint(
                'Respuesta recibida con éxito, longitud: ${htmlContent.length}',
              );

              final titleRegExp = RegExp(
                r'<title>(.*?)<\/title>',
                caseSensitive: false,
              );
              final titleMatch = titleRegExp.firstMatch(htmlContent);
              if (titleMatch != null && titleMatch.groupCount >= 1) {
                String extractedTitle = titleMatch.group(1) ?? '';
                debugPrint('Título extraído del HTML: $extractedTitle');

                // Limpiar el título (YouTube generalmente añade " - YouTube" al final)
                if (extractedTitle.endsWith(' - YouTube')) {
                  extractedTitle = extractedTitle.substring(
                    0,
                    extractedTitle.length - 10,
                  );
                }
                title = extractedTitle.trim();
                debugPrint('Título limpio: $title');
              }
            } else {
              debugPrint(
                'Error al obtener contenido: Código ${response.statusCode}',
              );
            }
          } catch (e) {
            debugPrint('Error obteniendo título desde contenido: $e');
          }
        }

        return {
          'thumbnailUrl': thumbnailUrl,
          'videoId': videoId,
          'title': title,
        };
      }
    } catch (e) {
      debugPrint('Error extracting YouTube info: $e');
    }
    return null;
  }

  // Función para obtener información de otras plataformas
  Future<Map<String, String>?> getOtherPlatformInfo(
    String url,
    PlatformType platform,
  ) async {
    debugPrint('Obteniendo información para URL: $url, plataforma: $platform');
    try {
      // Usamos un User-Agent para evitar bloqueos
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final document = response.body;
        debugPrint(
          'Respuesta recibida con éxito, longitud: ${document.length}',
        );

        // Extraer título
        final titleRegExp = RegExp(
          r'<title>(.*?)<\/title>',
          caseSensitive: false,
        );
        final titleMatch = titleRegExp.firstMatch(document);
        final title = titleMatch != null
            ? titleMatch.group(1)
            : 'Contenido compartido';

        debugPrint('Título extraído: $title');

        // Extraer miniatura (simplificado)
        final thumbnailRegExp = RegExp(
          r'<meta property="og:image" content="(.*?)"',
          caseSensitive: false,
        );
        final thumbnailMatch = thumbnailRegExp.firstMatch(document);
        final thumbnailUrl = thumbnailMatch != null
            ? thumbnailMatch.group(1)
            : '';

        return {'title': title ?? '', 'thumbnailUrl': thumbnailUrl ?? ''};
      }
    } catch (e) {
      debugPrint('Error extracting info from other platform: $e');
    }
    return null;
  }

  // Determinar la plataforma basado en la URL
  PlatformType detectPlatform(String url) {
    String lowercaseUrl = url.toLowerCase();

    if (lowercaseUrl.contains('youtube.com') ||
        lowercaseUrl.contains('youtu.be')) {
      return PlatformType.youtube;
    } else if (lowercaseUrl.contains('facebook.com') ||
        lowercaseUrl.contains('fb.watch') ||
        lowercaseUrl.contains('fb.me')) {
      return PlatformType.facebook;
    } else if (lowercaseUrl.contains('instagram.com') ||
        lowercaseUrl.contains('instagr.am')) {
      return PlatformType.instagram;
    } else if (lowercaseUrl.contains('tiktok.com') ||
        lowercaseUrl.contains('vm.tiktok.com')) {
      return PlatformType.tiktok;
    } else if (lowercaseUrl.contains('twitter.com') ||
        lowercaseUrl.contains('x.com') ||
        lowercaseUrl.contains('t.co')) {
      return PlatformType.twitter;
    } else {
      return PlatformType.other;
    }
  }

  // Intenta extraer un título de la URL dependiendo de la plataforma
  String? extractTitleFromUrl(String url, PlatformType platform) {
    debugPrint(
      'Intentando extraer título de URL: $url (Plataforma: $platform)',
    );
    try {
      // Extrae el título de diferentes formas según la plataforma
      switch (platform) {
        case PlatformType.youtube:
          // Para YouTube, no devolvemos un título genérico sino null
          // La extracción del título real se maneja en getYouTubeInfo
          debugPrint(
            'URL de YouTube detectada, el título se obtendrá con getYouTubeInfo',
          );
          return null;

        case PlatformType.facebook:
          // Tratar de extraer el título del segmento de la ruta
          debugPrint('Extrayendo título de Facebook URL');
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            if (pathSegments.contains('posts')) {
              int index = pathSegments.indexOf('posts');
              if (index > 0) {
                String username = pathSegments[index - 1].replaceAll('.', ' ');
                debugPrint('Nombre de usuario extraído de Facebook: $username');
                return "Video de $username";
              }
            } else if (pathSegments.isNotEmpty) {
              // Si no encontramos 'posts', intentamos usar el primer segmento útil
              for (final segment in pathSegments) {
                if (segment.isNotEmpty &&
                    segment != 'watch' &&
                    segment != 'video' &&
                    !segment.contains('.php')) {
                  debugPrint('Segmento útil encontrado: $segment');
                  return "Contenido de Facebook: $segment";
                }
              }
            }
          }
          return "Video de Facebook";
        case PlatformType.instagram:
          debugPrint('Extrayendo título de Instagram URL');
          // Intentar extraer username
          final regExp = RegExp(r'instagram\.com\/(?:p\/|reel\/)?([^\/\?]+)');
          final match = regExp.firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            final username = match.group(1);
            debugPrint('Usuario de Instagram encontrado: $username');
            if (url.contains('/p/') || url.contains('/reel/')) {
              return "Post de Instagram";
            }
            return "Post de @$username";
          }
          return "Contenido de Instagram";

        case PlatformType.tiktok:
          debugPrint('Extrayendo título de TikTok URL');
          // Intentar extraer username
          final regExp = RegExp(r'tiktok\.com\/@([^\/\?]+)');
          final match = regExp.firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            final username = match.group(1);
            debugPrint('Usuario de TikTok encontrado: $username');
            return "Video de @$username";
          }

          // Intentar extraer ID del video para URLs cortas
          final shortRegExp = RegExp(r'vm\.tiktok\.com\/([^\/\?]+)');
          final shortMatch = shortRegExp.firstMatch(url);
          if (shortMatch != null && shortMatch.groupCount >= 1) {
            debugPrint('ID de TikTok encontrado en URL corta');
            return "Video de TikTok";
          }
          return "Video de TikTok";

        case PlatformType.twitter:
          debugPrint('Extrayendo título de Twitter URL');
          // Intentar extraer username
          RegExp regExp;
          if (url.contains('twitter.com')) {
            regExp = RegExp(r'twitter\.com\/([^\/\?]+)');
          } else if (url.contains('x.com')) {
            regExp = RegExp(r'x\.com\/([^\/\?]+)');
          } else {
            return "Tweet";
          }

          final match = regExp.firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            final username = match.group(1);
            debugPrint('Usuario de Twitter encontrado: $username');
            if (username != null &&
                username != 'i' &&
                username != 'status' &&
                !username.startsWith('share')) {
              return "Tweet de @$username";
            }
          }
          return "Tweet";

        default:
          debugPrint('URL de tipo desconocido, usando título genérico');
          // Para URLs desconocidas, extraer el dominio como título
          try {
            final uri = Uri.parse(url);
            final host = uri.host;
            if (host.isNotEmpty) {
              return "Contenido de ${host.replaceFirst('www.', '')}";
            }
          } catch (e) {
            debugPrint('Error al parsear URL: $e');
          }
          return "Contenido web";
      }
    } catch (e) {
      debugPrint('Error extracting title: $e');
      return null;
    }
  }

  // Abrir URL en navegador
  Future<bool> launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      return await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }
}
