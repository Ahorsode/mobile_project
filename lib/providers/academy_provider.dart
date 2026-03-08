import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/experience_manager.dart';

class AcademyProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Tier> _tiers = [];
  Map<String, double> _lessonScores = {};
  Set<String> _completedLessons = {};
  int _totalXP = 0;
  int _currentLevel = 1;
  List<String> _inventory = [];
  bool _isLoading = true;

  List<Tier> get tiers => _tiers;
  bool get isLoading => _isLoading;
  int get totalXP => _totalXP;
  int get currentLevel => _currentLevel;
  List<String> get inventory => _inventory;

  AcademyProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadLessons();
    await loadProgress();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLessons() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/lessons.json',
      );
      final data = await json.decode(response);
      _tiers = (data as List).map((t) => Tier.fromJson(t)).toList();
    } catch (e) {
      debugPrint("Error loading lessons: $e");
    }
  }

  Future<void> loadProgress() async {
    // Load User Progress (XP, Level)
    final userProgress = await _dbService.getUserProgress();
    _totalXP = userProgress['total_xp'] ?? 0;
    _currentLevel = userProgress['current_level'] ?? 1;

    // Load Lesson Status
    final lessonStatuses = await _dbService.getAllLessonStatus();
    _completedLessons.clear();
    _lessonScores.clear();
    for (var status in lessonStatuses) {
      String id = status['lesson_id'];
      if (status['is_completed'] == 1) {
        _completedLessons.add(id);
      }
      _lessonScores[id] = status['quiz_score'] ?? 0.0;
    }

    // Load Inventory
    final inventoryItems = await _dbService.getInventory();
    _inventory = inventoryItems
        .map((item) => item['item_id'] as String)
        .toList();
  }

  bool isLessonCompleted(String lessonId) =>
      _completedLessons.contains(lessonId);

  double getLessonScore(String lessonId) => _lessonScores[lessonId] ?? 0.0;

  Future<void> completeLesson(String lessonId, double score) async {
    bool alreadyCompleted = _completedLessons.contains(lessonId);

    _completedLessons.add(lessonId);
    _lessonScores[lessonId] = score;

    // Calculate XP Reward
    int xpGained = 0;
    if (!alreadyCompleted) {
      xpGained += ExperienceManager.xpPerLesson;
    }

    if (score >= 1.0) {
      // Bonus for perfect quiz (only once per lesson for simplicity, or every time?)
      // Requirement says "Every perfect quiz grants an extra 50 XP".
      // Let's assume it's per completion attempt that is perfect.
      xpGained += ExperienceManager.perfectQuizBonus;
    }

    if (xpGained > 0) {
      _totalXP += xpGained;
      int newLevel = ExperienceManager.calculateLevel(_totalXP);
      if (newLevel > _currentLevel) {
        _currentLevel = newLevel;
        // Trigger Level Up Celebration in UI if possible, or just update state
      }
      await _dbService.updateXP(_totalXP, _currentLevel);
    }

    await _dbService.saveLessonStatus(lessonId, true, score);

    // Check for inventory unlocks (Example: Unlock Boolean Shield on Lesson 1.3)
    if (lessonId == "1.3" && !_inventory.contains("boolean_shield")) {
      await unlockItem("boolean_shield", "The Boolean Shield", "shield");
    }

    notifyListeners();
  }

  Future<void> unlockItem(
    String itemId,
    String itemName,
    String itemType,
  ) async {
    if (!_inventory.contains(itemId)) {
      await _dbService.unlockItem(itemId, itemName, itemType);
      _inventory.add(itemId);
      notifyListeners();
    }
  }

  double getTierProgress(int tierIndex) {
    if (tierIndex < 0 || tierIndex >= _tiers.length) return 0.0;
    final lessons = _tiers[tierIndex].lessons;
    if (lessons.isEmpty) return 0.0;

    int completedCount = lessons.where((l) => isLessonCompleted(l.id)).length;
    return completedCount / lessons.length;
  }

  double getTierMastery(int tierIndex) {
    if (tierIndex < 0 || tierIndex >= _tiers.length) return 0.0;
    final lessons = _tiers[tierIndex].lessons;
    if (lessons.isEmpty) return 0.0;

    double totalScore = 0.0;
    int scoredCount = 0;

    for (var lesson in lessons) {
      if (_lessonScores.containsKey(lesson.id)) {
        totalScore += _lessonScores[lesson.id]!;
        scoredCount++;
      }
    }

    return scoredCount == 0 ? 0.0 : totalScore / scoredCount;
  }

  bool isTierUnlocked(int tierIndex) {
    if (tierIndex == 0) return true;
    double prevTierProgress = getTierProgress(tierIndex - 1);
    return prevTierProgress >= 1.0;
  }
}
