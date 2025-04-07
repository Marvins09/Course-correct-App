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
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return {
          "fullName": data["fullName"] ?? "Guest",
          "email": data["email"] ?? user.email,
          "profilePicture": data["profilePicture"] ?? "",
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

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      List<dynamic> enrolled = data["enrolledCourses"] ?? [];
      return List<String>.from(enrolled);
    }

    return [];
  }

  /// ✅ Fetch user's module completion progress within a course
  Future<Map<String, bool>> getUserModuleProgress(String courseId) async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    DocumentSnapshot progressDoc =
        await _firestore.collection('user_progress').doc(user.uid).get();

    if (!progressDoc.exists) return {};

    Map<String, dynamic> data =
        progressDoc.data() as Map<String, dynamic>? ?? {};

    Map<String, dynamic> courseData =
        (data['courses'] ?? {})[courseId] ?? {};
    Map<String, dynamic> modules =
        (courseData['modules'] ?? {}) as Map<String, dynamic>;

    Map<String, bool> progress = {};
    modules.forEach((moduleId, moduleData) {
      progress[moduleId] = moduleData['completed'] ?? false;
    });

    return progress;
  }

  /// ✅ Fetch user's quiz progress for a module (simplified)
  Future<List<Map<String, dynamic>>> getQuizAttempts(
      String courseId, String moduleId) async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    DocumentSnapshot progressDoc =
        await _firestore.collection('user_progress').doc(user.uid).get();

    if (!progressDoc.exists) return [];

    Map<String, dynamic> data =
        progressDoc.data() as Map<String, dynamic>? ?? {};
    var moduleData = data['courses']?[courseId]?['modules']?[moduleId];
    if (moduleData == null || moduleData['attempts'] == null) return [];

    List<dynamic> attempts = moduleData['attempts'];
    return List<Map<String, dynamic>>.from(attempts);
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
