import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// ✅ Sign in with Email and Password
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

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc['disabled'] == true) {
        _logger.w("🚫 User account is disabled");
        return null;
      }

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

  /// ✅ Register New User and Initialize Progress Structure
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
      QuerySnapshot existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      if (existingUser.docs.isNotEmpty) {
        _logger.w("🚫 Email already registered: $email");
        return null;
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user == null) {
        _logger.e("❌ Error: UserCredential.user is null");
        return null;
      }

      String userId = user.uid;

      // ✅ Create user personal profile
      await _firestore.collection('users').doc(userId).set({
        'fullName': fullName.trim().isNotEmpty ? fullName.trim() : 'Anonymous',
        'userName': userName.trim().isNotEmpty ? userName.trim() : 'Guest',
        'email': email.trim(),
        'uid': userId,
        'phone': phone.trim().isNotEmpty ? phone.trim() : 'Not provided',
        'gender': gender.isNotEmpty ? gender : 'Not specified',
        'country': country.isNotEmpty ? country : 'Not specified',
        'profilePicture': '',
        'createdAt': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
        'notifications': {},
        'certificates': [],
        'disabled': false,
      });

      // ✅ Initialize user_progress document
      await _firestore.collection('user_progress').doc(userId).set({
        'completedModules': [],
        'courses': {},
        'totalPoints': 0,
      });

      _logger.i("✅ User registered successfully: $email");
      return user;
    } catch (e) {
      _logger.e("❌ Error during registration: $e");
      return null;
    }
  }

  /// ✅ Sign Out User
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userRef.get();
        if (userDoc.exists) {
          await userRef.update({'last_active': FieldValue.serverTimestamp()});
        }

        await _auth.signOut();
        _logger.i("✅ User signed out successfully");
      }
    } catch (e) {
      _logger.e("❌ Error during sign-out: $e");
    }
  }

  /// ✅ Get Current User
  User? get currentUser => _auth.currentUser;
}
