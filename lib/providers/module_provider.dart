import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> _completedModules = {}; // ✅ Track module progress
  int _totalPoints = 0; // ✅ Track total points

  Map<String, bool> get completedModules => _completedModules;
  int get totalPoints => _totalPoints;

  /// ✅ **Load Module Progress for a Course**
  Future<void> loadModuleProgress(String userId, String courseId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('user_progress').doc(userId).get();

      if (snapshot.exists) {
        Map<String, dynamic>? userProgress =
            snapshot.data() as Map<String, dynamic>?;

        if (userProgress?['courses']?[courseId]?['modules'] != null) {
          final modules = userProgress!['courses'][courseId]['modules']
              as Map<String, dynamic>;

          _completedModules = {
            for (var entry in modules.entries)
              entry.key: (entry.value['completed'] ?? false) as bool
          };
        } else {
          _completedModules = {};
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading module progress: $e');
    }
  }

  /// ✅ **Mark a Module as Completed**
  Future<void> markModuleCompleted(
    String userId,
    String courseId,
    String moduleId, {
    int points = 0,
  }) async {
    try {
      _completedModules[moduleId] = true;
      notifyListeners();

      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId': {
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
          'pointsEarned': points,
        },
      }, SetOptions(merge: true));

      await calculateTotalPoints(userId);

      debugPrint("✅ Module $moduleId marked as completed for course $courseId");
    } catch (e) {
      debugPrint('❌ Error marking module as completed: $e');
    }
  }

  /// ✅ **Track study time for a module**
  Future<void> updateStudyTime(
    String userId,
    String courseId,
    String moduleId,
    int seconds,
  ) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.studyTime': FieldValue.increment(seconds),
        'courses.$courseId.modules.$moduleId.lastStudied': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error updating study time: $e');
    }
  }

  /// ✅ **Update Quiz Score & Attempts**
  Future<void> updateQuizScore(
    String userId,
    String courseId,
    String moduleId,
    int score,
  ) async {
    try {
      final now = Timestamp.now();
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.score': score,
        'courses.$courseId.modules.$moduleId.highestScore': score,
        'courses.$courseId.modules.$moduleId.attempts': FieldValue.arrayUnion([
          {'score': score, 'timestamp': now},
        ])
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error updating quiz score: $e');
    }
  }

  /// ✅ **Calculate Total Points Across All Courses & Modules**
  Future<void> calculateTotalPoints(String userId) async {
    try {
      final doc = await _firestore.collection('user_progress').doc(userId).get();
      final data = doc.data();
      int points = 0;

      final courses = data?['courses'] as Map<String, dynamic>? ?? {};
      for (var course in courses.values) {
        final modules = course['modules'] as Map<String, dynamic>? ?? {};
        for (var mod in modules.values) {
          points += (mod['pointsEarned'] ?? 0) as int;
        }
      }

      _totalPoints = points;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error calculating total points: $e");
    }
  }

  /// ✅ **Check if a Module is Completed**
  bool isModuleCompleted(String moduleId) {
    return _completedModules[moduleId] ?? false;
  }
}
