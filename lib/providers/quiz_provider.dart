import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> get quizzes => _quizzes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get userId => _auth.currentUser?.uid ?? "";

  /// ✅ Fetch quizzes for a module
  Future<void> fetchQuizzes(String courseId, String moduleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('quizzes')
          .get();

      _quizzes = querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "question": doc["question"] ?? "No question",
          "options": doc["options"] is List
              ? List<String>.from(doc["options"])
              : [],
          "correct_answer": doc["correct_answer"] ?? "",
          "explanation": doc["explanation"] ?? "",
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching quizzes: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ Evaluate answers and return score
  double evaluateAnswers(Map<String, String> userAnswers) {
    if (_quizzes.isEmpty) return 0.0;

    int correct = 0;

    for (var quiz in _quizzes) {
      final quizId = quiz["id"];
      final userAnswer = userAnswers[quizId];
      final correctAnswer = quiz["correct_answer"];

      if (userAnswer != null && userAnswer == correctAnswer) {
        correct++;
      }
    }

    return (correct / _quizzes.length) * 100;
  }

  /// ✅ Save attempt & score to Firestore (used by ProgressProvider)
  Future<void> saveQuizResult({
    required String courseId,
    required String moduleId,
    required double score,
  }) async {
    if (userId.isEmpty) return;

    final timestamp = FieldValue.serverTimestamp();
    final modulePath = 'courses.$courseId.modules.$moduleId';

    final attemptEntry = {
      'score': score,
      'timestamp': timestamp,
    };

    try {
      await _firestore.collection('user_progress').doc(userId).set({
        '$modulePath.attempts': FieldValue.arrayUnion([attemptEntry]),
        '$modulePath.highestScore': FieldValue.increment(score), // this will be overridden later by ProgressProvider logic
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Error saving quiz result: $e");
    }
  }
}
