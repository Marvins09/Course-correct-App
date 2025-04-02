import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> get quizzes => _quizzes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchQuizzes(String courseId, String moduleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('quizzes')
              .get();

      _quizzes =
          querySnapshot.docs.map((doc) {
            return {
              "id": doc.id,
              "question": doc["question"] ?? "No question",
              "options":
                  doc["options"] is List
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
}
