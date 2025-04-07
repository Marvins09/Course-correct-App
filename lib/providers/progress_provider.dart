import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? "";

  Map<String, Map<String, dynamic>> moduleProgress = {}; // moduleId -> data
  double courseProgress = 0.0;

  /// ✅ Fetch all progress for a course
  Future<void> fetchCourseProgress(String courseId) async {
    if (userId.isEmpty) return;

    try {
      DocumentSnapshot doc = await _firestore.collection('user_progress').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>?;
      final modules = data?['courses']?[courseId]?['modules'] as Map<String, dynamic>?;

      if (modules != null) {
        moduleProgress.clear();

        modules.forEach((moduleId, moduleData) {
          moduleProgress[moduleId] = Map<String, dynamic>.from(moduleData);
        });

        _calculateCourseProgress();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching course progress: $e");
    }
  }

  /// ✅ Update study time
  Future<void> updateStudyTime(String courseId, String moduleId, int seconds) async {
    if (userId.isEmpty) return;

    final existingTime = moduleProgress[moduleId]?['studyTime'] ?? 0;
    final updatedTime = existingTime + seconds;

    moduleProgress[moduleId] = {
      ...?moduleProgress[moduleId],
      'studyTime': updatedTime,
    };

    await _firestore.collection('user_progress').doc(userId).set({
      'courses.$courseId.modules.$moduleId.studyTime': updatedTime,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// ✅ Update quiz score & attempts
  Future<void> updateQuizScore(String courseId, String moduleId, double score) async {
    if (userId.isEmpty) return;

    final currentHighest = moduleProgress[moduleId]?['highestScore'] ?? 0.0;
    final attempts = List<Map<String, dynamic>>.from(
      moduleProgress[moduleId]?['attempts'] ?? [],
    );

    final newAttempt = {
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    };

    attempts.add(newAttempt);

    final highestScore = score > currentHighest ? score : currentHighest;

    moduleProgress[moduleId] = {
      ...?moduleProgress[moduleId],
      'highestScore': highestScore,
      'attempts': attempts,
    };

    await _firestore.collection('user_progress').doc(userId).set({
      'courses.$courseId.modules.$moduleId.highestScore': highestScore,
      'courses.$courseId.modules.$moduleId.attempts': attempts,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// ✅ Mark module as completed (if score >= 70)
  Future<void> markModuleComplete(String courseId, String moduleId, double score) async {
    if (userId.isEmpty) return;

    if (score >= 70) {
      moduleProgress[moduleId] = {
        ...?moduleProgress[moduleId],
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId.completed': true,
        'courses.$courseId.modules.$moduleId.completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _calculateCourseProgress();
      notifyListeners();
    }
  }

  /// ✅ Update quiz progress (score, attempts, completion)
  Future<void> updateQuizProgress(String courseId, String moduleId, int score, {int total = 100}) async {
    final percentage = (score / total) * 100;
    await updateQuizScore(courseId, moduleId, percentage);
    await markModuleComplete(courseId, moduleId, percentage);
  }

  /// ✅ Unlock the next module after completion
  Future<void> unlockNextModule(String courseId, String currentModuleId) async {
    try {
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      final courseData = courseDoc.data();
      if (courseData == null) return;

      final modules = courseData['modules'] as List<dynamic>?;

      if (modules == null || modules.isEmpty) return;

      final currentIndex = modules.indexOf(currentModuleId);
      if (currentIndex == -1 || currentIndex + 1 >= modules.length) return;

      final nextModuleId = modules[currentIndex + 1];

      final isAlreadyUnlocked = moduleProgress[nextModuleId]?['unlocked'] == true;
      if (isAlreadyUnlocked) return;

      // Unlock next module in Firestore
      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$nextModuleId.unlocked': true,
      }, SetOptions(merge: true));

      // Update locally
      moduleProgress[nextModuleId] = {
        ...?moduleProgress[nextModuleId],
        'unlocked': true,
      };

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to unlock next module: $e");
    }
  }

  /// ✅ Check if a module is completed
  bool isCompleted(String moduleId) {
    return moduleProgress[moduleId]?['completed'] == true;
  }

  /// ✅ Get study time
  int getStudyTime(String moduleId) {
    return moduleProgress[moduleId]?['studyTime'] ?? 0;
  }

  /// ✅ Get highest quiz score
  double getHighestScore(String moduleId) {
    return (moduleProgress[moduleId]?['highestScore'] ?? 0.0).toDouble();
  }

  /// ✅ Get number of attempts
  int getAttemptCount(String moduleId) {
    return (moduleProgress[moduleId]?['attempts'] as List?)?.length ?? 0;
  }

  /// ✅ Calculate course-wide progress %
  void _calculateCourseProgress() {
    final total = moduleProgress.length;
    if (total == 0) {
      courseProgress = 0;
    } else {
      final completed = moduleProgress.values.where((m) => m['completed'] == true).length;
      courseProgress = (completed / total) * 100;
    }
  }

  double getCourseProgressPercent() => courseProgress;
}
