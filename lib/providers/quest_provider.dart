import 'package:flutter/material.dart';
import '../services/database_service.dart';

class QuestProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<String> _unlockedNodeIds = [];
  String _currentActiveNodeId = 'lesson1';
  List<Map<String, dynamic>> _gameInventory = [];
  int _gems = 0;

  List<String> get unlockedNodeIds => _unlockedNodeIds;
  String get currentActiveNodeId => _currentActiveNodeId;
  List<Map<String, dynamic>> get gameInventory => _gameInventory;
  int get gems => _gems;

  Map<String, dynamic>? get equippedWeapon => 
      _gameInventory.where((i) => i['category'] == 'Weapon' && i['is_equipped'] == 1).firstOrNull;
      
  Map<String, dynamic>? get equippedShield => 
      _gameInventory.where((i) => i['category'] == 'Shield' && i['is_equipped'] == 1).firstOrNull;

  Future<void> loadQuestState(List<String> completedAcademyLessons) async {
    // 1. Sync completed lessons from Academy
    // If lesson1 is completed, lesson2 should be unlocked, and so on.
    Set<String> unlocked = {'lesson1', ...completedAcademyLessons};
    
    for (var id in completedAcademyLessons) {
      if (id.startsWith('lesson')) {
        int num = int.tryParse(id.replaceAll('lesson', '')) ?? 0;
        if (num > 0) {
          unlocked.add('lesson${num + 1}');
        }
      }
    }
    
    _unlockedNodeIds = unlocked.toList();
    
    // 2. Load inventory from SQLite
    _gameInventory = await _db.getGameInventory();
    
    // 3. Load gems
    final userProgress = await _db.getUserProgress();
    _gems = userProgress['gems'] ?? 0;
    
    notifyListeners();
  }

  void setCurrentActiveNode(String lessonId) {
    _currentActiveNodeId = lessonId;
    notifyListeners();
  }

  Future<void> earnItem({
    required String itemId,
    required String itemName,
    required String category,
    int attackPower = 0,
    int defensePower = 0,
  }) async {
    await _db.saveGameItem(
      itemId: itemId,
      itemName: itemName,
      category: category,
      attackPower: attackPower,
      defensePower: defensePower,
    );
    _gameInventory = await _db.getGameInventory();
    notifyListeners();
  }

  Future<void> equipItem(String itemId, String category) async {
    await _db.equipItem(itemId, category);
    _gameInventory = await _db.getGameInventory();
    notifyListeners();
  }

  Future<void> addGems(int amount) async {
    _gems += amount;
    await _db.updateGems(_gems);
    notifyListeners();
  }

  Future<bool> spendGems(int amount) async {
    if (_gems >= amount) {
      _gems -= amount;
      await _db.updateGems(_gems);
      notifyListeners();
      return true;
    }
    return false;
  }
}
