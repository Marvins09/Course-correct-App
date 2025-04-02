import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'last_active': FieldValue.serverTimestamp()},
      );

      return userCredential.user;
    } catch (e) {
      debugPrint("Error during sign-in: $e");
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(
    String fullName,
    String userName,
    String email,
    String password,
    String phone,
    String gender,
    String country,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user == null) {
        debugPrint("❌ Error: UserCredential.user is null");
        return null;
      }

      String userId = user.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
            'fullName': fullName.trim(),
            'userName': userName.trim(),
            'email': email.trim(),
            'uid': userId,
            'phone': phone.trim().isNotEmpty ? phone.trim() : 'Not provided',
            'gender': gender.isNotEmpty ? gender : 'Not specified',
            'country': country.isNotEmpty ? country : 'Not specified',
            'profile_picture': '', // Default empty profile picture
            'createdAt': FieldValue.serverTimestamp(),
            'enrolled_courses': [],
            'completed_courses': [],
            'course_progress': {}, // Map of courseID: progress
            'study_time': 0, // Total study time in minutes
            'last_active': FieldValue.serverTimestamp(),
            'notifications': {}, // Store notification preferences
            'certificates': [], // List of completed course certificates
          })
          .then((_) {
            debugPrint("✅ User data added successfully");
          })
          .catchError((error) {
            debugPrint("❌ Firestore error: $error");
          });

      return user;
    } catch (e) {
      debugPrint("Error during registration: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error during sign-out: $e");
    }
  }

  User? get currentUser => _auth.currentUser;
}
