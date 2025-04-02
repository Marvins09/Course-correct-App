import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:course_correct/screens/login_screen.dart';
import 'package:course_correct/firebase_options.dart';
import 'package:course_correct/widgets/bottom_nav.dart';

import 'package:course_correct/providers/module_provider.dart';
import 'package:course_correct/providers/course_provider.dart';
import 'package:course_correct/providers/quiz_provider.dart';
import 'package:course_correct/providers/progress_provider.dart'; // ✅ Added ProgressProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ModuleProvider(),
        ), // ✅ Module State
        ChangeNotifierProvider(
          create: (_) => CourseProvider(),
        ), // ✅ Course State
        ChangeNotifierProvider(create: (_) => QuizProvider()), // ✅ Quiz State
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(),
        ), // ✅ Progress Tracking
      ],
      child: MaterialApp(
        title: 'Course Correct',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        debugShowCheckedModeBanner: false,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text("Error loading authentication!")),
              );
            }
            return snapshot.hasData ? const BottomNav() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
