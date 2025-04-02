import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:course_correct/screens/login_screen.dart';
import 'package:course_correct/firebase_options.dart';
import 'package:course_correct/widgets/bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Correct',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance.authStateChanges(), // ✅ Listen for changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // ✅ Show loading indicator
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const BottomNav(); // ✅ Navigate to home if logged in
          } else {
            return const LoginScreen(); // ✅ Stay on login if not authenticated
          }
        },
      ),
    );
  }
}
