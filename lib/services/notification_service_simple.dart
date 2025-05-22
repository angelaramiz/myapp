import 'package:flutter/material.dart';
import '../models/video_link.dart';

// Servicio de notificaciones simplificado sin dependencias externas
class NotificationServiceSimple {
  static final NotificationServiceSimple _instance =
      NotificationServiceSimple._();
  static NotificationServiceSimple get instance => _instance;

  NotificationServiceSimple._();

  // Inicialización
  Future<void> init() async {
    debugPrint('NotificationServiceSimple: Inicializado');
  }

  // Para programar notificaciones (versión simulada)
  Future<void> scheduleNotification(VideoLink videoLink) async {
    if (videoLink.reminder == null) return;

    final reminderDate = videoLink.reminder!;
    debugPrint(
      'Notificación programada para ${videoLink.title} en fecha: '
      '${reminderDate.day}/${reminderDate.month}/${reminderDate.year} '
      'a las ${reminderDate.hour}:${reminderDate.minute}',
    );
  }

  // Para cancelar notificaciones
  Future<void> cancelNotification(VideoLink videoLink) async {
    debugPrint('Notificación cancelada para ${videoLink.title}');
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('Todas las notificaciones han sido canceladas');
  }
}
