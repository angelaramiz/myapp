import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/video_link.dart';
import '../services/data_service.dart';
import '../services/url_service.dart';
import '../services/notification_service_simple.dart';

class AddVideoScreen extends StatefulWidget {
  final String folderId;
  final VideoLink? videoLinkToEdit; // Optional, for editing an existing video

  const AddVideoScreen({
    super.key,
    required this.folderId,
    this.videoLinkToEdit,
  });

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlService = UrlService();
  DateTime? _selectedReminderDate;
  PlatformType _selectedPlatform = PlatformType.youtube;
  String _thumbnailUrl = '';
  bool _isLoading = false;
  bool _isUrlValid = false;
  @override
  void initState() {
    super.initState();

    // If editing, populate with existing data
    if (widget.videoLinkToEdit != null) {
      _urlController.text = widget.videoLinkToEdit!.url;
      _titleController.text = widget.videoLinkToEdit!.title;
      _descriptionController.text = widget.videoLinkToEdit!.description;
      _selectedPlatform = widget.videoLinkToEdit!.platform;
      _selectedReminderDate = widget.videoLinkToEdit!.reminder;
      _thumbnailUrl = widget.videoLinkToEdit!.thumbnailUrl;
      _isUrlValid = true;
    }

    // Añadir listener para validar automáticamente cuando cambie el texto
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    // Si el texto tiene un formato válido de URL y ha cambiado, validamos automáticamente
    final url = _urlController.text.trim();
    if (url.isNotEmpty && url.startsWith('http')) {
      // Utilizamos un pequeño retraso para no validar con cada pulsación
      Future.delayed(const Duration(milliseconds: 800), () {
        // Verificamos si el texto sigue siendo el mismo después del retraso
        if (_urlController.text.trim() == url) {
          _validateUrl();
        }
      });
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _validateUrl() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final url = _urlController.text.trim();
    debugPrint('Validando URL: $url');

    // Detectar la plataforma
    final platform = _urlService.detectPlatform(url);
    debugPrint('Plataforma detectada: $platform');
    setState(() {
      _selectedPlatform = platform;
    });

    // Primero intentamos extraer un título básico de la URL
    final basicTitle = _urlService.extractTitleFromUrl(url, platform);
    if (basicTitle != null && _titleController.text.isEmpty) {
      debugPrint('Título básico extraído: $basicTitle');
      setState(() {
        _titleController.text = basicTitle;
      });
    } // Si es YouTube, trata de obtener la miniatura y el título más detallado
    if (platform == PlatformType.youtube) {
      debugPrint('Obteniendo información de YouTube...');
      final youtubeInfo = await _urlService.getYouTubeInfo(url);
      if (youtubeInfo != null) {
        debugPrint('Información de YouTube obtenida: $youtubeInfo');
        setState(() {
          _thumbnailUrl = youtubeInfo['thumbnailUrl'] ?? '';
          _isUrlValid = true;

          // Para YouTube, siempre usamos el título extraído de la API si está disponible
          final youtubeTitle = youtubeInfo['title'] ?? '';
          if (youtubeTitle.isNotEmpty) {
            debugPrint('Usando título de YouTube: $youtubeTitle');
            _titleController.text = youtubeTitle;
          } else {
            debugPrint('No se pudo extraer el título de YouTube');
            // Si no hay título de la API pero el campo está vacío, usamos un genérico
            if (_titleController.text.isEmpty) {
              _titleController.text = "Video de YouTube";
            }
          }
        });
      } else {
        debugPrint('No se pudo obtener información de YouTube');
        // Si no pudimos obtener información específica, seguimos marcando como válida
        setState(() {
          _isUrlValid = true;
        });
      }
    } else {
      debugPrint('Obteniendo información para otra plataforma...');

      // Lógica para obtener miniatura y título para otras plataformas
      final otherPlatformInfo = await _urlService.getOtherPlatformInfo(
        url,
        platform,
      );
      if (otherPlatformInfo != null) {
        debugPrint('Información obtenida: $otherPlatformInfo');
        setState(() {
          _thumbnailUrl = otherPlatformInfo['thumbnailUrl'] ?? '';
          _isUrlValid = true;

          // Si hay un título disponible y es mejor que el básico que ya teníamos
          final infoTitle = otherPlatformInfo['title'];
          if (infoTitle?.isNotEmpty == true &&
              (infoTitle!.length > _titleController.text.length ||
                  _titleController.text.isEmpty)) {
            debugPrint('Usando título de plataforma: $infoTitle');
            _titleController.text = infoTitle;
          }
        });
      } else {
        debugPrint('No se pudo obtener información para esta URL');
        // Si no pudimos obtener información específica, seguimos marcando como válida
        setState(() {
          _isUrlValid = true;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!context.mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedReminderDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveVideoLink() async {
    if (!_formKey.currentState!.validate()) return;

    // Mostrar loading
    setState(() {
      _isLoading = true;
    });

    try {
      final videoLink =
          widget.videoLinkToEdit?.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            url: _urlController.text.trim(),
            platform: _selectedPlatform,
            thumbnailUrl: _thumbnailUrl,
            reminder: _selectedReminderDate,
          ) ??
          VideoLink(
            id: const Uuid().v4(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            url: _urlController.text.trim(),
            thumbnailUrl: _thumbnailUrl,
            platform: _selectedPlatform,
            createdAt: DateTime.now(),
            reminder: _selectedReminderDate,
            folderId: widget.folderId,
          ); // Guardar en almacenamiento local
      final dataService = DataService();
      await dataService.saveVideoLink(
        videoLink,
      ); // Si hay un recordatorio, programar notificación
      if (_selectedReminderDate != null) {
        await NotificationServiceSimple.instance.scheduleNotification(
          videoLink,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.videoLinkToEdit != null
                  ? 'Video actualizado exitosamente'
                  : 'Video guardado exitosamente',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.videoLinkToEdit != null
              ? 'Editar Video'
              : 'Añadir Nuevo Video',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // URL Input with validation button
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL del Video',
                        hintText: 'Ej. https://www.youtube.com/watch?v=...',
                        suffixIcon: IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          onPressed: _validateUrl,
                        ),
                      ),
                      onEditingComplete:
                          _validateUrl, // Validar al presionar Enter
                      onFieldSubmitted: (_) =>
                          _validateUrl(), // Validar al cambiar de campo
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la URL del video';
                        }
                        if (!value.startsWith('http')) {
                          return 'La URL debe comenzar con http:// o https://';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Platform Selection
                    DropdownButtonFormField<PlatformType>(
                      decoration: const InputDecoration(
                        labelText: 'Plataforma',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPlatform,
                      items: PlatformType.values.map((platform) {
                        return DropdownMenuItem(
                          value: platform,
                          child: Row(
                            children: [
                              Icon(
                                platform == PlatformType.youtube
                                    ? Icons.youtube_searched_for
                                    : platform == PlatformType.facebook
                                    ? Icons.facebook
                                    : platform == PlatformType.instagram
                                    ? Icons.camera_alt
                                    : platform == PlatformType.tiktok
                                    ? Icons.music_note
                                    : platform == PlatformType.twitter
                                    ? Icons.campaign
                                    : Icons.link,
                                color: platform == PlatformType.youtube
                                    ? Colors.red
                                    : platform == PlatformType.facebook
                                    ? Colors.blue
                                    : platform == PlatformType.instagram
                                    ? Colors.purple
                                    : platform == PlatformType.tiktok
                                    ? Colors.black
                                    : platform == PlatformType.twitter
                                    ? Colors.lightBlue
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Text(platform.toString().split('.').last),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPlatform = newValue!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Title Input
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ingresa un título para este video',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description Input
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText:
                            'Ingresa una descripción o notas para este video',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    // Reminder Date Picker
                    ListTile(
                      title: const Text('Establecer un recordatorio'),
                      subtitle: _selectedReminderDate != null
                          ? Text(
                              '${_selectedReminderDate!.day}/${_selectedReminderDate!.month}/${_selectedReminderDate!.year} a las ${_selectedReminderDate!.hour}:${_selectedReminderDate!.minute.toString().padLeft(2, '0')}',
                            )
                          : const Text('Sin recordatorio'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.alarm_add),
                            onPressed: () => _selectDate(context),
                          ),
                          if (_selectedReminderDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedReminderDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Thumbnail Preview
                    if (_thumbnailUrl.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vista previa:'),
                          const SizedBox(height: 8),
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              _thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Text(
                                      'No se pudo cargar la vista previa',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isUrlValid ? _saveVideoLink : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.videoLinkToEdit != null
                            ? 'Actualizar Video'
                            : 'Guardar Video',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
