import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Get user progress for a specific course
  Future<Map<String, dynamic>?> getUserCourseProgress(
    String userId,
    String courseId,
  ) async {
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

  /// ✅ Mark a module as completed
  Future<void> markModuleCompleted(
    String userId,
    String courseId,
    String moduleId,
  ) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.completed': true,
        'courses.$courseId.modules.$moduleId.completedAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("✅ Module $moduleId completed for course $courseId");
    } catch (e) {
      debugPrint("❌ Error marking module as completed: $e");
    }
  }

  /// ✅ Update study time for a module
  Future<void> updateStudyTime(
    String userId,
    String courseId,
    String moduleId,
    int seconds,
  ) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.studyTime': FieldValue.increment(
          seconds,
        ),
      }, SetOptions(merge: true));
      debugPrint("⏳ Study time updated: $seconds seconds");
    } catch (e) {
      debugPrint("❌ Error updating study time: $e");
    }
  }

  /// ✅ Fetch completed modules for a course
  Future<List<String>> getCompletedModules(
    String userId,
    String courseId,
  ) async {
    Map<String, dynamic>? progress = await getUserCourseProgress(
      userId,
      courseId,
    );
    return (progress?['modules'] as Map<String, dynamic>?)?.keys.toList() ?? [];
  }

  /// ✅ Track quiz progress
  Future<void> updateQuizProgress(
    String userId,
    String courseId,
    String quizId,
    double score,
  ) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.quizScores.$quizId': score,
        'courses.$courseId.updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("📊 Quiz $quizId updated with score: $score");
    } catch (e) {
      debugPrint("❌ Error updating quiz progress: $e");
    }
  }

  /// ✅ Reset progress for a course
  Future<void> resetUserProgress(String userId, String courseId) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId': FieldValue.delete(),
      }, SetOptions(merge: true));
      debugPrint("🗑️ Progress reset for course $courseId");
    } catch (e) {
      debugPrint("❌ Error resetting user progress: $e");
    }
  }
}
