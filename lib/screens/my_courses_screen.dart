import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'course_detail_screen.dart';
import '../services/progress_service.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  MyCoursesScreenState createState() => MyCoursesScreenState();
}

class MyCoursesScreenState extends State<MyCoursesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProgressService _progressService = ProgressService();

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view courses")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Courses"),
        backgroundColor: Colors.teal[800],
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("No user data available"));
          }

          List<dynamic> enrolledCourseIds = [];
          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('enrolledCourses')) {
            enrolledCourseIds = userData['enrolledCourses'] as List<dynamic>;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('courses').snapshots(),
            builder: (context, courseSnapshot) {
              if (courseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No courses available"));
              }

              var allCourses = courseSnapshot.data!.docs;
              var enrolledCourses = allCourses
                  .where((doc) => enrolledCourseIds.contains(doc.id))
                  .toList();
              var recommendedCourses = allCourses
                  .where((doc) => !enrolledCourseIds.contains(doc.id))
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enrolled Courses",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (enrolledCourses.isEmpty)
                      const Text("You are not enrolled in any courses yet."),
                    ...enrolledCourses.map((course) {
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _progressService.getUserCourseProgress(user.uid, course.id),
                        builder: (context, progressSnapshot) {
                          var progress = progressSnapshot.data ?? {};
                          List<dynamic> completedModules = progress['completedModules'] ?? [];
                          int totalModules = course['totalModules'] ?? 1;
                          double moduleProgress = totalModules > 0
                              ? completedModules.length / totalModules
                              : 0.0;

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.book, size: 28, color: Colors.teal),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          course['title'] ?? 'No Title',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(course['description'] ?? 'No Description'),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: moduleProgress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(moduleProgress * 100).toInt()}% completed",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CourseDetailScreen(courseId: course.id),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_forward),
                                      label: const Text("Continue"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 30),
                    const Text(
                      "Recommended Courses",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (recommendedCourses.isEmpty)
                      const Text("No recommended courses available."),
                    ...recommendedCourses.map((course) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.orange[100],
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.school, size: 28, color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course['title'] ?? 'No Title',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(course['description'] ?? 'No Description'),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await _firestore.collection('users').doc(user.uid).update({
                                    'enrolledCourses': FieldValue.arrayUnion([course.id]),
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[800],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Enroll"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
