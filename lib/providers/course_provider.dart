import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CourseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _enrolledCourses = {}; // Track enrolled courses
  final Map<String, double> _courseProgress = {}; // Track course progress %

  bool isEnrolled(String courseId) {
    return _enrolledCourses[courseId] ?? false;
  }

  double getCourseProgress(String courseId) {
    return _courseProgress[courseId] ?? 0.0; // Default to 0% progress
  }

  Future<void> enrollInCourse(String userId, String courseId) async {
    try {
      await _firestore.collection('user_progress').doc(userId).set({
        'courses': {
          courseId: {
            'modules': {}, // No modules completed yet
          },
        },
        'completedModules': [],
        'totalPoints': 0,
      }, SetOptions(merge: true));

      _enrolledCourses[courseId] = true;
      _courseProgress[courseId] = 0.0;
      notifyListeners(); // Notify UI to update
    } catch (e) {
      debugPrint("❌ Error enrolling in course: $e");
    }
  }

  Future<void> fetchUserCourses(String userId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('user_progress').doc(userId).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('courses')) {
          _enrolledCourses.clear();
          _courseProgress.clear();

          (data['courses'] as Map<String, dynamic>).forEach((courseId, courseData) {
            _enrolledCourses[courseId] = true;

            if (courseData['modules'] is Map) {
              final modules = courseData['modules'] as Map<String, dynamic>;
              final completedCount = modules.values
                  .where((m) => m['completed'] == true)
                  .length;
              final totalModules = modules.length;
              _courseProgress[courseId] = totalModules > 0
                  ? (completedCount / totalModules)
                  : 0.0;
            } else {
              _courseProgress[courseId] = 0.0;
            }
          });

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching enrolled courses: $e");
    }
  }
}
