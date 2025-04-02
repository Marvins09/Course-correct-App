import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? "";

  Map<String, bool> completedModules = {};
  Map<String, int> studyTime = {};
  Map<String, double> highestQuizScores = {};
  Map<String, int> quizAttempts = {};

  /// ✅ **Load user progress from Firestore**
  Future<void> fetchUserProgress(String courseId) async {
    if (userId.isEmpty) return;

    try {
      DocumentSnapshot progressDoc =
          await _firestore.collection('user_progress').doc(userId).get();

      if (progressDoc.exists) {
        Map<String, dynamic> data = progressDoc.data() as Map<String, dynamic>;

        completedModules = Map<String, bool>.from(
          data['completedModules'] ?? {},
        );
        studyTime = Map<String, int>.from(data['studyTime'] ?? {});
        highestQuizScores = Map<String, double>.from(
          data['highestQuizScores'] ?? {},
        );
        quizAttempts = Map<String, int>.from(data['quizAttempts'] ?? {});

        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching user progress: $e");
    }
  }

  /// ✅ **Mark a module as completed**
  Future<void> completeModule(String courseId, String moduleId) async {
    if (userId.isEmpty) return;

    if (!isModuleCompleted(courseId, moduleId)) return;

    completedModules[moduleId] = true;

    await _firestore.collection('user_progress').doc(userId).set({
      "completedModules": completedModules,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// ✅ **Update study time**
  Future<void> updateStudyTime(
    String courseId,
    String moduleId,
    int duration,
  ) async {
    if (userId.isEmpty) return;

    studyTime[moduleId] = (studyTime[moduleId] ?? 0) + duration;

    await _firestore.collection('user_progress').doc(userId).set({
      "studyTime": studyTime,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// ✅ **Update quiz attempts**
  Future<void> incrementQuizAttempts(
    String courseId,
    String moduleId,
    String quizId,
  ) async {
    if (userId.isEmpty) return;

    quizAttempts[quizId] = (quizAttempts[quizId] ?? 0) + 1;

    await _firestore.collection('user_progress').doc(userId).set({
      "quizAttempts": quizAttempts,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// ✅ **Update highest quiz score**
  Future<void> updateHighestQuizScore(
    String courseId,
    String moduleId,
    String quizId,
    double score,
  ) async {
    if (userId.isEmpty) return;

    if ((highestQuizScores[quizId] ?? 0) < score) {
      highestQuizScores[quizId] = score;

      await _firestore.collection('user_progress').doc(userId).set({
        "highestQuizScores": highestQuizScores,
      }, SetOptions(merge: true));

      notifyListeners();
    }
  }

  /// ✅ **Check if a module is completed (study time + quiz)**
  bool isModuleCompleted(String courseId, String moduleId) {
    bool hasStudyTime = (studyTime[moduleId] ?? 0) > 0;
    bool hasQuizScore = (highestQuizScores[moduleId] ?? 0) > 0;
    return hasStudyTime && hasQuizScore;
  }
}
