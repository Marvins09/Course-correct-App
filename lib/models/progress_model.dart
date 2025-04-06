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

  /// ✅ Convert Firestore document to ProgressModel
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
      studyTime:
          (data['studyTime'] is int)
              ? data['studyTime']
              : (data['studyTime'] ?? 0).toInt(), // ✅ Ensures integer type
      quizScores:
          (data['quizScores'] != null)
              ? Map<String, double>.from(
                data['quizScores'].map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ),
              )
              : {},
    );
  }

  /// ✅ Convert ProgressModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'completed': isCompleted,
      'completedAt':
          isCompleted
              ? FieldValue.serverTimestamp() // ✅ Sets timestamp only when completed
              : null,
      'studyTime': studyTime,
      'quizScores': quizScores,
    };
  }

  /// ✅ Convert ProgressModel to JSON (for APIs, local storage, etc.)
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'moduleId': moduleId,
      'completed': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'studyTime': studyTime,
      'quizScores': quizScores,
    };
  }

  /// ✅ copyWith method for updating properties
  ProgressModel copyWith({
    String? courseId,
    String? moduleId,
    bool? isCompleted,
    DateTime? completedAt,
    int? studyTime,
    Map<String, double>? quizScores,
  }) {
    return ProgressModel(
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      studyTime: studyTime ?? this.studyTime,
      quizScores: quizScores ?? this.quizScores,
    );
  }
}
