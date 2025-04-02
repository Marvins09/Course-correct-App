import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Import URL Launcher

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
  List<Map<String, dynamic>> materials = [];

  @override
  void initState() {
    super.initState();
    _fetchCourseMaterials();
  }

  Future<void> _fetchCourseMaterials() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('courses')
              .doc(widget.courseId)
              .collection('modules')
              .doc(widget.moduleId)
              .collection('course_materials')
              .get();

      setState(() {
        materials =
            querySnapshot.docs.map((doc) {
              return {
                "id": doc.id,
                "file_name": doc["file_name"] ?? "Untitled",
                "type": doc["type"] ?? "Unknown",
                "url": doc["url"] ?? "",
                "uploadedAt": doc["uploadedAt"] ?? Timestamp.now(),
              };
            }).toList();
      });
    } catch (e) {
      debugPrint(
        "❌ Error fetching course materials: $e",
      ); // ✅ `debugPrint()` still works
    }
  }

  Future<void> _openMaterial(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint("❌ Could not launch $url"); // ✅ Logs error instead of crashing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.moduleTitle)), // ✅ Dynamic Title
      body:
          materials.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(materials[index]["file_name"]),
                      subtitle: Text("Type: ${materials[index]["type"]}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openMaterial(materials[index]["url"]),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
