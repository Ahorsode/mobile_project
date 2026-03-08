import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/code_refactor_service.dart';
import '../providers/code_provider.dart';

class GeminiOverlay extends StatefulWidget {
  final String Function() getLatestLogs;

  const GeminiOverlay({super.key, required this.getLatestLogs});

  @override
  State<GeminiOverlay> createState() => GeminiOverlayState();
}

class GeminiOverlayState extends State<GeminiOverlay> {
  final CodeRefactorService _aiService = CodeRefactorService();
  final TextEditingController _promptController = TextEditingController();
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;
  String? _aiResponse;

  /// Public method to trigger AI analysis from outside (e.g., on console error)
  Future<void> triggerAIAnalysis({bool isError = false}) async {
    if (_isLoading) return; // Throttling

    final codeProvider = Provider.of<CodeProvider>(context, listen: false);
    final codeController = codeProvider.activeController;
    if (codeController == null) return;

    _showOverlay();
    setState(() => _isLoading = true);
    _updateOverlay();

    try {
      final code = codeController.text;
      final logs = widget.getLatestLogs();

      if (isError || logs.isNotEmpty) {
        _aiResponse = await _aiService.getFix(code, errorLog: logs);
      } else if (code.trim().isEmpty) {
        _aiResponse =
            "Your workspace is empty. Type a prompt below to generate a program!";
      } else {
        _aiResponse = await _aiService.getFix(code);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _updateOverlay();
      }
    }
  }

  Future<void> _handleCustomPrompt() async {
    if (_isLoading) return;
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final codeProvider = Provider.of<CodeProvider>(context, listen: false);
    final codeController = codeProvider.activeController;
    if (codeController == null) return;

    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });
    _updateOverlay();

    try {
      final code = codeController.text;
      _aiResponse = await _aiService.customPrompt(prompt, code);
      _promptController.clear();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _updateOverlay();
      }
    }
  }

  Future<void> _handleComplete() async {
    if (_isLoading) return;
    final codeProvider = Provider.of<CodeProvider>(context, listen: false);
    final codeController = codeProvider.activeController;
    if (codeController == null) return;

    setState(() => _isLoading = true);
    _updateOverlay();
    try {
      _aiResponse = await _aiService.completeCode(codeController.text);
    } finally {
      setState(() => _isLoading = false);
      _updateOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildResponsePanel());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertCode() {
    if (_aiResponse == null) return;

    final codeProvider = Provider.of<CodeProvider>(context, listen: false);
    final codeController = codeProvider.activeController;
    if (codeController == null) return;

    final regex = RegExp(r"```python\n([\s\S]*?)```");
    final match = regex.firstMatch(_aiResponse!);
    final codeToInsert = match != null ? match.group(1) : _aiResponse;

    if (codeToInsert != null) {
      codeController.text = codeToInsert.trim();
      _closeOverlay();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isLoading ? "Mentor is thinking..." : "Gemini Assistant",
      child: GestureDetector(
        onTap: () {
          if (_isLoading) return;
          if (_overlayEntry != null) {
            _closeOverlay();
          } else {
            triggerAIAnalysis();
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _isLoading
                  ? [Colors.grey, Colors.blueGrey]
                  : [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsePanel() {
    final bool hasCode =
        _aiResponse != null && _aiResponse!.contains("```python");
    final bool isError =
        _aiResponse != null && _aiResponse!.contains("AI Error");
    final codeProvider = Provider.of<CodeProvider>(context, listen: false);
    final codeText = codeProvider.activeController?.text ?? "";

    return Stack(
      children: [
        Positioned(
          top: 60,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 500),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "PyQuest Mentor",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white54,
                        ),
                        onPressed: _closeOverlay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Text(
                              _aiResponse ?? "How can I help you today?",
                              style: TextStyle(
                                fontSize: 13,
                                color: isError
                                    ? Colors.redAccent
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),
                  if (!_isLoading) ...[
                    const SizedBox(height: 12),
                    if (hasCode)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _insertCode,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            codeText.isEmpty ? "Insert Code" : "Apply Fix",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (codeText.isNotEmpty && !hasCode && !isError)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleComplete,
                          icon: const Icon(Icons.add_task, size: 18),
                          label: const Text("Complete Program"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                            side: const BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Ask Gemini something...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          onPressed: _handleCustomPrompt,
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _handleCustomPrompt(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
