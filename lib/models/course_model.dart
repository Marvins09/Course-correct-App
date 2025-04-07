class CourseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int totalModules;

  // 🆕 Optional additions for enhanced features
  final int totalPoints; // Total points available in the course
  final bool isEnrolled; // Whether the user is enrolled (local state)

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.totalModules,
    this.totalPoints = 0,
    this.isEnrolled = false,
  });

  factory CourseModel.fromMap(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? 'No description available',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'] ?? '',
      totalModules: (data['totalModules'] is int)
          ? data['totalModules']
          : (data['totalModules'] ?? 0).toInt(),
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      // `isEnrolled` is a local UI-only flag, not stored in Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'totalModules': totalModules,
      'totalPoints': totalPoints,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    int? totalModules,
    int? totalPoints,
    bool? isEnrolled,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      totalModules: totalModules ?? this.totalModules,
      totalPoints: totalPoints ?? this.totalPoints,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}
