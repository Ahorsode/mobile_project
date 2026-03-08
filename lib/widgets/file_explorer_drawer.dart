import 'dart:io';
import 'package:flutter/material.dart';

class FileExplorerDrawer extends StatelessWidget {
  final List<FileSystemEntity> files;
  final String currentFileName;
  final Function(String) onFileSelected;
  final Function(String) onFolderSelected;
  final Function(FileSystemEntity) onFileDeleted;
  final VoidCallback onCreateFile;
  final VoidCallback onCreateFolder;
  final VoidCallback onNavigateUp;
  final VoidCallback onImportFile;
  final bool isRoot;

  const FileExplorerDrawer({
    super.key,
    required this.files,
    required this.currentFileName,
    required this.onFileSelected,
    required this.onFolderSelected,
    required this.onFileDeleted,
    required this.onCreateFile,
    required this.onCreateFolder,
    required this.onNavigateUp,
    required this.onImportFile,
    required this.isRoot,
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
                const Icon(
                  Icons.folder_open,
                  size: 40,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 10),
                const Text(
                  "File Explorer",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.create_new_folder,
                        color: Colors.blueAccent,
                      ),
                      onPressed: onCreateFolder,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.note_add,
                        color: Colors.blueAccent,
                      ),
                      onPressed: onCreateFile,
                      tooltip: "New File",
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.file_upload,
                        color: Colors.greenAccent,
                      ),
                      onPressed: onImportFile,
                      tooltip: "Import from Storage",
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: files.length + (isRoot ? 0 : 1),
              itemBuilder: (context, index) {
                if (!isRoot && index == 0) {
                  return ListTile(
                    leading: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      ".. (Go Up)",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: onNavigateUp,
                  );
                }

                final entity = files[isRoot ? index : index - 1];
                final name = entity.path.split(Platform.pathSeparator).last;
                final isDir = entity is Directory;
                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.description,
                    color: isDir ? Colors.amber : Colors.blueGrey,
                  ),
                  title: Text(name),
                  selected: currentFileName == name,
                  onTap: () {
                    if (isDir) {
                      onFolderSelected(name);
                    } else {
                      onFileSelected(name);
                      Navigator.pop(context);
                    }
                  },
                  trailing:
                      (name == "Academy_Practice" ||
                          entity.path.contains("Academy_Practice"))
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.redAccent,
                          ),
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
