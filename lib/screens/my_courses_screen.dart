import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  MyCoursesScreenState createState() => MyCoursesScreenState();
}

class MyCoursesScreenState extends State<MyCoursesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> enrolledCourses = [];
  List<DocumentSnapshot> recommendedCourses = [];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      List<dynamic> enrolledCourseIds = userDoc['enrolledCourses'] ?? [];

      QuerySnapshot allCoursesQuery =
          await _firestore.collection('courses').get();

      setState(() {
        enrolledCourses =
            allCoursesQuery.docs
                .where((doc) => enrolledCourseIds.contains(doc.id))
                .toList();

        recommendedCourses = allCoursesQuery.docs; // Load all courses
      });
    }
  }

  Future<void> _enrollInCourse(String courseId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });
      _fetchCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Courses")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enrolled Courses",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            enrolledCourses.isEmpty
                ? const Text("You are not enrolled in any courses yet.")
                : Column(
                  children:
                      enrolledCourses.map((course) {
                        return Card(
                          child: ListTile(
                            title: Text(course['title'] ?? 'No Title'),
                            subtitle: Text(
                              course['description'] ?? 'No Description',
                            ),
                          ),
                        );
                      }).toList(),
                ),
            const SizedBox(height: 20),
            const Text(
              "All Courses (Recommended)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            recommendedCourses.isEmpty
                ? const Text("No courses available.")
                : Column(
                  children:
                      recommendedCourses.map((course) {
                        return Card(
                          child: ListTile(
                            title: Text(course['title'] ?? 'No Title'),
                            subtitle: Text(
                              course['description'] ?? 'No Description',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _enrollInCourse(course.id),
                              child: const Text("Enroll"),
                            ),
                          ),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }
}
