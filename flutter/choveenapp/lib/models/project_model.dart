// lib/models/project_model.dart
class Project {
  final String id;
  final String title;
  final String description;
  final String? category; // Made nullable
  final List<String> requiredSkills;
  final String status;
  final List<String> teamMembers;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.category, // Nullable
    required this.requiredSkills,
    required this.status,
    required this.teamMembers,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'], // Can be null
      requiredSkills: json['required_skills'] != null 
          ? List<String>.from(json['required_skills']) 
          : [],
      status: json['status'] ?? 'active',
      teamMembers: json['team_members'] != null 
          ? List<String>.from(json['team_members']) 
          : [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'required_skills': requiredSkills,
      'status': status,
      'team_members': teamMembers,
      'created_at': createdAt.toIso8601String(),
    };
  }
}