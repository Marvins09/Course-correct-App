import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_correct/models/content_model.dart';
import 'dart:developer' as developer;

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch content for a given course and module
  Future<List<ContentModel>> getContents(
    String courseId,
    String moduleId,
  ) async {
    try {
      developer.log(
        '📡 Fetching contents for Course: $courseId, Module: $moduleId',
        name: 'ContentService',
      );

      QuerySnapshot querySnapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules') // ✅ Corrected path
              .doc(moduleId)
              .collection('contents')
              .get();

      List<ContentModel> contents =
          querySnapshot.docs
              .map((doc) {
                try {
                  return ContentModel.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                } catch (e) {
                  developer.log(
                    '⚠️ Skipping document ${doc.id} due to error: $e',
                    name: 'ContentService',
                  );
                  return null;
                }
              })
              .where((content) => content != null)
              .cast<ContentModel>()
              .toList();

      developer.log(
        '✅ Successfully fetched ${contents.length} contents',
        name: 'ContentService',
      );

      return contents;
    } catch (e) {
      developer.log('❌ Error fetching contents: $e', name: 'ContentService');
      return [];
    }
  }
}
