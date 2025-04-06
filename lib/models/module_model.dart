import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  final String id;
  final String title;
  final String description;
  final int moduleNumber;
  final DateTime createdAt;

  ModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.moduleNumber,
    required this.createdAt,
  });

  /// ✅ Convert Firestore document to ModuleModel
  factory ModuleModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ModuleModel(
      id: docId,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? 'No description available',
      moduleNumber:
          (data['moduleNumber'] is int)
              ? data['moduleNumber']
              : (data['moduleNumber'] ?? 0).toInt(),
      createdAt:
          (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(), // ✅ Handles missing timestamps
    );
  }

  /// ✅ Convert ModuleModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'moduleNumber': moduleNumber,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Firestore auto-timestamp
    };
  }

  /// ✅ Convert ModuleModel to JSON (for APIs, local storage, etc.)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'moduleNumber': moduleNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// ✅ copyWith method for updating properties
  ModuleModel copyWith({
    String? id,
    String? title,
    String? description,
    int? moduleNumber,
    DateTime? createdAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      moduleNumber: moduleNumber ?? this.moduleNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
