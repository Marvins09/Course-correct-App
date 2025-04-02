import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressModel {
  final String courseId;
  final String moduleId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int studyTime;
  final Map<String, double> quizScores; // Quiz ID -> Score

  ProgressModel({
    required this.courseId,
    required this.moduleId,
    required this.isCompleted,
    this.completedAt,
    required this.studyTime,
    required this.quizScores,
  });

  // Convert Firestore document to ProgressModel
  factory ProgressModel.fromFirestore(
    Map<String, dynamic> data,
    String courseId,
    String moduleId,
  ) {
    return ProgressModel(
      courseId: courseId,
      moduleId: moduleId,
      isCompleted: data['completed'] ?? false,
      completedAt:
          data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
      studyTime: data['studyTime'] ?? 0,
      quizScores: Map<String, double>.from(data['quizScores'] ?? {}),
    );
  }

  // Convert ProgressModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'completed': isCompleted,
      'completedAt': completedAt,
      'studyTime': studyTime,
      'quizScores': quizScores,
    };
  }
}
