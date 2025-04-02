import 'dart:developer'; // ✅ Import log function
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnrollmentService {
  static Future<void> enrollUser(String courseId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        log("❌ Error: No user logged in.");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]), // Store Course ID
      });

      log("✅ Enrollment Successful!");
    } catch (error) {
      log("❌ Enrollment Failed: $error");
    }
  }
}
