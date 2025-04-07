import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class EnrollmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Enroll the user and initialize progress data in new structure
  static Future<void> enrollUser(String courseId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint("❌ No user logged in.");
        return;
      }

      final userRef = _firestore.collection('users').doc(userId);
      final userSnapshot = await userRef.get();

      List<String> enrolledCourses = List<String>.from(
        userSnapshot.data()?['enrolledCourses'] ?? [],
      );

      if (enrolledCourses.contains(courseId)) {
        debugPrint("⚠️ User already enrolled in $courseId");
        return;
      }

      // ✅ Update user doc: add course to enrolledCourses
      await userRef.set({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      }, SetOptions(merge: true));

      // ✅ Fetch course modules
      final moduleSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .get();

      Map<String, dynamic> moduleProgressMap = {};
      final firstModuleId = moduleSnapshot.docs.isNotEmpty ? moduleSnapshot.docs.first.id : null;

      for (var module in moduleSnapshot.docs) {
        final moduleId = module.id;

        moduleProgressMap[moduleId] = {
          'completed': false,
          'studyTime': 0,
          'unlocked': moduleId == firstModuleId,
          'highestScore': 0,
          'score': 0,
          'pointsEarned': 0,
          'attempts': [],
          'completedAt': null,
        };

        debugPrint("✅ Initialized $moduleId");
      }

      // ✅ Write user progress
      final progressRef = _firestore.collection('user_progress').doc(userId);
      await progressRef.set({
        'courses': {
          courseId: {
            'courseId': courseId,
            'modules': moduleProgressMap,
          }
        },
        'completedModules': [],
        'totalPoints': 0,
      }, SetOptions(merge: true));

      debugPrint("🎉 User enrolled & progress initialized for $courseId");
    } catch (e) {
      debugPrint("❌ Enrollment failed: $e");
    }
  }
}
