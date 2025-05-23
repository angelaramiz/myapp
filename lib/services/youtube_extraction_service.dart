import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'extraction_helper.dart';

/// Un servicio dedicado para extraer información de videos de YouTube
class YouTubeExtractionService {
  /// Extrae el ID del video de una URL de YouTube
  static String? extractVideoId(String url) {
    try {
      RegExp regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      RegExpMatch? match = regExp.firstMatch(url);

      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    } catch (e) {
      debugPrint('Error al extraer ID de video: $e');
    }
    return null;
  }

  /// Obtiene la miniatura de un video de YouTube por su ID
  static String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  /// Obtiene información detallada de un video de YouTube usando la API de oEmbed
  static Future<Map<String, String>> getVideoInfo(String videoId) async {
    Map<String, String> result = {
      'title': '',
      'thumbnailUrl': getThumbnailUrl(videoId),
      'videoId': videoId,
    };

    try {
      // Primero intentamos el método oEmbed que es el más confiable para obtener el título
      final oembedUrl =
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
        'Accept': 'application/json',
      };

      final response = await http.get(Uri.parse(oembedUrl), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = response.body;
        debugPrint('Respuesta de oEmbed recibida: $jsonResponse');

        // Extraer el título del JSON
        final titleRegExp = RegExp(r'"title"\s*:\s*"([^"]+)"');
        final titleMatch = titleRegExp.firstMatch(jsonResponse);

        if (titleMatch != null && titleMatch.groupCount >= 1) {
          String title = titleMatch.group(1) ?? '';
          // Decodificar las secuencias de escape JSON
          title = title.replaceAll(r'\"', '"').replaceAll(r'\/', '/');
          result['title'] = title;
          debugPrint('Título extraído de oEmbed: $title');
          return result;
        }
      }

      // Si oEmbed falla, intentamos con el método HTML
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final videoResponse = await http.get(
        Uri.parse(videoUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
        },
      );

      if (videoResponse.statusCode == 200) {
        final htmlContent = videoResponse.body;

        // Intentar extraer desde la etiqueta og:title
        final ogTitleRegExp = RegExp(
          r'<meta\s+property="og:title"\s+content="([^"]+)"',
          caseSensitive: false,
        );
        final ogTitleMatch = ogTitleRegExp.firstMatch(htmlContent);

        if (ogTitleMatch != null && ogTitleMatch.groupCount >= 1) {
          result['title'] = ogTitleMatch.group(1) ?? '';
          debugPrint('Título extraído desde og:title: ${result['title']}');
          return result;
        }

        // Si no encontramos og:title, intentamos con la etiqueta title
        final titleRegExp = RegExp(
          r'<title>(.*?)<\/title>',
          caseSensitive: false,
        );
        final titleMatch = titleRegExp.firstMatch(htmlContent);

        if (titleMatch != null && titleMatch.groupCount >= 1) {
          String extractedTitle = titleMatch.group(1) ?? '';
          // Limpiar el título (YouTube añade " - YouTube" al final)
          if (extractedTitle.endsWith(' - YouTube')) {
            extractedTitle = extractedTitle.substring(
              0,
              extractedTitle.length - 10,
            );
          }
          result['title'] = extractedTitle.trim();
          debugPrint(
            'Título extraído de la etiqueta title: ${result['title']}',
          );
          return result;
        }
      }

      // Si todo falla, intentamos buscar por otro patrón común en el HTML
      debugPrint('Usando métodos alternativos para extraer título...');
      if (videoResponse.statusCode == 200) {
        final htmlContent = videoResponse.body;

        // Buscar patrones comunes de título en el HTML de YouTube
        final patterns = [
          RegExp(r'"title":"([^"]+)"'),
          RegExp(r'"videoTitle":"([^"]+)"'),
          RegExp(r'<h1[^>]*>([^<]+)</h1>'),
        ];

        for (var pattern in patterns) {
          final match = pattern.firstMatch(htmlContent);
          if (match != null && match.groupCount >= 1) {
            result['title'] = match.group(1) ?? '';
            debugPrint(
              'Título extraído con patrón alternativo: ${result['title']}',
            );
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al obtener información del video: $e');
    }

    // Si todo falla, devolvemos lo que tenemos
    return result;
  }

  /// Método principal para obtener toda la información de un video de YouTube
  static Future<Map<String, String>?> getYouTubeVideoInfo(String url) async {
    final videoId = extractVideoId(url);
    if (videoId != null) {
      final info = await getVideoInfo(videoId);

      // Limpiar y normalizar el título y la miniatura
      if (info.containsKey('title') && info['title']!.isNotEmpty) {
        info['title'] = ExtractionHelper.cleanupTitle(info['title']!);
      }

      if (info.containsKey('thumbnailUrl') &&
          info['thumbnailUrl']!.isNotEmpty) {
        info['thumbnailUrl'] = ExtractionHelper.normalizeImageUrl(
          info['thumbnailUrl']!,
          url,
        );
      }

      return info;
    }
    return null;
  }
}
