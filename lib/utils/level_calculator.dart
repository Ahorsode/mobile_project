import 'dart:math';

class LevelCalculator {
  /// Calculate level from XP based on a standard RPG curve
  /// Level = floor((XP / 100)^0.5) + 1
  static int calculateLevel(int xp) {
    if (xp < 0) return 1;
    return (sqrt(xp / 100)).floor() + 1;
  }

  /// Calculate the XP required for a specific level
  /// XP = (Level - 1)^2 * 100
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return pow(level - 1, 2).toInt() * 100;
  }

  /// Calculate the XP required for the NEXT level
  static int xpForNextLevel(int currentLevel) {
    return xpForLevel(currentLevel + 1);
  }
}
