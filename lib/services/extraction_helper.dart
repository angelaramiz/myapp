import 'dart:convert';
import 'package:flutter/material.dart';

/// Clase de utilidad para mejorar y normalizar la extracción de información de plataformas
class ExtractionHelper {
  /// Convierte URLs relativas a absolutas y corrige errores comunes en las URLs de miniaturas
  static String normalizeImageUrl(String imageUrl, String baseUrl) {
    if (imageUrl.isEmpty) return '';

    // Si ya es una URL absoluta, solo la limpiamos
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return _cleanupUrl(imageUrl);
    }

    // Convertir relativas a absolutas
    if (imageUrl.startsWith('//')) {
      // URL con protocolo relativo
      return _cleanupUrl('https:$imageUrl');
    } else if (imageUrl.startsWith('/')) {
      // URL relativa a la raíz
      try {
        final uri = Uri.parse(baseUrl);
        final baseHost = '${uri.scheme}://${uri.host}';
        return _cleanupUrl('$baseHost$imageUrl');
      } catch (e) {
        debugPrint('Error parseando URL base: $e');
        return '';
      }
    } else {
      // Otra URL relativa
      try {
        final uri = Uri.parse(baseUrl);
        final path = uri.path;
        final basePath = path.endsWith('/')
            ? path
            : path.substring(0, path.lastIndexOf('/') + 1);
        final baseHost = '${uri.scheme}://${uri.host}';
        return _cleanupUrl('$baseHost$basePath$imageUrl');
      } catch (e) {
        debugPrint('Error parseando URL relativa: $e');
        return '';
      }
    }
  }

  /// Limpia una URL de problemas comunes y escapes
  static String _cleanupUrl(String url) {
    return url
        .replaceAll(r'\u0025', '%')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u003A', ':')
        .replaceAll(r'\u003F', '?')
        .replaceAll(r'\u003D', '=')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u002E', '.')
        .replaceAll(r'\/', '/');
  }
  /// Limpia y mejora un título
  static String cleanupTitle(String title) {
    if (title.isEmpty) {
      return ''; // Decodificar secuencias Unicode (por ejemplo emojis)
    }
    try {
      final decoded =
          json.decode('"${title.replaceAll('"', '\\"')}"') as String;
      title = decoded;
    } catch (e) {
      // Ignorar si falla el decode
    }
    String cleanTitle = title;

    // Eliminar secuencias de escape comunes
    cleanTitle = cleanTitle
        .replaceAll(r'\u0022', '"')
        .replaceAll(r'\u0027', "'")
        .replaceAll(r'\u002C', ',')
        .replaceAll(r'\u002E', '.')
        .replaceAll(r'\u003A', ':')
        .replaceAll(r'\u003B', ';')
        .replaceAll(r'\/', '/');

    // Eliminar múltiples espacios en blanco
    // Eliminar múltiples espacios
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Limitar la longitud del título para evitar títulos excesivamente largos
    if (cleanTitle.length > 200) {
      cleanTitle = '${cleanTitle.substring(0, 197)}...';
    }

    return cleanTitle;
  }

  /// Verifica si un título parece ser genérico o realmente contiene información útil
  static bool isGenericTitle(String title, String platform) {
    // Convertir a minúsculas para comparaciones más robustas
    final lowercaseTitle = title.toLowerCase();

    // Patrones de títulos genéricos
    final genericPatterns = [
      'facebook',
      'instagram',
      'tiktok',
      'tweet',
      'twitter',
      'video de',
      'post de',
      'reel de',
      'contenido de',
      'contenido compartido',
      'log in',
      'sign in',
      'iniciar sesión',
    ];

    for (var pattern in genericPatterns) {
      if (lowercaseTitle.contains(pattern) &&
          lowercaseTitle.length < pattern.length + 20) {
        return true;
      }
    }

    // Si el título es muy corto, probablemente es genérico
    if (lowercaseTitle.length < 10) {
      return true;
    }

    return false;
  }
}
