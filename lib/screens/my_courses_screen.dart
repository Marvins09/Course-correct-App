import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'course_detail_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  MyCoursesScreenState createState() => MyCoursesScreenState();
}

class MyCoursesScreenState extends State<MyCoursesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        backgroundColor: Colors.teal[900],
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

          // ✅ FIX: Check if 'enrolledCourses' exists & is a List
          List<dynamic> enrolledCourseIds = [];
          var userData =
              userSnapshot.data!.data() as Map<String, dynamic>?; // Cast to Map

          if (userData != null && userData.containsKey('enrolledCourses')) {
            enrolledCourseIds = userData['enrolledCourses'] as List<dynamic>;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('courses').snapshots(),
            builder: (context, courseSnapshot) {
              if (courseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!courseSnapshot.hasData ||
                  courseSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No courses available"));
              }

              var allCourses = courseSnapshot.data!.docs;
              var enrolledCourses =
                  enrolledCourseIds.isEmpty
                      ? []
                      : allCourses
                          .where((doc) => enrolledCourseIds.contains(doc.id))
                          .toList();
              var recommendedCourses =
                  allCourses
                      .where((doc) => !(enrolledCourseIds.contains(doc.id)))
                      .toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enrolled Courses",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    enrolledCourses.isEmpty
                        ? const Center(
                          child: Text(
                            "You are not enrolled in any courses yet.",
                          ),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: enrolledCourses.length,
                            itemBuilder: (context, index) {
                              var course = enrolledCourses[index];
                              return Card(
                                color: Colors.blueAccent.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    course['title'] ?? 'No Title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    course['description'] ?? 'No Description',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CourseDetailScreen(
                                                courseId: course.id,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text("Continue"),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                    const SizedBox(height: 20),

                    const Text(
                      "All Courses (Recommended)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    recommendedCourses.isEmpty
                        ? const Center(
                          child: Text("No recommended courses available."),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: recommendedCourses.length,
                            itemBuilder: (context, index) {
                              var course = recommendedCourses[index];
                              return Card(
                                color: Colors.orangeAccent.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    course['title'] ?? 'No Title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    course['description'] ?? 'No Description',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () async {
                                      await _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .update({
                                            'enrolledCourses':
                                                FieldValue.arrayUnion([
                                                  course.id,
                                                ]),
                                          });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[900],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Enroll"),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
