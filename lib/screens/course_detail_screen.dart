import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Fixed deprecated methods
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
  Map<String, bool> completedModules = {}; // ✅ Track completed modules

  @override
  void initState() {
    super.initState();
    _fetchUserProgress();
  }

  Future<void> _fetchUserProgress() async {
    // ✅ Fetch completed modules from Firestore
    try {
      QuerySnapshot progressSnapshot =
          await _firestore
              .collection('user_progress')
              .where("courseId", isEqualTo: widget.courseId)
              .where("completed", isEqualTo: true)
              .get();

      setState(() {
        for (var doc in progressSnapshot.docs) {
          String? moduleId = doc["moduleId"];
          if (moduleId != null) {
            completedModules[moduleId] = true;
          }
        }
      });
    } catch (e) {
      debugPrint("❌ Error fetching user progress: $e");
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
                        bool isCompleted = completedModules[moduleId] ?? false;
                        bool isLocked =
                            index > 0 &&
                            !(completedModules[modules[index - 1].id] ?? false);

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
                                  onPressed:
                                      isLocked
                                          ? null // 🔒 Disable if previous module isn't completed
                                          : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => ModuleContentScreen(
                                                      courseId: widget.courseId,
                                                      moduleId: moduleId,
                                                      moduleTitle: moduleTitle,
                                                    ),
                                              ),
                                            );
                                          },
                                  child: Text(isLocked ? "Locked 🔒" : "View"),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      isCompleted
                                          ? () {
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
                                          }
                                          : null, // 🔒 Hide if module not completed
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
              // ✅ Resources Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Resources",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('courses')
                              .doc(widget.courseId)
                              .collection('resources')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text("No resources available.");
                        }

                        var resources = snapshot.data!.docs;
                        return Column(
                          children:
                              resources.map((resource) {
                                return ListTile(
                                  title: Text(
                                    resource['title'] ?? "Untitled Resource",
                                  ),
                                  subtitle: Text(resource['url'] ?? "No URL"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () {
                                      _openResource(resource['url']);
                                    },
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openResource(String? url) async {
    if (url == null || url.isEmpty) {
      debugPrint("❌ Invalid URL");
      return;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // ✅ Fixed deprecated `canLaunch`
      await launchUrl(uri); // ✅ Fixed deprecated `launch`
    } else {
      debugPrint("❌ Could not launch $url");
    }
  }
}
