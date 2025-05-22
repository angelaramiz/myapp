import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._();
  static ShareIntentService get instance => _instance;

  static const MethodChannel _channel = MethodChannel('app/share_intent');
  final StreamController<String> _sharedUrlController =
      StreamController<String>.broadcast();

  Stream<String> get sharedUrlStream => _sharedUrlController.stream;

  ShareIntentService._() {
    // Configurar el método channel para recibir enlaces compartidos
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'sharedUrl':
        final String sharedUrl = call.arguments as String;
        _sharedUrlController.add(sharedUrl);
        break;
      default:
        break;
    }
  }

  // Método para comprobar si hay un enlace inicial al arrancar la app
  Future<String?> getInitialSharedUrl() async {
    try {
      final String? initialUrl = await _channel.invokeMethod<String>(
        'getInitialSharedUrl',
      );
      return initialUrl;
    } catch (e) {
      debugPrint('Error al obtener el enlace compartido inicial: $e');
      return null;
    }
  }

  void dispose() {
    _sharedUrlController.close();
  }
}
