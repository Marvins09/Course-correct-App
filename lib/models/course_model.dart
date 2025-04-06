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
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? 'No description available',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'] ?? '',
      totalModules:
          (data['totalModules'] is int)
              ? data['totalModules']
              : (data['totalModules'] ?? 0).toInt(),
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

  /// Copy method for immutability
  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    int? totalModules,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      totalModules: totalModules ?? this.totalModules,
    );
  }
}
