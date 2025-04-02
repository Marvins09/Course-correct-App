import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // ✅ Import Logger

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(); // ✅ Logger Instance

  /// ✅ **Sign in with Email and Password**
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        _logger.e("❌ Sign-in failed: User is null");
        return null;
      }

      // ✅ Check if the user is disabled
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc['disabled'] == true) {
        _logger.w("🚫 User account is disabled");
        return null;
      }

      // ✅ Update last active timestamp
      await _firestore.collection('users').doc(user.uid).update({
        'last_active': FieldValue.serverTimestamp(),
      });

      _logger.i("✅ User signed in: ${user.email}");
      return user;
    } catch (e) {
      _logger.e("❌ Error during sign-in: $e");
      return null;
    }
  }

  /// ✅ **Register New User**
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
      // ✅ Check if email is already registered
      QuerySnapshot existingUser =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .get();

      if (existingUser.docs.isNotEmpty) {
        _logger.w("🚫 Email already registered: $email");
        return null;
      }

      // ✅ Create Firebase Authentication User
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user == null) {
        _logger.e("❌ Error: UserCredential.user is null");
        return null;
      }

      String userId = user.uid;
      await _firestore.collection('users').doc(userId).set({
        'fullName': fullName.trim().isNotEmpty ? fullName.trim() : 'Anonymous',
        'userName': userName.trim().isNotEmpty ? userName.trim() : 'Guest',
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
        'studyTime': 0, // ✅ Ensure study time is initialized correctly
        'last_active': FieldValue.serverTimestamp(),
        'notifications': {}, // Store notification preferences
        'certificates': [], // List of completed course certificates
        'disabled': false, // ✅ New: Account status tracking
      });

      _logger.i("✅ User registered successfully: $email");
      return user;
    } catch (e) {
      _logger.e("❌ Error during registration: $e");
      return null;
    }
  }

  /// ✅ **Sign Out User**
  Future<void> signOut() async {
    try {
      if (_auth.currentUser != null) {
        // ✅ Update last active timestamp before signing out
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'last_active': FieldValue.serverTimestamp()},
        );

        // ✅ Update study time before signing out
        DocumentSnapshot userDoc =
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .get();

        if (userDoc.exists && userDoc['studyTime'] != null) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update(
                {'studyTime': FieldValue.increment(5)}, // ✅ Example increment
              );
        }
      }

      await _auth.signOut();
      _logger.i("✅ User signed out successfully");
    } catch (e) {
      _logger.e("❌ Error during sign-out: $e");
    }
  }

  /// ✅ **Get Current Logged-In User**
  User? get currentUser => _auth.currentUser;
}
