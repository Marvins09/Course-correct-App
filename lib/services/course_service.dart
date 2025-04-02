import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Fetch all available courses
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('courses')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching courses: $e");
      return [];
    }
  }

  /// ✅ Fetch only courses that the user is enrolled in
  Future<List<Map<String, dynamic>>> getEnrolledCourses(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists ||
          !userDoc.data().toString().contains('enrolledCourses')) {
        return [];
      }

      List<String> enrolledCourseIds = List<String>.from(
        userDoc['enrolledCourses'] ?? [],
      );

      if (enrolledCourseIds.isEmpty) return [];

      QuerySnapshot enrolledCoursesSnapshot =
          await _firestore
              .collection('courses')
              .where(FieldPath.documentId, whereIn: enrolledCourseIds)
              .get();

      return enrolledCoursesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching enrolled courses: $e");
      return [];
    }
  }

  /// ✅ Fetch recommended courses (Excludes enrolled ones)
  Future<List<Map<String, dynamic>>> getRecommendedCourses(
    List<String> enrolledCourseIds,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('courses').get();

      return snapshot.docs
          .where((doc) => !enrolledCourseIds.contains(doc.id))
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching recommended courses: $e");
      return [];
    }
  }

  /// ✅ Enroll user in a new course (Prevents duplicate enrollments)
  Future<void> enrollUserInCourse(String userId, String courseId) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      List<String> enrolledCourses = List<String>.from(
        userDoc['enrolledCourses'] ?? [],
      );

      if (enrolledCourses.contains(courseId)) {
        debugPrint("⚠️ User is already enrolled in course: $courseId");
        return;
      }

      await userRef.update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });

      debugPrint("✅ User $userId enrolled in course $courseId");
    } catch (e) {
      debugPrint("❌ Error enrolling user: $e");
    }
  }

  /// ✅ Check if a user has completed a course
  Future<bool> isCourseCompleted(String userId, String courseId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      List<String> completedCourses = List<String>.from(
        userDoc['completedCourses'] ?? [],
      );
      return completedCourses.contains(courseId);
    } catch (e) {
      debugPrint("❌ Error checking course completion: $e");
      return false;
    }
  }

  /// ✅ Mark a course as completed when all modules are done
  Future<void> updateCourseCompletionStatus(
    String userId,
    String courseId,
  ) async {
    try {
      QuerySnapshot modulesSnapshot =
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .get();

      QuerySnapshot completedModulesSnapshot =
          await _firestore
              .collection('user_progress')
              .doc(userId)
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .where('completed', isEqualTo: true)
              .get();

      if (modulesSnapshot.docs.length == completedModulesSnapshot.docs.length) {
        await _firestore.collection('users').doc(userId).update({
          'completedCourses': FieldValue.arrayUnion([courseId]),
        });

        debugPrint("✅ Course $courseId marked as completed for user $userId");
      }
    } catch (e) {
      debugPrint("❌ Error updating course completion status: $e");
    }
  }
}
