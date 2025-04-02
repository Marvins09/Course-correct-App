import 'dart:math'; // ✅ Import for shuffling
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ Optimized image loading

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "Guest"; // Default name if not found
  List<QueryDocumentSnapshot> courses = []; // ✅ Store courses

  @override
  void initState() {
    super.initState();
    _getUserName();
    _fetchCourses();
  }

  /// ✅ Fetch User Name
  Future<void> _getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          userName = userDoc['userName'] ?? "Guest";
        });
      }
    }
  }

  /// ✅ Fetch Courses from Firestore (Efficient Loading)
  Future<void> _fetchCourses() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('courses')
              .orderBy('title') // ✅ Ensure consistent data fetching
              .limit(20) // ✅ Fetch a limited number of courses for performance
              .get();

      if (mounted) {
        setState(() {
          courses = snapshot.docs;
          _shuffleCourses(); // ✅ Shuffle courses after fetching
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching courses: $e");
    }
  }

  /// ✅ Shuffle Courses Randomly
  void _shuffleCourses() {
    courses.shuffle(Random());
    setState(() {}); // Refresh UI after shuffling
  }

  /// ✅ Enroll User in a Course
  Future<void> _enrollInCourse(String courseId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enrolled Successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Correct"),
        backgroundColor: Colors.teal[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle), // ✅ Shuffle Button
            onPressed: _shuffleCourses,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 70, 58),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Text(
              "Welcome, $userName",
              style: GoogleFonts.greatVibes(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fade(duration: 500.ms).slideX(begin: -0.2, end: 0),
          ),

          const SizedBox(height: 20),

          /// ✅ Featured Courses Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              "Featured Courses",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ).animate().fade(duration: 500.ms).slideX(begin: -0.2, end: 0),
          ),

          /// ✅ Course GridView
          Expanded(
            child:
                courses.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 3 / 4,
                            ),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          var course = courses[index];
                          return _buildCourseCard(
                            course.id,
                            course["title"],
                            course["category"],
                            course["description"],
                            course["image"],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  /// ✅ Course Card UI
  Widget _buildCourseCard(
    String courseId,
    String title,
    String category,
    String description,
    String imageUrl,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ Optimized Image Loading
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _enrollInCourse(courseId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Enroll",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
