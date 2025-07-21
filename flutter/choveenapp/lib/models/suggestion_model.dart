import 'project_model.dart';
import 'user_model.dart';

class Suggestion {
  final String id;
  final String type;
  final Project? project;
  final User? teamMember;
  final String description;
  final double matchScore;
  final DateTime createdAt;

  Suggestion({
    required this.id,
    required this.type,
    this.project,
    this.teamMember,
    required this.description,
    required this.matchScore,
    required this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] ?? '',
      type: json['type'] ?? 'project',
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      teamMember: json['team_member'] != null ? User.fromJson(json['team_member']) : null,
      description: json['description'] ?? '',
      matchScore: (json['match_score'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'project': project?.toJson(),
      'team_member': teamMember?.toJson(),
      'description': description,
      'match_score': matchScore,
      'created_at': createdAt.toIso8601String(),
    };
  }
}