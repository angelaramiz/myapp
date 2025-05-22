import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../services/data_service.dart';
import 'package:uuid/uuid.dart';
import 'folder_detail_screen.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  final DataService _dataService = DataService();
  late Future<List<Folder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _refreshFolders();
  }

  void _refreshFolders() {
    setState(() {
      _foldersFuture = _dataService.getFolders();
    });
  }

  Future<void> _showAddFolderDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva Carpeta'),
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
                  final newFolder = Folder(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  await _dataService.saveFolder(newFolder);
                  _refreshFolders();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Carpeta creada exitosamente'),
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
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación'),
        content: Text(
          '¿Estás seguro de eliminar la carpeta "${folder.name}"? Esto también eliminará todos los videos guardados dentro de esta carpeta.',
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
      await _dataService.deleteFolder(folder.id);
      _refreshFolders();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Carpeta "${folder.name}" eliminada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Biblioteca de Videos')),
      body: FutureBuilder<List<Folder>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final folders = snapshot.data ?? [];

          if (folders.isEmpty) {
            return const Center(
              child: Text(
                'No hay carpetas. ¡Crea tu primera carpeta!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: const Icon(
                  Icons.folder,
                  size: 40,
                  color: Colors.amber,
                ),
                title: Text(folder.name),
                subtitle: folder.description != null
                    ? Text(
                        folder.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteFolder(folder),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FolderDetailScreen(folder: folder),
                    ),
                  ).then((_) => _refreshFolders());
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
