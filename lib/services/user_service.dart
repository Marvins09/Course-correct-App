import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Fetch user full name, email, and profile picture
  Future<Map<String, dynamic>> getUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return {
          "fullName": userDoc["fullName"] ?? "Guest",
          "email": userDoc["email"] ?? user.email,
          "profilePicture": userDoc["profilePicture"] ?? "",
        };
      }
    }
    return {
      "fullName": "Guest",
      "email": "Not Available",
      "profilePicture": "",
    };
  }

  /// ✅ Fetch user's enrolled courses
  Future<List<String>> getUserEnrolledCourses() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    QuerySnapshot snapshot =
        await _firestore
            .collection('user_progress')
            .doc(user.uid)
            .collection('courses')
            .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// ✅ Fetch user's module progress within a course
  Future<Map<String, bool>> getUserModuleProgress(String courseId) async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    QuerySnapshot snapshot =
        await _firestore
            .collection('user_progress')
            .doc(user.uid)
            .collection('courses')
            .doc(courseId)
            .collection('modules')
            .get();

    Map<String, bool> progress = {};
    for (var doc in snapshot.docs) {
      progress[doc.id] = doc["completed"] ?? false;
    }

    return progress;
  }

  /// ✅ Fetch user's quiz progress for a module
  Future<Map<String, dynamic>> getUserQuizProgress(
    String courseId,
    String moduleId,
  ) async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    QuerySnapshot snapshot =
        await _firestore
            .collection('user_progress')
            .doc(user.uid)
            .collection('courses')
            .doc(courseId)
            .collection('modules')
            .doc(moduleId)
            .collection('quizzes')
            .get();

    Map<String, dynamic> quizProgress = {};
    for (var doc in snapshot.docs) {
      quizProgress[doc.id] = {
        "completed": doc["completed"] ?? false,
        "score": doc["score"] ?? 0,
        "attempts": doc["attempts"] ?? 0,
      };
    }

    return quizProgress;
  }

  /// ✅ Update user profile (e.g., full name, profile picture)
  Future<void> updateUserProfile(String fullName, String profilePicture) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        "fullName": fullName,
        "profilePicture": profilePicture,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
