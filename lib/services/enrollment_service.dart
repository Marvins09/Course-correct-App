import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // ✅ Import debugPrint()

class EnrollmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Enroll user in a course and initialize progress tracking
  static Future<void> enrollUser(String courseId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint("❌ Error: No user logged in.");
        return;
      }

      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await userRef.get();
      List<String> enrolledCourses = List<String>.from(
        userSnapshot['enrolledCourses'] ?? [],
      );

      if (enrolledCourses.contains(courseId)) {
        debugPrint("⚠️ User is already enrolled in course: $courseId");
        return;
      }

      // ✅ Update enrolled courses in user document
      await userRef.set({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      }, SetOptions(merge: true));

      debugPrint("✅ User enrolled in course: $courseId");

      // ✅ Fetch course modules
      QuerySnapshot moduleSnapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .get();

      for (var moduleDoc in moduleSnapshot.docs) {
        String moduleId = moduleDoc.id;

        // ✅ Create module progress entry
        DocumentReference moduleProgressRef = _firestore
            .collection('user_progress')
            .doc(userId)
            .collection('courses')
            .doc(courseId)
            .collection('modules')
            .doc(moduleId);

        await moduleProgressRef.set({
          'moduleId': moduleId,
          'completed': false,
          'studyTime': 0, // Initial study time in seconds
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("✅ Created module progress for: $moduleId");

        // ✅ Fetch quizzes for this module
        QuerySnapshot quizSnapshot =
            await _firestore
                .collection('courses')
                .doc(courseId)
                .collection('modules')
                .doc(moduleId)
                .collection('quizzes')
                .get();

        for (var quizDoc in quizSnapshot.docs) {
          String quizId = quizDoc.id;

          // ✅ Pre-create quiz progress entry
          DocumentReference quizProgressRef = moduleProgressRef
              .collection('quizzes')
              .doc(quizId);

          await quizProgressRef.set({
            'quizId': quizId,
            'quizAttempts': 0,
            'quizScore': null, // Score is initially null
            'lastAttempted': null,
          }, SetOptions(merge: true));

          debugPrint("✅ Pre-created quiz progress for: $quizId");
        }
      }

      debugPrint("🎉 Enrollment & progress setup completed successfully!");
    } catch (error) {
      debugPrint("❌ Enrollment Failed: $error");
    }
  }
}
