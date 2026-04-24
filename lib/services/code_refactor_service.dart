import 'dart:isolate';
import 'package:google_generative_ai/google_generative_ai.dart';

class CodeRefactorService {
  late final String _apiKey;
  static const String _systemInstruction =
      "You are the PyQuest Mentor. Your goal is to help students fix Python errors based on Tony Gaddis principles. Be concise and always provide the full corrected code block.";

  CodeRefactorService() {
    _apiKey = "AIzaSyAGbANC7c4kb2X8NtyzVmG_iGupyWml0Qk";
  }

  /// Fixes the provided code, optionally taking error logs into account.
  /// Runs in a background isolate to prevent UI freezing.
  Future<String?> getFix(String code, {String? errorLog}) async {
    final prompt = errorLog != null
        ? "Fix this code after it produced this error:\nCode:\n$code\n\nError:\n$errorLog"
        : "Review and fix this Python code for potential errors or improvements:\n$code";

    return await _callAI(prompt);
  }

  /// Generates a boilerplate for a new project.
  Future<String?> generateBoilerplate(String topic) async {
    final prompt =
        "Generate a basic Python OOP boilerplate for: $topic. Follow Tony Gaddis principles.";
    return await _callAI(prompt);
  }

  /// Completes the program based on the current context.
  Future<String?> completeCode(String code) async {
    final prompt =
        "Complete this Python program based on Tony Gaddis principles. Provide ONLY the full corrected code block:\n\n$code";
    return await _callAI(prompt);
  }

  /// Sends a custom prompt to the AI.
  Future<String?> customPrompt(String userPrompt, String currentCode) async {
    final prompt =
        "User Question: $userPrompt\n\nCurrent Code Context:\n$currentCode\n\nProvide the full corrected code if applicable.";
    return await _callAI(prompt);
  }

  Future<String?> _callAI(String prompt) async {
    final apiKey = _apiKey;
    final systemInst = _systemInstruction;

    return await Isolate.run(() async {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(systemInst),
        );
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        final text = response.text;
        print("Gemini Response: $text");
        return text;
      } catch (e) {
        print("AI Call Error (Isolate): $e");
        // Return the error message to the UI so we can see what's happening
        return "AI Error: ${e.toString()}";
      }
    });
  }
}
