import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/folder_list_screen.dart';
import 'widgets/quick_save_modal.dart';
import 'services/notification_service_simple.dart';
import 'services/share_intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el servicio de notificaciones simplificado
  await NotificationServiceSimple.instance.init();

  // Verificar si la app se abrió desde un enlace compartido
  final initialUrl = await ShareIntentService.instance.getInitialSharedUrl();

  runApp(MyApp(initialSharedUrl: initialUrl));
}

class MyApp extends StatefulWidget {
  final String? initialSharedUrl;

  const MyApp({super.key, this.initialSharedUrl});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<String> _sharedTextSub;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Suscribirnos a nuevos enlaces compartidos
    _sharedTextSub = ShareIntentService.instance.sharedUrlStream.listen((url) {
      if (url.isNotEmpty) {
        _showQuickSaveModal(url);
      }
    });

    // Si la app se abrió con un enlace inicial, mostrarlo después de que se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSharedUrl != null &&
          widget.initialSharedUrl!.isNotEmpty) {
        _showQuickSaveModal(widget.initialSharedUrl!);
      }
    });
  }

  @override
  void dispose() {
    _sharedTextSub.cancel();
    super.dispose();
  }

  void _showQuickSaveModal(String url) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => QuickSaveModal(sharedUrl: url),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Biblioteca de Videos',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const FolderListScreen(),
    );
  }
}
