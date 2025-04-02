import 'package:flutter/material.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key}); // ✅ Added 'super.key'

  @override
  MyCoursesScreenState createState() => MyCoursesScreenState();
}

class MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Courses")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // ✅ Prevents overflow issues
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enrolled Courses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal, // ✅ Allows horizontal scrolling
                child: Row(
                  children: [
                    _buildCourseCard("Flutter Basics", Colors.blue),
                    _buildCourseCard("Advanced Dart", Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Recommended Courses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCourseCard("Machine Learning", Colors.orange),
                    _buildCourseCard("Data Science", Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(String title, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
      ), // ✅ Adds spacing between cards
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
