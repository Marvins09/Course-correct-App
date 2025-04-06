import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { pdf, docx, txt, image, unknown }

class ContentModel {
  final String id;
  final String title;
  final String contentUrl;
  final String? videoUrl; // 👈 Added videoUrl field
  final ContentType type;
  final DateTime date;

  ContentModel({
    required this.id,
    required this.title,
    required this.contentUrl,
    required this.type,
    required this.date,
    this.videoUrl,
  });

  // Factory method to create ContentModel from Firestore data
  factory ContentModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ContentModel(
      id: docId,
      title: data['title'] ?? 'Untitled',
      contentUrl: data['contentUrl'] ?? '',
      videoUrl: data['videoUrl'], // 👈 Fetch from Firestore
      type: _parseContentType(data['type'] ?? 'unknown'),
      date: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert ContentType from Firestore String
  static ContentType _parseContentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return ContentType.pdf;
      case 'docx':
        return ContentType.docx;
      case 'txt':
        return ContentType.txt;
      case 'image':
        return ContentType.image;
      default:
        return ContentType.unknown;
    }
  }
}
