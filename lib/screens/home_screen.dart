import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "Guest";
  List<QueryDocumentSnapshot> courses = [];

  @override
  void initState() {
    super.initState();
    _getUserName();
    _fetchCourses();
  }

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

  Future<void> _fetchCourses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('courses')
          .orderBy('title')
          .limit(20)
          .get();

      if (mounted) {
        setState(() {
          courses = snapshot.docs;
          _shuffleCourses();
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching courses: $e");
    }
  }

  void _shuffleCourses() {
    courses.shuffle(Random());
    setState(() {});
  }

  Future<void> _enrollInCourse(String courseId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Enrolled Successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        elevation: 0,
        title: const Text(
          "Course Correct",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade900.withAlpha((0.3 * 255).round()),

                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.shuffle, color: Colors.white),
                tooltip: 'Shuffle Courses',
                onPressed: _shuffleCourses,
              ),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 70, 58),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Text(
              "Welcome, $userName 👋",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ).animate().fade(duration: 400.ms).slideX(begin: -0.3, end: 0),
          ),
          const SizedBox(height: 20),

          /// ✅ Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              "Featured Courses",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ).animate().fade(duration: 400.ms).slideX(begin: -0.2, end: 0),
          ),
          const SizedBox(height: 10),

          /// ✅ Course Grid
          Expanded(
            child: courses.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: courses.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 3 / 4,
                      ),
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

  /// ✅ Reusable Course Card
  Widget _buildCourseCard(
    String courseId,
    String title,
    String category,
    String description,
    String imageUrl,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          ),
          /// ✅ Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _enrollInCourse(courseId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Enroll", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fade(duration: 500.ms),
    );
  }
}
