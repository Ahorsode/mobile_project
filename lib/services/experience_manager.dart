class ExperienceManager {
  static const int xpPerLesson = 100;
  static const int perfectQuizBonus = 50;
  static const int xpPerLevel = 500;

  /// Calculates the current level based on total XP.
  static int calculateLevel(int totalXP) {
    if (totalXP < 0) return 1;
    return (totalXP / xpPerLevel).floor() + 1;
  }

  /// Calculates the XP required to reach the next level.
  static int xpToNextLevel(int currentLevel) {
    return currentLevel * xpPerLevel;
  }

  /// Calculates progress towards the next level (0.0 to 1.0).
  static double calculateLevelProgress(int totalXP) {
    int currentLevel = calculateLevel(totalXP);
    int currentLevelXP = (currentLevel - 1) * xpPerLevel;
    int nextLevelXP = currentLevel * xpPerLevel;

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
