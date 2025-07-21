import 'user_model.dart';

class Project {
final String id;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final String ownerId;
  final List<String> teamMembers;
  final String status;
  final int teamSize; // ✅ Add this field
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.ownerId,
    required this.teamMembers,
    required this.status,
    this.teamSize = 1, // ✅ Default value
    required this.createdAt,
    required this.updatedAt,
  });

 factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      ownerId: json['owner_id'] ?? '',
      teamMembers: List<String>.from(json['team_members'] ?? []),
      status: json['status'] ?? 'active',
      teamSize: json['team_size'] ?? json['teamSize'] ?? 1, // ✅ Add this
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'required_skills': requiredSkills,
      'owner_id': ownerId,
      'team_members': teamMembers,
      'status': status,
      'team_size': teamSize, // ✅ Add this
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}