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

        return {'thumbnailUrl': thumbnailUrl, 'videoId': videoId};
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
        lowercaseUrl.contains('fb.watch')) {
      return PlatformType.facebook;
    } else if (lowercaseUrl.contains('instagram.com')) {
      return PlatformType.instagram;
    } else if (lowercaseUrl.contains('tiktok.com')) {
      return PlatformType.tiktok;
    } else if (lowercaseUrl.contains('twitter.com') ||
        lowercaseUrl.contains('x.com')) {
      return PlatformType.twitter;
    } else {
      return PlatformType.other;
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
