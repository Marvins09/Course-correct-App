import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int attempts;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.attempts,
    required this.createdAt,
  });

  /// ✅ Convert Firestore document to QuizModel
  factory QuizModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return QuizModel(
      id: docId,
      question: data['question'] ?? 'No question available',
      options:
          (data['options'] != null) ? List<String>.from(data['options']) : [],
      correctAnswer: data['correct_answer'] ?? '',
      attempts: data['attempts'] ?? 0,
      createdAt:
          (data['createdAt'] != null)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(), // ✅ Handles missing timestamps safely
    );
  }

  /// ✅ Convert QuizModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'attempts': attempts,
      'createdAt': Timestamp.fromDate(createdAt), // ✅ Firestore-safe format
    };
  }

  /// ✅ Convert QuizModel to JSON (for API or local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'attempts': attempts,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// ✅ copyWith method for updating properties
  QuizModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? correctAnswer,
    int? attempts,
    DateTime? createdAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
