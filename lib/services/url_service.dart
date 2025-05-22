import 'package:flutter/material.dart';
import '../models/video_link.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

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

        // Este es un enfoque simplificado. En una app real, deberías usar la API de YouTube
        // con una clave API apropiada para obtener esta información.
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

        // Intentar extraer el título del video de la URL
        String title = "";
        // Si la URL contiene el parámetro title
        RegExp titleRegExp = RegExp(r'(?:title=)([^&]+)');
        RegExpMatch? titleMatch = titleRegExp.firstMatch(url);
        if (titleMatch != null && titleMatch.groupCount >= 1) {
          // Decodificar el título de la URL
          title = Uri.decodeComponent(
            titleMatch.group(1)!.replaceAll('+', ' '),
          );
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
    try {
      // Extrae el título de diferentes formas según la plataforma
      switch (platform) {
        case PlatformType.youtube:
          // Ya se maneja en getYouTubeInfo
          return null;

        case PlatformType.facebook:
          // Tratar de extraer el título del segmento de la ruta
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty && pathSegments.contains('posts')) {
            int index = pathSegments.indexOf('posts');
            if (index > 0) {
              return "Video de ${pathSegments[index - 1].replaceAll('.', ' ')}";
            }
          }
          return null;

        case PlatformType.instagram:
          // Intentar extraer username
          final regExp = RegExp(r'instagram\.com\/([^\/]+)');
          final match = regExp.firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            return "Post de ${match.group(1)}";
          }
          return null;

        default:
          return null;
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
