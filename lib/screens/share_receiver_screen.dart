import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/video_link.dart';
import '../services/data_service.dart';
import '../services/url_service.dart';

class ShareReceiverScreen extends StatefulWidget {
  final String sharedUrl;

  const ShareReceiverScreen({super.key, required this.sharedUrl});

  @override
  State<ShareReceiverScreen> createState() => _ShareReceiverScreenState();
}

class _ShareReceiverScreenState extends State<ShareReceiverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dataService = DataService();
  final _urlService = UrlService();

  String _thumbnailUrl = '';
  PlatformType _platform = PlatformType.other;
  List<Folder> _folders = [];
  Folder? _selectedFolder;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUrlValid = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _processSharedUrl();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    final List<Folder> folders = await _dataService.getFolders();
    setState(() {
      _folders = folders;
      if (_folders.isNotEmpty) {
        _selectedFolder = _folders.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _processSharedUrl() async {
    final url = widget.sharedUrl;

    // Detectar plataforma
    final platform = _urlService.detectPlatform(url);
    setState(() {
      _platform = platform;
    });

    // Obtener información según la plataforma
    if (platform == PlatformType.youtube) {
      final youtubeInfo = await _urlService.getYouTubeInfo(url);
      if (youtubeInfo != null) {
        setState(() {
          _thumbnailUrl = youtubeInfo['thumbnailUrl'] ?? '';
          if (youtubeInfo['title']?.isNotEmpty == true) {
            _titleController.text = youtubeInfo['title'] ?? '';
          } else {
            _titleController.text = 'Video de YouTube';
          }
          _isUrlValid = true;
        });
      } else {
        _titleController.text = 'Video de YouTube';
        _isUrlValid = true;
      }
    } else {
      // Para otras plataformas
      final extractedTitle = _urlService.extractTitleFromUrl(url, platform);
      if (extractedTitle != null) {
        _titleController.text = extractedTitle;
      } else {
        // Título genérico basado en la plataforma
        switch (platform) {
          case PlatformType.facebook:
            _titleController.text = 'Video de Facebook';
            break;
          case PlatformType.instagram:
            _titleController.text = 'Post de Instagram';
            break;
          case PlatformType.tiktok:
            _titleController.text = 'Video de TikTok';
            break;
          case PlatformType.twitter:
            _titleController.text = 'Tweet';
            break;
          default:
            _titleController.text = 'Contenido compartido';
            break;
        }
      }

      // Lógica para obtener miniatura y título para otras plataformas
      final otherPlatformInfo = await _urlService.getOtherPlatformInfo(url, platform);
      if (otherPlatformInfo != null) {
        setState(() {
          _thumbnailUrl = otherPlatformInfo['thumbnailUrl'] ?? '';
          _isUrlValid = true;

          // Si hay un título disponible y el campo está vacío, lo completamos automáticamente
          if (otherPlatformInfo['title']?.isNotEmpty == true &&
              _titleController.text.isEmpty) {
            _titleController.text = otherPlatformInfo['title'] ?? '';
          }
        });
      } else {
        setState(() {
          _isUrlValid = true;
        });
      }
    }
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate() || _selectedFolder == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final videoLink = VideoLink(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        url: widget.sharedUrl.trim(),
        thumbnailUrl: _thumbnailUrl,
        platform: _platform,
        createdAt: DateTime.now(),
        reminder: null, // Sin recordatorio por defecto desde compartido
        folderId: _selectedFolder!.id,
      );

      await _dataService.saveVideoLink(videoLink);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video guardado exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardar contenido')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // URL recibida
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _platform.getIcon(),
                                  color: _platform.getColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _platform.getName(),
                                  style: TextStyle(
                                    color: _platform.getColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.sharedUrl,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Miniatura (si está disponible)
                    if (_thumbnailUrl.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            _thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Título
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Selección de carpeta
                    const Text(
                      'Selecciona una carpeta:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (_folders.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No hay carpetas disponibles. Por favor, crea una carpeta primero.',
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _folders.length,
                          itemBuilder: (context, index) {
                            final folder = _folders[index];
                            final isSelected = _selectedFolder?.id == folder.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFolder = folder;
                                });
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      size: 40,
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey[500],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      folder.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving || _folders.isEmpty || !_isUrlValid
                            ? null
                            : _saveVideo,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar video'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
