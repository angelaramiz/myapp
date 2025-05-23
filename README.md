# myapp

**myapp** es una aplicación Flutter cuyo objetivo es extraer información clave de URLs de contenido multimedia en diferentes plataformas sociales (YouTube, Facebook, Instagram, TikTok y Twitter/X).

---
## Contenido
- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Tutorial](#tutorial)
- [Arquitectura](#arquitectura)
- [Licencia](#licencia)

---
## Características
- Detección automática de plataforma a partir de la URL.
- Extracción de datos clave: miniatura, título, descripción, identificador de usuario o video.
- Soporte para YouTube, Facebook, Instagram, TikTok y Twitter/X.
- Interfaz de prueba (pantalla de test) para validar URLs en tiempo real.
- Diseño responsivo usando Material 3.

## Requisitos
- Flutter SDK (>=3.0.0)
- Conexión a internet (para realizar peticiones HTTP)

## Instalación
1. Clona este repositorio:
   ```shell
   git clone <url-del-repositorio>
   cd myapp
   ```
2. Obtén las dependencias:
   ```shell
   flutter pub get
   ```
3. Ejecuta la aplicación en un emulador o dispositivo:
   ```shell
   flutter run
   ```

## Uso
1. Al iniciar la app verás la pantalla principal.
2. Ingresa una URL de contenido (por ejemplo, un enlace de YouTube, Instagram, TikTok, Facebook o Twitter/X).
3. Pulsa **Probar Extracción**.
4. Observa los resultados:
   - Miniatura (si está disponible).
   - Título o descripción extraídos.
   - Mapa de todos los datos que se recuperaron.

## Tutorial
1. Abre la aplicación en tu dispositivo/emulador.
2. Copia la URL de un contenido de YouTube: .
3. Pégala en el campo de texto y pulsa **Probar Extracción**.
4. Verás la miniatura del video y el título extraído.
5. Repite los pasos con otras plataformas:
   - Facebook: comparte un enlace de video o post.
   - Instagram: enlace de foto o reel.
   - TikTok: enlace de video.
   - Twitter/X: enlace de tweet.

## Arquitectura
La app está organizada en:
- **lib/services**: contiene servicios responsables de detectar la plataforma y extraer datos específicos para cada una.
  - `url_service.dart`: detecta la plataforma según la URL.
  - `*_extraction_service.dart`: para YouTube, Facebook, Instagram, TikTok y Twitter.
- **lib/models/video_link.dart**: modelo de los datos extraídos.
- **test_extraction.dart**: pantalla de prueba donde se ejecuta la extracción en tiempo real.
- **lib/extraction_helper.dart**: funciones de limpieza y normalización de títulos y URL de miniaturas.

## Licencia
Este proyecto es de código abierto y se distribuye bajo la licencia MIT.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
