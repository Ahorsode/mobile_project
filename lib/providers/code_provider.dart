import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';

class CodeProvider with ChangeNotifier {
  CodeController? _activeController;

  CodeController? get activeController => _activeController;

  void registerController(CodeController controller) {
    _activeController = controller;
    notifyListeners();
  }

  void clearController() {
    _activeController = null;
    notifyListeners();
  }
}
