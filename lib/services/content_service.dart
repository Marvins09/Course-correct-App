import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Fetch all contents for a given module
  Future<List<Map<String, dynamic>>> getContents(
    String courseId,
    String moduleId,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('contents')
              .orderBy('createdAt', descending: false)
              .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching contents: $e");
      return [];
    }
  }

  /// ✅ Fetch a single content item
  Future<Map<String, dynamic>?> getContent(
    String courseId,
    String moduleId,
    String contentId,
  ) async {
    try {
      DocumentSnapshot contentDoc =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('contents')
              .doc(contentId)
              .get();

      return contentDoc.exists
          ? contentDoc.data() as Map<String, dynamic>
          : null;
    } catch (e) {
      debugPrint("❌ Error fetching content: $e");
      return null;
    }
  }

  /// ✅ Add new content to a module
  Future<void> addContent(
    String courseId,
    String moduleId,
    Map<String, dynamic> contentData,
  ) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('contents')
          .add({...contentData, 'createdAt': FieldValue.serverTimestamp()});
      debugPrint("✅ Content added successfully!");
    } catch (e) {
      debugPrint("❌ Error adding content: $e");
    }
  }

  /// ✅ Update an existing content item
  Future<void> updateContent(
    String courseId,
    String moduleId,
    String contentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('contents')
          .doc(contentId)
          .update(updates);
      debugPrint("✅ Content updated successfully!");
    } catch (e) {
      debugPrint("❌ Error updating content: $e");
    }
  }

  /// ✅ Delete a content item
  Future<void> deleteContent(
    String courseId,
    String moduleId,
    String contentId,
  ) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('contents')
          .doc(contentId)
          .delete();
      debugPrint("✅ Content deleted successfully!");
    } catch (e) {
      debugPrint("❌ Error deleting content: $e");
    }
  }
}
