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

      QuerySnapshot progressSnapshot = await _firestore
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
        debugPrint("\u274c Error fetching user progress: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load progress!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Details"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('courses').doc(widget.courseId).snapshots(),
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  courseData['title'] ?? "Untitled Course",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Modules",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('courses')
                      .doc(widget.courseId)
                      .collection('modules')
                      .snapshots(),
                  builder: (context, moduleSnapshot) {
                    if (moduleSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!moduleSnapshot.hasData || moduleSnapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[500], size: 48),
                            const SizedBox(height: 10),
                            const Text("No modules available."),
                          ],
                        ),
                      );
                    }

                    var modules = moduleSnapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        var module = modules[index];
                        String moduleTitle = module['title'] ?? "No Title";
                        String moduleId = module.id;
                        String moduleDescription = module['description'] ?? "No Description";
                        bool isCompleted = completedModules[moduleId] ?? false;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              moduleTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(moduleDescription),
                            ),
                            leading: Icon(
                              isCompleted ? Icons.check_circle : Icons.lock_open,
                              color: isCompleted ? Colors.green : Colors.grey,
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ModuleContentScreen(
                                          courseId: widget.courseId,
                                          moduleId: moduleId,
                                          moduleTitle: moduleTitle,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  child: const Text("View"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizScreen(
                                          courseId: widget.courseId,
                                          moduleId: moduleId,
                                          moduleTitle: moduleTitle
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: const Text("Quiz"),
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
