import 'package:flutter/material.dart';
import '../services/user_repository.dart';

class LeaderboardProvider with ChangeNotifier {
  final UserRepository _repository = UserRepository();
  
  List<Map<String, dynamic>> _topUsers = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get topUsers => _topUsers;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _topUsers = await _repository.getLeaderboard();
    } catch (e) {
      print("Error fetching leaderboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
