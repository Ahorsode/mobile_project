import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/python.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../widgets/file_explorer_drawer.dart';
import '../services/python_service.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  late CodeController _codeController;
  final ScrollController _consoleScrollController = ScrollController();
  final FocusNode _consoleFocusNode = FocusNode();
  final TextEditingController _consoleInputController = TextEditingController();
  String _currentAppPath = "";
  String _currentPath = ""; // Path relative to app documents
  List<FileSystemEntity> _files = [];
  String _currentFileName = ""; // Full relative path to currently open file

  PythonService? _pythonService;
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: 'print("Hello from PyQuest!")\n',
      language: python,
    );
    _initializeWorkspace();
  }

  Future<void> _initializeWorkspace() async {
    final appDir = await getApplicationDocumentsDirectory();
    _currentAppPath = appDir.path;
    _currentPath = _currentAppPath;
    _pythonService = PythonService(userCodeDir: _currentAppPath);
    await _refreshFileList();

    // Default file
    if (await File(p.join(_currentAppPath, "user_script.py")).exists()) {
      await _loadFile("user_script.py");
    }
  }

  Future<void> _refreshFileList() async {
    final dir = Directory(_currentPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final entities = await dir.list().toList();
    setState(() {
      _files = entities
          .where(
            (e) =>
                !e.path.endsWith(".log") &&
                !e.path.endsWith(".lock") &&
                !e.path.endsWith(".txt"),
          )
          .toList();
    });
  }

  Future<void> _loadFile(String fileName) async {
    final filePath = p.isAbsolute(fileName)
        ? fileName
        : p.join(_currentPath, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      final content = await file.readAsString();
      setState(() {
        _currentFileName = p.relative(filePath, from: _currentAppPath);
        _codeController.text = content;
      });
    }
  }

  Future<void> _saveCurrentFile() async {
    if (_currentFileName.isEmpty) {
      _currentFileName = "user_script.py";
    }
    final file = File(p.join(_currentAppPath, _currentFileName));
    await file.writeAsString(_codeController.text);
  }

  Future<void> _createNewFile(String name, {bool isFolder = false}) async {
    final targetPath = p.join(_currentPath, name);
    if (isFolder) {
      final dir = Directory(targetPath);
      await dir.create();
    } else {
      final file = File(targetPath);
      await file.writeAsString("");
    }
    _refreshFileList();
  }

  void _navigateToFolder(String folderName) {
    setState(() {
      _currentPath = p.join(_currentPath, folderName);
    });
    _refreshFileList();
  }

  void _navigateUp() {
    if (_currentPath != _currentAppPath) {
      setState(() {
        _currentPath = p.dirname(_currentPath);
      });
      _refreshFileList();
    }
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['py'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String content = await file.readAsString();

      final targetFile = File(p.join(_currentPath, fileName));
      await targetFile.writeAsString(content);

      await _refreshFileList();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Imported $fileName")));
    }
  }

  void _insertQuickCode() {
    _codeController.text = '''# Quick Code Template
name = input("Enter your name: ")
print(f"Welcome to PyQuest, {name}!")

# Simple loop example
for i in range(5):
    print(f"Counting: {i}")
''';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pythonService?.dispose();
    _consoleScrollController.dispose();
    _consoleFocusNode.dispose();
    _consoleInputController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    if (_pythonService == null) return;

    _showConsolePopup(context);
    await _saveCurrentFile();

    final userScriptPath = p.join(_currentAppPath, "user_script.py");
    if (_currentFileName != "user_script.py") {
      final currentFile = File(p.join(_currentAppPath, _currentFileName));
      if (await currentFile.exists()) {
        await currentFile.copy(userScriptPath);
      }
    }

    await _pythonService!.runCode();

    if (mounted) {
      setState(() {}); // Refresh run state
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitInput() async {
    final input = _consoleInputController.text;
    await _pythonService?.submitInput(input);

    if (mounted) {
      setState(() {
        _consoleInputController.clear();
      });
      _scrollToBottom();
    }
  }

  void _showConsolePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final isRunning = _pythonService?.isRunning ?? false;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Console Output",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            if (isRunning)
                              const Padding(
                                padding: EdgeInsets.only(left: 12.0),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        controller: _consoleScrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBuilder<String>(
                              stream: _pythonService?.outputStream,
                              builder: (context, snapshot) {
                                final output =
                                    snapshot.data ?? "// Initializing...";
                                _scrollToBottom();
                                return Text(
                                  output,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                            StreamBuilder<bool>(
                              stream: _pythonService?.inputRequestStream,
                              builder: (context, snapshot) {
                                final isInputRequested = snapshot.data ?? false;
                                if (isInputRequested) {
                                  _consoleFocusNode.requestFocus();
                                  return TextField(
                                    controller: _consoleInputController,
                                    focusNode: _consoleFocusNode,
                                    onSubmitted: (val) {
                                      _submitInput();
                                      setPopupState(() {});
                                    },
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    cursorColor: Colors.blueAccent,
                                    autofocus: true,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNameDialog(bool isFolder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFolder ? "New Folder" : "New File"),
        content: TextField(
          controller: _fileNameController,
          decoration: InputDecoration(
            hintText: isFolder ? "folder_name" : "script.py",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_fileNameController.text.isNotEmpty) {
                _createNewFile(_fileNameController.text, isFolder: isFolder);
                _fileNameController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Workspace: $_currentFileName"),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            onPressed: () => _showConsolePopup(context),
            tooltip: "Open Console",
          ),
        ],
      ),
      drawer: FileExplorerDrawer(
        files: _files,
        currentFileName: p.basename(_currentFileName),
        isRoot: _currentPath == _currentAppPath,
        onFileSelected: _loadFile,
        onFolderSelected: _navigateToFolder,
        onNavigateUp: _navigateUp,
        onImportFile: _importFile,
        onFileDeleted: (entity) async {
          await entity.delete(recursive: true);
          _refreshFileList();
        },
        onCreateFile: () => _showNameDialog(false),
        onCreateFolder: () => _showNameDialog(true),
      ),
      body: Column(
        children: [
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: CodeField(
                  controller: _codeController,
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                  expands: true,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: _insertQuickCode,
                  icon: const Icon(Icons.bolt),
                  label: const Text("Quick Code"),
                  backgroundColor: Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  onPressed: (_pythonService?.isRunning ?? false)
                      ? null
                      : _runCode,
                  icon: (_pythonService?.isRunning ?? false)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    (_pythonService?.isRunning ?? false)
                        ? "Running..."
                        : "Run Code",
                  ),
                  backgroundColor: (_pythonService?.isRunning ?? false)
                      ? Colors.grey
                      : Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
