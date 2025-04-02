import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> _completedModules = {}; // ✅ Track module progress

  Map<String, bool> get completedModules => _completedModules;

  /// ✅ **Load Module Progress for a Course**
  Future<void> loadModuleProgress(String userId, String courseId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('user_progress').doc(userId).get();

      if (snapshot.exists) {
        Map<String, dynamic>? userProgress =
            snapshot.data() as Map<String, dynamic>?;

        if (userProgress?['courses']?[courseId]?['modules'] != null) {
          _completedModules = Map<String, bool>.from(
            userProgress!['courses'][courseId]['modules'],
          );
        } else {
          _completedModules = {};
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading module progress: $e');
    }
  }

  /// ✅ **Mark a Module as Completed**
  Future<void> markModuleCompleted(
    String userId,
    String courseId,
    String moduleId,
  ) async {
    try {
      _completedModules[moduleId] = true;
      notifyListeners();

      await _firestore.collection('user_progress').doc(userId).set({
        'courses.$courseId.modules.$moduleId': {
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      debugPrint("✅ Module $moduleId marked as completed for course $courseId");
    } catch (e) {
      debugPrint('❌ Error marking module as completed: $e');
    }
  }

  /// ✅ **Check if a Module is Completed**
  bool isModuleCompleted(String moduleId) {
    return _completedModules[moduleId] ?? false;
  }
}
