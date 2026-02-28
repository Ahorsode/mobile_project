import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:serious_python/serious_python.dart';

/// A service that manages Python execution and log-watching in a background Isolate.
/// This prevents the Main UI Thread from stuttering on budget devices (Fetch-Decode-Execute decoupling).
class PythonService {
  final String userCodeDir;
  final String assetZipPath;

  Isolate? _logWatcherIsolate;
  final StreamController<String> _outputStreamController =
      StreamController<String>.broadcast();
  final StreamController<bool> _inputRequestController =
      StreamController<bool>.broadcast();

  bool _isRunning = false;

  PythonService({
    required this.userCodeDir,
    this.assetZipPath = "assets/app.zip",
  });

  /// Stream of cumulative console output.
  Stream<String> get outputStream => _outputStreamController.stream;

  /// Stream of input request status.
  Stream<bool> get inputRequestStream => _inputRequestController.stream;

  bool get isRunning => _isRunning;

  /// Starts the Python script execution and log-watching.
  Future<void> runCode() async {
    if (_isRunning) return;
    _isRunning = true;

    // Clear previous logs
    final logFile = File("$userCodeDir/output.log");
    if (await logFile.exists()) {
      await logFile.writeAsString("");
    }

    _outputStreamController.add(
      "PyQuest Console v3.1 (Optimized)\n-------------------\n",
    );

    // Start background log watcher isolate
    final ReceivePort receivePort = ReceivePort();
    _logWatcherIsolate = await Isolate.spawn(
      _watchLogs,
      _LogWatcherParams(
        logPath: logFile.path,
        lockPath: "$userCodeDir/input.lock",
        sendPort: receivePort.sendPort,
      ),
    );

    receivePort.listen((message) {
      if (message is String) {
        _outputStreamController.add(message);
      } else if (message is bool) {
        _inputRequestController.add(message);
      }
    });

    try {
      // serious_python.run is async but it blocks until the script finished IF not handled carefully.
      // However, it runs native Python code which SHOULD NOT block the Dart Event Loop entirely,
      // but polling files on the main thread definitely does.
      await SeriousPython.run(
        assetZipPath,
        environmentVariables: {"USER_CODE_DIR": userCodeDir},
      );
    } catch (e) {
      _outputStreamController.add("\n[Python Error]: $e");
    } finally {
      await stop();
    }
  }

  /// Stops execution and cleans up resources.
  Future<void> stop() async {
    _isRunning = false;
    _logWatcherIsolate?.kill(priority: Isolate.immediate);
    _logWatcherIsolate = null;
    _inputRequestController.add(false);

    // Final log sync
    final logFile = File("$userCodeDir/output.log");
    if (await logFile.exists()) {
      _outputStreamController.add(await logFile.readAsString());
    }
  }

  /// Submits user input to the Python process.
  Future<void> submitInput(String input) async {
    final inputFile = File("$userCodeDir/input.txt");
    await inputFile.writeAsString(input);
    _inputRequestController.add(false);
  }

  /// Proper disposal for memory management (critical for Samsung A17/budget devices).
  void dispose() {
    stop();
    _outputStreamController.close();
    _inputRequestController.close();
  }

  /// Background Isolate function to poll files.
  /// Decouples the "Fetch-Decode-Execute" logic from the UI.
  static void _watchLogs(_LogWatcherParams params) {
    String lastContent = "";
    bool lastInputStatus = false;

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final logFile = File(params.logPath);
      if (logFile.existsSync()) {
        try {
          final content = logFile.readAsStringSync();
          if (content != lastContent) {
            params.sendPort.send(content);
            lastContent = content;
          }
        } catch (_) {}
      }

      final lockFile = File(params.lockPath);
      final exists = lockFile.existsSync();
      if (exists != lastInputStatus) {
        params.sendPort.send(exists);
        lastInputStatus = exists;
      }
    });
  }
}

class _LogWatcherParams {
  final String logPath;
  final String lockPath;
  final SendPort sendPort;

  _LogWatcherParams({
    required this.logPath,
    required this.lockPath,
    required this.sendPort,
  });
}
