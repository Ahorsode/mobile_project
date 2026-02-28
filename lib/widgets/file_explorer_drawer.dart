import 'dart:io';
import 'package:flutter/material.dart';

class FileExplorerDrawer extends StatelessWidget {
  final List<FileSystemEntity> files;
  final String currentFileName;
  final Function(String) onFileSelected;
  final Function(FileSystemEntity) onFileDeleted;
  final VoidCallback onCreateFile;
  final VoidCallback onCreateFolder;

  const FileExplorerDrawer({
    super.key,
    required this.files,
    required this.currentFileName,
    required this.onFileSelected,
    required this.onFileDeleted,
    required this.onCreateFile,
    required this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 40, color: Colors.blueAccent),
                const SizedBox(height: 10),
                const Text("File Explorer",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.create_new_folder,
                          color: Colors.blueAccent),
                      onPressed: onCreateFolder,
                    ),
                    IconButton(
                      icon: const Icon(Icons.note_add, color: Colors.blueAccent),
                      onPressed: onCreateFile,
                    ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final entity = files[index];
                final name = entity.path.split(Platform.pathSeparator).last;
                final isDir = entity is Directory;
                return ListTile(
                  leading: Icon(isDir ? Icons.folder : Icons.description,
                      color: isDir ? Colors.amber : Colors.blueGrey),
                  title: Text(name),
                  selected: currentFileName == name,
                  onTap: () {
                    if (!isDir) {
                      onFileSelected(name);
                      Navigator.pop(context);
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete,
                        size: 20, color: Colors.redAccent),
                    onPressed: () => onFileDeleted(entity),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
