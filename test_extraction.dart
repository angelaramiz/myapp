import 'dart:async';
import 'package:flutter/material.dart';
import 'lib/services/url_service.dart';
import 'lib/services/youtube_extraction_service.dart';
import 'lib/services/facebook_extraction_service.dart';
import 'lib/services/instagram_extraction_service.dart';
import 'lib/services/tiktok_extraction_service.dart';
import 'lib/models/video_link.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba de Extracción',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ExtractionTestScreen(),
    );
  }
}

class ExtractionTestScreen extends StatefulWidget {
  const ExtractionTestScreen({super.key});

  @override
  State<ExtractionTestScreen> createState() => _ExtractionTestScreenState();
}

class _ExtractionTestScreenState extends State<ExtractionTestScreen> {
  final TextEditingController _urlController = TextEditingController();
  final UrlService _urlService = UrlService();
  Map<String, String>? _extractionResult = {}; // Permitir null
  PlatformType _detectedPlatform = PlatformType.other;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // Realiza pruebas de extracción con la URL proporcionada
  Future<void> _testExtraction() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _error = 'Por favor ingresa una URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _extractionResult = {};
    });

    try {
      // Detectar plataforma
      final platform = _urlService.detectPlatform(url);

      setState(() {
        _detectedPlatform = platform;
      });

      Map<String, String>? result;
      switch (platform) {
        case PlatformType.youtube:
          result = await YouTubeExtractionService.getYouTubeVideoInfo(url);
          break;
        case PlatformType.facebook:
          result = await FacebookExtractionService.getFacebookInfo(url);
          break;
        case PlatformType.instagram:
          result = await InstagramExtractionService.getInstagramInfo(url);
          break;
        case PlatformType.tiktok:
          result = await TikTokExtractionService.getTikTokInfo(url);
          break;
        case PlatformType.twitter:
          // result = await TwitterExtractionService.getTwitterInfo(url); // Comentado temporalmente por errores en el servicio
          setState(() {
            _error =
                "La extracción de Twitter está temporalmente deshabilitada.";
            _isLoading = false;
          });
          return; // Salir temprano si es Twitter
        default:
          result = await _urlService.getOtherPlatformInfo(url, platform);
      }

      if (result != null) {
        setState(() {
          _extractionResult = result;
        });
      } else {
        setState(() {
          _error = 'No se pudo extraer información';
          _extractionResult = null; // Asegurar que sea null si no hay resultado
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error durante la extracción: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de Extracción de Información')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL para probar',
                hintText: 'https://youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testExtraction,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Probar Extracción'),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error),
                ),
              ),
            if (_detectedPlatform != PlatformType.other && _error.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Plataforma detectada: ${_detectedPlatform.toString().split('.').last}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_extractionResult != null &&
                _extractionResult!
                    .isNotEmpty) // Comprobar si no es null antes de acceder a isNotEmpty
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        if (_extractionResult!.containsKey(
                              'thumbnailUrl',
                            ) && // Usar ! para acceso seguro
                            _extractionResult!['thumbnailUrl']!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Miniatura:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  _extractionResult!['thumbnailUrl']!, // Usar ! para acceso seguro
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Text(
                                          'Error al cargar la imagen',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        if (_extractionResult!.containsKey(
                              'title',
                            ) && // Usar ! para acceso seguro
                            _extractionResult!['title']!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Título:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _extractionResult!['title']!,
                              ), // Usar ! para acceso seguro
                              const SizedBox(height: 16),
                            ],
                          ),
                        // Mostrar todos los datos extraídos
                        const Text(
                          'Todos los datos:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_extractionResult!.entries.map(
                          // Usar ! para acceso seguro
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(child: Text(entry.value)),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
