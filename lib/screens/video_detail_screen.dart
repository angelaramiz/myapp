import 'package:flutter/material.dart';
import '../models/video_link.dart';
import '../services/url_service.dart';
import '../services/notification_service_simple.dart';
import 'add_video_screen.dart';

class VideoDetailScreen extends StatelessWidget {
  final VideoLink videoLink;
  final UrlService _urlService = UrlService();

  VideoDetailScreen({super.key, required this.videoLink});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              videoLink.getPlatformIcon(),
              color: videoLink.getPlatformColor(),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                videoLink.platform.toString().split('.').last,
                style: TextStyle(color: videoLink.getPlatformColor()),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVideoScreen(
                    folderId: videoLink.folderId,
                    videoLinkToEdit: videoLink,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (videoLink.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  videoLink.thumbnailUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 60),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    videoLink.getPlatformIcon(),
                    size: 60,
                    color: videoLink.getPlatformColor(),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Title
            Text(
              videoLink.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Created date
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Guardado el ${videoLink.createdAt.day}/${videoLink.createdAt.month}/${videoLink.createdAt.year}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // URL
            const Text(
              'URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              videoLink.url,
              style: TextStyle(
                color: Colors.blue[700],
                decoration: TextDecoration.underline,
              ),
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              videoLink.description.isNotEmpty
                  ? videoLink.description
                  : 'Sin descripción',
              style: TextStyle(
                fontSize: 16,
                color: videoLink.description.isNotEmpty ? null : Colors.grey,
                fontStyle: videoLink.description.isNotEmpty
                    ? null
                    : FontStyle.italic,
              ),
            ),

            const SizedBox(height: 24),

            // Reminder
            if (videoLink.reminder != null) ...[
              const Text(
                'Recordatorio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '${videoLink.reminder!.day}/${videoLink.reminder!.month}/${videoLink.reminder!.year} a las ${videoLink.reminder!.hour}:${videoLink.reminder!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.orange),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar recordatorio'),
                            content: const Text(
                              '¿Estás seguro de eliminar el recordatorio para este video?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await NotificationServiceSimple.instance
                              .cancelNotification(videoLink);
                          // La pantalla de edición sería la forma de actualizar el recordatorio
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recordatorio eliminado'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir Video'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: () async {
              final success = await _urlService.launchUrl(videoLink.url);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo abrir la URL')),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
