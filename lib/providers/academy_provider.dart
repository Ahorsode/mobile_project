import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson.dart';

class AcademyProvider with ChangeNotifier {
  List<Tier> _tiers = [];
  Map<String, double> _lessonScores = {};
  Set<String> _completedLessons = {};
  bool _isLoading = true;

  List<Tier> get tiers => _tiers;
  bool get isLoading => _isLoading;

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
      final String response = await rootBundle.loadString('assets/lessons.json');
      final data = await json.decode(response);
      _tiers = (data as List).map((t) => Tier.fromJson(t)).toList();
    } catch (e) {
      debugPrint("Error loading lessons: $e");
    }
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _completedLessons = (prefs.getStringList('completed_lessons') ?? []).toSet();
    
    final scoresJson = prefs.getString('lesson_scores') ?? '{}';
    final Map<String, dynamic> decodedScores = json.decode(scoresJson);
    _lessonScores = decodedScores.map((key, value) => MapEntry(key, value.toDouble()));
  }

  bool isLessonCompleted(String lessonId) => _completedLessons.contains(lessonId);

  double getLessonScore(String lessonId) => _lessonScores[lessonId] ?? 0.0;

  Future<void> completeLesson(String lessonId, double score) async {
    _completedLessons.add(lessonId);
    _lessonScores[lessonId] = score;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_lessons', _completedLessons.toList());
    await prefs.setString('lesson_scores', json.encode(_lessonScores));
    
    notifyListeners();
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
    if (tierIndex == 0) return true; // First tier always unlocked
    
    // Previous tier must be 100% complete
    double prevTierProgress = getTierProgress(tierIndex - 1);
    return prevTierProgress >= 1.0;
  }
}
