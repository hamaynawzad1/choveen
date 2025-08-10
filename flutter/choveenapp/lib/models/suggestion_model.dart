// lib/models/suggestion_model.dart
import 'project_model.dart';
import 'user_model.dart';

class Suggestion {
  final String id;
  final String type;
  final Project? project;
  final User? teamMember;
  final String description;
  final double matchScore;
  final String timeline;
  final String difficulty;
  final List<String> feature; // Changed from features to feature to match usage

  Suggestion({
    required this.id,
    required this.type,
    this.project,
    this.teamMember,
    required this.description,
    required this.matchScore,
    required this.timeline,
    required this.difficulty,
    required this.feature, // Required parameter
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] ?? '',
      type: json['type'] ?? 'project',
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      teamMember: json['team_member'] != null ? User.fromJson(json['team_member']) : null,
      description: json['description'] ?? '',
      matchScore: (json['match_score'] ?? 0.0).toDouble(),
      timeline: json['timeline'] ?? '2-4 weeks',
      difficulty: json['difficulty'] ?? 'Intermediate',
      feature: json['feature'] != null ? List<String>.from(json['feature']) : [],
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
      'timeline': timeline,
      'difficulty': difficulty,
      'feature': feature,
    };
  }
}