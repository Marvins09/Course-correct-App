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

  /// ✅ Submit Quiz Attempt & Update Progress
  Future<void> submitQuizAttempt({
    required String userId,
    required String courseId,
    required String moduleId,
    required String quizId,
    required int score,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference quizProgressRef = _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('quizzes')
          .doc(quizId);

      batch.set(quizProgressRef, {
        'quizId': quizId,
        'score': score,
        'attempts': FieldValue.increment(1),
        'completed': score >= 60, // ✅ Mark as completed if score ≥ 60%
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.commit();
      debugPrint("✅ Quiz attempt recorded for $quizId with score: $score");
    } catch (e) {
      debugPrint("❌ Error submitting quiz attempt: $e");
    }
  }

  /// ✅ Fetch user quiz progress
  Future<Map<String, dynamic>?> getUserQuizProgress(
    String userId,
    String courseId,
    String moduleId,
    String quizId,
  ) async {
    try {
      DocumentSnapshot quizSnapshot =
          await _firestore
              .collection('user_progress')
              .doc(userId)
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('quizzes')
              .doc(quizId)
              .get();

      return quizSnapshot.exists
          ? quizSnapshot.data() as Map<String, dynamic>
          : null;
    } catch (e) {
      debugPrint("❌ Error fetching user quiz progress: $e");
      return null;
    }
  }

  /// ✅ Check if Quiz is Completed
  Future<bool> isQuizCompleted(
    String userId,
    String courseId,
    String moduleId,
    String quizId,
  ) async {
    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('user_progress')
              .doc(userId)
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('quizzes')
              .doc(quizId)
              .get();

      return doc.exists && (doc["completed"] == true);
    } catch (e) {
      debugPrint("❌ Error checking quiz completion: $e");
      return false;
    }
  }

  /// ✅ Delete a Quiz Attempt (if needed)
  Future<void> deleteQuizAttempt(
    String userId,
    String courseId,
    String moduleId,
    String quizId,
  ) async {
    try {
      await _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('quizzes')
          .doc(quizId)
          .delete();

      debugPrint("🗑️ Deleted quiz attempt for $quizId");
    } catch (e) {
      debugPrint("❌ Error deleting quiz attempt: $e");
    }
  }
}
