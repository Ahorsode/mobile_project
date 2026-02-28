import 'dart:async';
import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/python.dart';
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../widgets/file_explorer_drawer.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  late CodeController _codeController;
  String _consoleOutput = "";
  bool _isRunning = false;
  Timer? _logWatcher;
  bool _isInputRequested = false;
  final ScrollController _consoleScrollController = ScrollController();
  final FocusNode _consoleFocusNode = FocusNode();
  final TextEditingController _consoleInputController = TextEditingController();
  String _currentAppPath = "";
  List<FileSystemEntity> _files = [];
  String _currentFileName = "user_script.py";
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: 'print("Hello from PyQuest!")\n',
      language: python,
    );
    _refreshFileList();
  }

  Future<void> _refreshFileList() async {
    final appDir = await getApplicationDocumentsDirectory();
    final entities = await appDir.list().toList();
    setState(() {
      _currentAppPath = appDir.path;
      _files = entities
          .where((e) =>
              !e.path.endsWith(".log") &&
              !e.path.endsWith(".lock") &&
              !e.path.endsWith(".txt"))
          .toList();
    });
  }

  Future<void> _loadFile(String fileName) async {
    final file = File("$_currentAppPath/$fileName");
    if (await file.exists()) {
      final content = await file.readAsString();
      setState(() {
        _currentFileName = fileName;
        _codeController.text = content;
      });
    }
  }

  Future<void> _saveCurrentFile() async {
    final file = File("$_currentAppPath/$_currentFileName");
    await file.writeAsString(_codeController.text);
  }

  Future<void> _createNewFile(String name, {bool isFolder = false}) async {
    if (isFolder) {
      final dir = Directory("$_currentAppPath/$name");
      await dir.create();
    } else {
      final file = File("$_currentAppPath/$name");
      await file.writeAsString("");
    }
    _refreshFileList();
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
    _logWatcher?.cancel();
    _consoleScrollController.dispose();
    _consoleFocusNode.dispose();
    _consoleInputController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _consoleOutput = "PyQuest Console v2.0\n-------------------\n";
    });

    if (mounted) {
      _showConsolePopup(context);
    }

    await _saveCurrentFile();

    try {
      final scriptFile = File("$_currentAppPath/$_currentFileName");
      final logFilePath = "$_currentAppPath/output.log";

      final userScriptPath = "$_currentAppPath/user_script.py";
      if (_currentFileName != "user_script.py") {
        await scriptFile.copy(userScriptPath);
      }

      final logFile = File(logFilePath);
      if (await logFile.exists()) {
        await logFile.writeAsString("");
      }

      _logWatcher?.cancel();
      _logWatcher =
          Timer.periodic(const Duration(milliseconds: 50), (timer) async {
        if (await logFile.exists()) {
          final content = await logFile.readAsString();
          if (mounted) {
            setState(() {
              _consoleOutput = content;
            });
            _scrollToBottom();
          }
        }

        final lockFile = File("$_currentAppPath/input.lock");
        if (await lockFile.exists() && !_isInputRequested) {
          if (mounted) {
            setState(() {
              _isInputRequested = true;
            });
            _scrollToBottom();
            _consoleFocusNode.requestFocus();
          }
        }
      });

      await SeriousPython.run(
        "assets/app.zip",
        environmentVariables: {"USER_CODE_DIR": _currentAppPath},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _consoleOutput += "\nError: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _isInputRequested = false;
        });
        _logWatcher?.cancel();
        final logFile = File("$_currentAppPath/output.log");
        if (await logFile.exists()) {
          final content = await logFile.readAsString();
          setState(() {
            _consoleOutput = content;
          });
        }
      }
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
    final inputFile = File("$_currentAppPath/input.txt");
    await inputFile.writeAsString(input);

    if (mounted) {
      setState(() {
        _isInputRequested = false;
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
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border:
                    Border(top: BorderSide(color: Colors.blueAccent, width: 2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text("Console Output",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent)),
                            if (_isRunning)
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
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        controller: _consoleScrollController,
                        child: ListenableBuilder(
                          listenable: Listenable.merge([_consoleFocusNode]),
                          builder: (context, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _consoleOutput.isEmpty
                                      ? "// Initializing..."
                                      : _consoleOutput,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_isInputRequested)
                                  TextField(
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
                                  ),
                              ],
                            );
                          },
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
              hintText: isFolder ? "folder_name" : "script.py"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
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
        currentFileName: _currentFileName,
        onFileSelected: _loadFile,
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
                  textStyle:
                      const TextStyle(fontFamily: 'monospace', fontSize: 16),
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
                  onPressed: _isRunning ? null : _runCode,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunning ? "Running..." : "Run Code"),
                  backgroundColor: _isRunning ? Colors.grey : Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
