import 'package:flutter/material.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseTitle;
  final String courseDescription;

  const CourseDetailScreen({
    super.key,
    required this.courseTitle,
    required this.courseDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(courseTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(courseDescription, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
