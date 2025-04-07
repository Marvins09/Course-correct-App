import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user progress for a specific course
  Future<Map<String, dynamic>?> getUserCourseProgress(
      String userId, String courseId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('user_progress').doc(userId).get();
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      return data?['courses']?[courseId];
    } catch (e) {
      debugPrint("❌ Error fetching user progress: $e");
      return null;
    }
  }

  /// Mark a module as completed
  Future<void> markModuleCompleted(
    String userId,
    String courseId,
    String moduleId,
    double score,
    int pointsEarned,
  ) async {
    try {
      final modulePath = 'courses.$courseId.modules.$moduleId';

      await _firestore.collection('user_progress').doc(userId).set({
        modulePath: {
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
          'score': score,
          'pointsEarned': pointsEarned,
        },
        'completedModules': FieldValue.arrayUnion([moduleId]),
        'totalPoints': FieldValue.increment(pointsEarned),
      }, SetOptions(merge: true));

      debugPrint("✅ Module $moduleId marked as completed.");
    } catch (e) {
      debugPrint("❌ Error marking module as completed: $e");
    }
  }

  /// Update study time for a module
  Future<void> updateStudyTime(
      String userId, String courseId, String moduleId, int seconds) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.studyTime':
            FieldValue.increment(seconds),
        'courses.$courseId.modules.$moduleId.lastStudied':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Error updating study time: $e");
    }
  }

  /// Track quiz attempts
  Future<void> trackQuizAttempt({
    required String userId,
    required String courseId,
    required String moduleId,
    required double score,
  }) async {
    try {
      final attemptData = {
        'score': score,
        'timestamp': Timestamp.now(),
      };

      final userRef = _firestore.collection('user_progress').doc(userId);
      final doc = await userRef.get();
      final current = doc.data()?['courses']?[courseId]?['modules']?[moduleId];
      final double highest = (current?['highestScore'] ?? 0).toDouble();

      await userRef.set({
        'courses.$courseId.modules.$moduleId.attempts':
            FieldValue.arrayUnion([attemptData]),
        'courses.$courseId.modules.$moduleId.score': score,
        if (score > highest)
          'courses.$courseId.modules.$moduleId.highestScore': score,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Error tracking quiz attempt: $e");
    }
  }

  /// Unlock the next module
  Future<void> unlockNextModule(
    String userId,
    String courseId,
    String moduleId,
  ) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.unlocked': true,
      }, SetOptions(merge: true));
      debugPrint("🔓 Unlocked $moduleId");
    } catch (e) {
      debugPrint("❌ Error unlocking module: $e");
    }
  }

  /// Auto-unlock next module in sequence
  Future<void> unlockNextModuleInSequence(
    String userId,
    String courseId,
    List<String> moduleOrder,
    String currentModuleId,
  ) async {
    final currentIndex = moduleOrder.indexOf(currentModuleId);
    if (currentIndex != -1 && currentIndex + 1 < moduleOrder.length) {
      final nextModuleId = moduleOrder[currentIndex + 1];
      await unlockNextModule(userId, courseId, nextModuleId);
      debugPrint("🔓 Unlocked $nextModuleId after completing $currentModuleId");
    }
  }

  /// Get completed modules
  Future<List<String>> getCompletedModules(
      String userId, String courseId) async {
    Map<String, dynamic>? course = await getUserCourseProgress(userId, courseId);
    final modules = course?['modules'] as Map<String, dynamic>? ?? {};
    return modules.entries
        .where((e) => e.value['completed'] == true)
        .map((e) => e.key)
        .toList();
  }

  /// Reset progress
  Future<void> resetUserProgress(String userId, String courseId) async {
    try {
      await _firestore.collection('user_progress').doc(userId).update({
        'courses.$courseId': FieldValue.delete(),
        'completedModules': [],
        'totalPoints': 0,
      });
    } catch (e) {
      debugPrint("❌ Error resetting progress: $e");
    }
  }

  /// Get full user progress
  Future<Map<String, dynamic>?> getFullUserProgress(String userId) async {
    try {
      final doc = await _firestore.collection('user_progress').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint("❌ Error fetching full progress: $e");
      return null;
    }
  }
}
