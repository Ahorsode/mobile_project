import 'dart:math';

class ExperienceManager {
  static const int xpPerLesson = 100;
  static const int perfectQuizBonus = 50;
  static const int xpPerLevel = 500;

  /// Calculates the current level based on total XP.
  /// Level = floor((XP / 100)^0.5) + 1
  static int calculateLevel(int totalXP) {
    if (totalXP < 0) return 1;
    return (sqrt(totalXP / 100)).floor() + 1;
  }

  /// Calculates the total XP required to reach a specific level.
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return pow(level - 1, 2).toInt() * 100;
  }

  /// Calculates the total XP required to reach the next level.
  static int xpToNextLevel(int currentLevel) {
    return xpForLevel(currentLevel + 1);
  }

  /// Calculates progress towards the next level (0.0 to 1.0).
  static double calculateLevelProgress(int totalXP) {
    int currentLevel = calculateLevel(totalXP);
    int currentLevelXP = xpForLevel(currentLevel);
    int nextLevelXP = xpForLevel(currentLevel + 1);

    if (nextLevelXP - currentLevelXP == 0) return 1.0;
    return (totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP);
  }

  /// Titles for different level ranges.
  static String getLevelTitle(int level) {
    if (level < 5) return "Data Page";
    if (level < 10) return "Code Apprentice";
    if (level < 15) return "Logic Knight";
    if (level < 20) return "Syntax Paladin";
    return "Code Wizard";
  }
}
