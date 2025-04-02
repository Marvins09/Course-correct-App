import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModuleContentScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String moduleTitle;

  const ModuleContentScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  ModuleContentScreenState createState() => ModuleContentScreenState();
}

class ModuleContentScreenState extends State<ModuleContentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> materials = [];
  bool isLoading = true;
  bool hasError = false;
  bool hasScrolledToEnd = false;
  bool isMarkedDone = false;
  late DateTime _startTime;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCourseMaterials();
    _checkIfMarkedDone();
    _startTime = DateTime.now();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        hasScrolledToEnd = true;
      });
    }
  }

  Future<void> _fetchCourseMaterials() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('courses')
              .doc(widget.courseId)
              .collection('modules')
              .doc(widget.moduleId)
              .collection('contents')
              .orderBy("createdAt", descending: true)
              .get();

      setState(() {
        materials =
            querySnapshot.docs.map((doc) {
              return {
                "id": doc.id,
                "title": doc["title"] ?? "Untitled",
                "type": doc["type"] ?? "Unknown",
                "content": doc["content"] ?? "No content available",
                "createdAt": doc["createdAt"] ?? Timestamp.now(),
              };
            }).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching course materials: $e");
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _checkIfMarkedDone() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      DocumentSnapshot userProgress =
          await _firestore.collection('user_progress').doc(userId).get();

      setState(() {
        isMarkedDone =
            (userProgress.data() as Map<String, dynamic>?)?["courses"]?[widget
                .courseId]?["modules"]?[widget.moduleId]?["completed"] ??
            false;
      });
    } catch (e) {
      debugPrint("❌ Error checking progress: $e");
    }
  }

  Future<void> markAsDone() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint("❌ User not logged in!");
      return;
    }

    try {
      await _firestore.collection('user_progress').doc(userId).set({
        "completedModules": FieldValue.arrayUnion([widget.moduleId]),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        isMarkedDone = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Module marked as done!")));
    } catch (e) {
      debugPrint("❌ Error: $e");
    }
  }

  Future<void> updateStudyTime() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final DateTime endTime = DateTime.now();
    final int studyDuration = endTime.difference(_startTime).inSeconds;

    try {
      await _firestore.collection('user_progress').doc(userId).set({
        "courses.${widget.courseId}.modules.${widget.moduleId}.studyTime":
            FieldValue.increment(studyDuration),
      }, SetOptions(merge: true));

      debugPrint("✅ Study time updated: $studyDuration seconds");
    } catch (e) {
      debugPrint("❌ Error updating study time: $e");
    }
  }

  @override
  void dispose() {
    updateStudyTime();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.moduleTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? const Center(
                  child: Text(
                    "⚠️ Failed to load materials. Try again later.",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          var material = materials[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material["title"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    material["content"],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isMarkedDone ? null : markAsDone,
                      child: Text(
                        isMarkedDone ? "✔️ Marked as Done" : "Mark as Done",
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
