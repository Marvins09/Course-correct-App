import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Fetch all modules for a course (Ordered by `module_number`)
  Future<List<Map<String, dynamic>>> getModules(String courseId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .orderBy(
                "module_number",
                descending: false,
              ) // ✅ Ensures correct order
              .get();

      return querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "title": doc["title"] ?? "Untitled",
          "description": doc["description"] ?? "No description",
          "module_number":
              doc["module_number"] ?? 0, // ✅ Ensure module number exists
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching modules: $e");
      return [];
    }
  }

  /// ✅ Fetch a single module’s details
  Future<Map<String, dynamic>?> getModuleDetails(
    String courseId,
    String moduleId,
  ) async {
    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .get();

      if (!doc.exists) return null;

      return {
        "id": doc.id,
        "title": doc["title"] ?? "Untitled",
        "description": doc["description"] ?? "No description",
        "module_number": doc["module_number"] ?? 0,
      };
    } catch (e) {
      debugPrint("❌ Error fetching module details: $e");
      return null;
    }
  }

  /// ✅ **Check if a module exists**
  Future<bool> doesModuleExist(String courseId, String moduleId) async {
    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .get();

      return doc.exists;
    } catch (e) {
      debugPrint("❌ Error checking module existence: $e");
      return false;
    }
  }
}
