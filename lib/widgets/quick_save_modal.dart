import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/video_link.dart';
import '../screens/share_receiver_screen.dart';
import '../services/data_service.dart';
import '../services/url_service.dart';
import '../services/thumbnail_service.dart';
import '../services/facebook_extraction_service.dart';
import '../services/instagram_extraction_service.dart';
import '../services/tiktok_extraction_service.dart';
import '../services/twitter_extraction_service.dart';

class QuickSaveModal extends StatefulWidget {
  final String sharedUrl;

  const QuickSaveModal({super.key, required this.sharedUrl});

  @override
  State<QuickSaveModal> createState() => _QuickSaveModalState();
}

class _QuickSaveModalState extends State<QuickSaveModal> {
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
  bool _isLoadingThumbnail =
      false; // Variable para tracking del estado de carga de miniatura

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
      // Para YouTube, usar tanto el servicio existente como el mejorado para miniaturas
      final youtubeInfo = await _urlService.getYouTubeInfo(url);
      String? thumbnailUrl; // Intentar obtener miniatura mejorada
      setState(() {
        _isLoadingThumbnail = true;
      });

      try {
        thumbnailUrl = await ThumbnailService.getBestThumbnail(url, platform);
      } catch (e) {
        debugPrint('Error obteniendo miniatura mejorada: $e');
      } finally {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }

      // Si no se obtuvo miniatura mejorada, usar la del servicio existente
      thumbnailUrl ??= youtubeInfo?['thumbnailUrl'];

      setState(() {
        _thumbnailUrl = thumbnailUrl ?? '';
        if (youtubeInfo != null && youtubeInfo['title']?.isNotEmpty == true) {
          _titleController.text = youtubeInfo['title'] ?? '';
        } else {
          _titleController.text = 'Video de YouTube';
        }
        _isUrlValid = true;
      });
    } else {
      // Para otras plataformas, intentar usar servicios específicos
      Map<String, String>? extractedInfo;

      try {
        switch (platform) {
          case PlatformType.facebook:
            extractedInfo = await FacebookExtractionService.getFacebookInfo(
              url,
            );
            break;
          case PlatformType.instagram:
            extractedInfo = await InstagramExtractionService.getInstagramInfo(
              url,
            );
            break;
          case PlatformType.tiktok:
            extractedInfo = await TikTokExtractionService.getTikTokInfo(url);
            break;
          case PlatformType.twitter:
            extractedInfo = await TwitterExtractionService.getTwitterInfo(url);
            break;
          default:
            extractedInfo = await _urlService.getOtherPlatformInfo(
              url,
              platform,
            );
        }
      } catch (e) {
        debugPrint('Error extrayendo información específica: $e');
      } // Usar el nuevo servicio de miniaturas mejorado para otras plataformas
      String? thumbnailUrl;
      setState(() {
        _isLoadingThumbnail = true;
      });

      try {
        thumbnailUrl = await ThumbnailService.getBestThumbnail(url, platform);
        debugPrint('Miniatura obtenida con servicio mejorado: $thumbnailUrl');
      } catch (e) {
        debugPrint('Error con servicio de miniatura mejorado: $e');
      } finally {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }

      // Si no se obtuvo miniatura con el servicio mejorado, usar la extraída
      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
        thumbnailUrl = extractedInfo?['thumbnailUrl'];
      }

      setState(() {
        _thumbnailUrl = thumbnailUrl ?? '';

        // Usar el título extraído si está disponible
        if (extractedInfo != null &&
            extractedInfo['title']?.isNotEmpty == true) {
          _titleController.text = extractedInfo['title'] ?? '';
        } else {
          // Título genérico basado en la plataforma
          _titleController.text = _getDefaultTitleForPlatform(platform);
        }

        // Usar descripción si está disponible
        if (extractedInfo != null &&
            extractedInfo['description']?.isNotEmpty == true) {
          _descriptionController.text = extractedInfo['description'] ?? '';
        }

        _isUrlValid = true;
      });
    }
  }

  String _getDefaultTitleForPlatform(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return 'Video de YouTube';
      case PlatformType.facebook:
        return 'Video de Facebook';
      case PlatformType.instagram:
        return 'Post de Instagram';
      case PlatformType.tiktok:
        return 'Video de TikTok';
      case PlatformType.twitter:
        return 'Tweet';
      default:
        return 'Contenido compartido';
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
          const SnackBar(
            content: Text('Video guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle para arrastrar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Título del modal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Guardar contenido compartido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Botón para abrir pantalla completa
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ShareReceiverScreen(
                                sharedUrl: widget.sharedUrl,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_full),
                        tooltip: 'Abrir en pantalla completa',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                // Contenido del modal
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // URL y plataforma
                                _buildUrlInfoCard(),
                                const SizedBox(
                                  height: 16,
                                ), // Miniatura si está disponible
                                if (_thumbnailUrl.isNotEmpty)
                                  _buildThumbnailCard()
                                else if (_isLoadingThumbnail)
                                  _buildLoadingThumbnail()
                                else
                                  _buildThumbnailPlaceholder(),
                                const SizedBox(height: 16),

                                // Campo de título
                                _buildTitleField(),
                                const SizedBox(height: 16),

                                // Campo de descripción
                                _buildDescriptionField(),
                                const SizedBox(height: 16),

                                // Selector de carpeta
                                _buildFolderSelector(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                ),

                // Botones de acción
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUrlInfoCard() {
    return Card(
      elevation: 2,
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _platform.getName(),
                  style: TextStyle(
                    color: _platform.getColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.sharedUrl,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailCard() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Imagen principal
            Image.network(
              _thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cargando miniatura...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error cargando miniatura: $error');
                return Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No se pudo cargar la miniatura',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Overlay con icono de plataforma
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(_platform.getIcon(), color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Card(
      elevation: 2,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _platform.getColor().withValues(alpha: 0.1),
                _platform.getColor().withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_platform.getIcon(), size: 60, color: _platform.getColor()),
              const SizedBox(height: 8),
              Text(
                'Contenido de ${_platform.getName()}',
                style: TextStyle(
                  color: _platform.getColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Miniatura no disponible',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingThumbnail() {
    return Card(
      elevation: 2,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _platform.getColor().withValues(alpha: 0.05),
                _platform.getColor().withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _platform.getColor()),
              const SizedBox(height: 16),
              Icon(
                _platform.getIcon(),
                size: 40,
                color: _platform.getColor().withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                'Obteniendo miniatura...',
                style: TextStyle(
                  color: _platform.getColor(),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'De ${_platform.getName()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Título',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El título es requerido';
        }
        return null;
      },
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Descripción (opcional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildFolderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccionar carpeta:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_folders.isEmpty)
          Card(
            color: Colors.orange[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay carpetas disponibles. Crea una carpeta primero.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
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
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
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
                          size: 32,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[500],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          folder.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
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
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar video'),
            ),
          ),
        ],
      ),
    );
  }
}
