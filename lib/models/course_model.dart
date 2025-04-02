class CourseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int totalModules;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.totalModules,
  });

  /// Convert Firestore document to CourseModel
  factory CourseModel.fromMap(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      totalModules: data['totalModules'] ?? 0,
    );
  }

  /// Convert CourseModel to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'totalModules': totalModules,
    };
  }
}
