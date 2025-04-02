import 'package:cloud_firestore/cloud_firestore.dart';

class ContentModel {
  final String id;
  final String title;
  final String type;
  final String content;
  final DateTime createdAt;

  ContentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  // Convert Firestore document to ContentModel
  factory ContentModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ContentModel(
      id: docId,
      title: data['title'] ?? 'Untitled',
      type: data['type'] ?? 'text',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert ContentModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
