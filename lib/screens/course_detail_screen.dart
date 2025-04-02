import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  CourseDetailScreenState createState() => CourseDetailScreenState();
}

class CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _courseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    try {
      DocumentSnapshot courseDoc =
          await _firestore.collection('courses').doc(widget.courseId).get();
      if (courseDoc.exists) {
        if (mounted) {
          setState(() {
            _courseData = courseDoc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading course: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_courseData?['title'] ?? "Course Details"),
        backgroundColor: Colors.teal[900],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _courseData != null
              ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Banner Image
                      if (_courseData!['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _courseData!['image'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Course Title
                      Text(
                        _courseData!['title'] ?? "No Title",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Course Description
                      Text(
                        _courseData!['description'] ?? "No Description",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Section Title
                      const Text(
                        "Course Content:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Course Content List
                      _courseData!['content'] != null
                          ? Column(
                            children:
                                (_courseData!['content'] as List<dynamic>)
                                    .map(
                                      (item) => Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.book,
                                            color: Colors.teal,
                                          ),
                                          title: Text(
                                            item['title'] ?? "Untitled",
                                          ),
                                          subtitle: Text(
                                            item['description'] ?? "No details",
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          )
                          : const Text("No content available."),
                    ],
                  ),
                ),
              )
              : const Center(child: Text("Course not found.")),
    );
  }
}
