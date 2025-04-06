import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'module_content_screen.dart';
import 'quiz_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  CourseDetailScreenState createState() => CourseDetailScreenState();
}

class CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, bool> completedModules = {};

  @override
  void initState() {
    super.initState();
    _fetchUserProgress();
  }

  Future<void> _fetchUserProgress() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot progressSnapshot =
          await _firestore
              .collection('user_progress')
              .where("userId", isEqualTo: user.uid)
              .where("courseId", isEqualTo: widget.courseId)
              .where("completed", isEqualTo: true)
              .get();

      if (!mounted) return;

      setState(() {
        for (var doc in progressSnapshot.docs) {
          String? moduleId = doc["moduleId"];
          if (moduleId != null) {
            completedModules[moduleId] = true;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        debugPrint("❌ Error fetching user progress: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load progress!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Course Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('courses').doc(widget.courseId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
            return const Center(child: Text("Course not found."));
          }

          var courseData = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  courseData['title'] ?? "Untitled Course",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Modules",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('courses')
                          .doc(widget.courseId)
                          .collection('modules')
                          .snapshots(),
                  builder: (context, moduleSnapshot) {
                    if (moduleSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!moduleSnapshot.hasData ||
                        moduleSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No modules available."));
                    }

                    var modules = moduleSnapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        var module = modules[index];
                        String moduleTitle = module['title'] ?? "No Title";
                        String moduleId = module.id;

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(moduleTitle),
                            subtitle: Text(
                              module['description'] ?? "No Description",
                            ),
                            trailing: Wrap(
                              spacing: 12,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ModuleContentScreen(
                                              courseId: widget.courseId,
                                              moduleId: moduleId,
                                              moduleTitle: moduleTitle,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text("View"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => QuizScreen(
                                              courseId: widget.courseId,
                                              moduleId: moduleId,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: const Text("Start Quiz"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
