import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update User XP in Firestore
  Future<void> updateXP(String uid, int newXP, int newLevel) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'xp': newXP,
        'level': newLevel,
        'lastCompletionTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating XP: $e");
    }
  }

  // Fetch top 50 users for leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .orderBy('xp', descending: true)
          .orderBy('lastCompletionTimestamp', descending: false)
          .limit(50)
          .get();

      return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching leaderboard: $e");
      return [];
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }
}
