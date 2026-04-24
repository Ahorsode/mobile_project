import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

class SensoryFeedbackService {
  static final SensoryFeedbackService _instance = SensoryFeedbackService._internal();
  factory SensoryFeedbackService() => _instance;
  SensoryFeedbackService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Plays a sword slash sound effect when the player attacks
  Future<void> playSlashSfx() async {
    try {
      await _audioPlayer.play(AssetSource('audio/slash.mp3'));
    } catch (e) {
      // Graceful failure: Log and continue
      print('DEBUG: [SensoryFeedbackService] playSlashSfx failed (likely missing asset): $e');
    }
  }

  /// Plays a thud sound effect when the player takes damage
  Future<void> playThudSfx() async {
    try {
      await _audioPlayer.play(AssetSource('audio/thud.mp3'));
    } catch (e) {
      // Graceful failure: Log and continue
      print('DEBUG: [SensoryFeedbackService] playThudSfx failed (likely missing asset): $e');
    }
  }

  /// Triggers a haptic vibration
  Future<void> triggerHaptic({int duration = 100, int intensity = 128}) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: duration, amplitude: intensity);
      }
    } catch (e) {
      print('DEBUG: [SensoryFeedbackService] triggerHaptic failed: $e');
    }
  }

  /// Triggers a double vibration for critical events
  Future<void> triggerSuccessHaptic() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 100, 50, 100]);
      }
    } catch (e) {
      print('DEBUG: [SensoryFeedbackService] triggerSuccessHaptic failed: $e');
    }
  }

  /// Triggers a heavy vibration
  Future<void> triggerHeavyHaptic() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 300, amplitude: 255);
      }
    } catch (e) {
      print('DEBUG: [SensoryFeedbackService] triggerHeavyHaptic failed: $e');
    }
  }
}
