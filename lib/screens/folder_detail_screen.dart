import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/video_link.dart';
import '../services/data_service.dart';
import 'video_detail_screen.dart';
import 'add_video_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final Folder folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final DataService _dataService = DataService();
  late Future<List<VideoLink>> _videoLinksFuture;

  @override
  void initState() {
    super.initState();
    _refreshVideoLinks();
  }

  void _refreshVideoLinks() {
    setState(() {
      _videoLinksFuture = _dataService.getVideoLinksByFolder(widget.folder.id);
    });
  }

  Future<void> _deleteVideoLink(VideoLink videoLink) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación'),
        content: Text(
          '¿Estás seguro de eliminar el video "${videoLink.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteVideoLink(videoLink.id);
      _refreshVideoLinks();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video "${videoLink.title}" eliminado')),
        );
      }
    }
  }

  Future<void> _editFolder() async {
    final TextEditingController nameController = TextEditingController(
      text: widget.folder.name,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: widget.folder.description ?? '',
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Carpeta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingresa el nombre de la carpeta',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ingresa una descripción',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedFolder = widget.folder.copyWith(
                    name: nameController.text.trim(),
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );

                  await _dataService.saveFolder(updatedFolder);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    // Actualizar el widget con el folder actualizado
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Carpeta actualizada exitosamente'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre de la carpeta es requerido'),
                    ),
                  );
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editFolder),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.folder.description != null &&
              widget.folder.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.folder.description!,
                style: const TextStyle(fontSize: 16),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Videos Guardados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<VideoLink>>(
              future: _videoLinksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final videoLinks = snapshot.data ?? [];

                if (videoLinks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay videos en esta carpeta.\nAñade tu primer video!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: videoLinks.length,
                  itemBuilder: (context, index) {
                    final videoLink = videoLinks[index];
                    return VideoLinkCard(
                      videoLink: videoLink,
                      onDelete: () => _deleteVideoLink(videoLink),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoDetailScreen(videoLink: videoLink),
                          ),
                        ).then((_) => _refreshVideoLinks());
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVideoScreen(folderId: widget.folder.id),
            ),
          ).then((_) => _refreshVideoLinks());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class VideoLinkCard extends StatelessWidget {
  final VideoLink videoLink;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const VideoLinkCard({
    super.key,
    required this.videoLink,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (videoLink.thumbnailUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  videoLink.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    );
                  },
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      videoLink.getPlatformIcon(),
                      size: 50,
                      color: videoLink.getPlatformColor(),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Platform
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          videoLink.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        videoLink.getPlatformIcon(),
                        color: videoLink.getPlatformColor(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  if (videoLink.description.isNotEmpty)
                    Text(
                      videoLink.description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Reminder and Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reminder indicator
                      if (videoLink.reminder != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.alarm,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${videoLink.reminder!.day}/${videoLink.reminder!.month}/${videoLink.reminder!.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),

                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
