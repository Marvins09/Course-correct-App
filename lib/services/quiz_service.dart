import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Fetch all quizzes for a module
  Future<List<Map<String, dynamic>>> getQuizzes(
    String courseId,
    String moduleId,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('quizzes')
              .orderBy("createdAt", descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "question": doc["question"] ?? "No question",
          "options":
              doc["options"] is List ? List<String>.from(doc["options"]) : [],
          "correct_answer": doc["correct_answer"] ?? "",
          "explanation": doc["explanation"] ?? "",
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching quizzes: $e");
      return [];
    }
  }

  /// ✅ Record quiz attempt and update user progress
  Future<void> recordQuizAttempt({
    required String userId,
    required String courseId,
    required String moduleId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final userDocRef = _firestore.collection('user_progress').doc(userId);
      final modulePath = 'courses.$courseId.modules.$moduleId';

      final passed = score >= 0.7 * totalQuestions;

      await userDocRef.set({
        '$modulePath.attempts': FieldValue.arrayUnion([
          {
            'score': score,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
        '$modulePath.score': score,
        '$modulePath.highestScore': score,
        '$modulePath.completed': passed,
        if (passed) '$modulePath.completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Quiz attempt recorded with score: $score");
    } catch (e) {
      debugPrint("❌ Error recording quiz attempt: $e");
    }
  }

  /// ❌ Deprecated: Removed old subcollection-based methods below
  /// These are no longer needed with the new user_progress structure
}
