import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/folder_list_screen.dart';
import 'screens/share_receiver_screen.dart';
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

  @override
  void initState() {
    super.initState();

    // Suscribirnos a nuevos enlaces compartidos
    _sharedTextSub = ShareIntentService.instance.sharedUrlStream.listen((url) {
      if (url.isNotEmpty) {
        _navigateToShareReceiverScreen(url);
      }
    });
  }

  @override
  void dispose() {
    _sharedTextSub.cancel();
    super.dispose();
  }

  void _navigateToShareReceiverScreen(String url) {
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShareReceiverScreen(sharedUrl: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Biblioteca de Videos',
      debugShowCheckedModeBanner: false,
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
      home:
          widget.initialSharedUrl != null && widget.initialSharedUrl!.isNotEmpty
          ? ShareReceiverScreen(sharedUrl: widget.initialSharedUrl!)
          : const FolderListScreen(),
    );
  }
}
