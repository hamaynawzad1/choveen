// lib/core/services/backend_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../models/project_model.dart';
import '../../models/suggestion_model.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  // Local storage keys
  static const String _usersKey = 'choveen_users';
  static const String _projectsKey = 'choveen_projects';
  static const String _currentUserKey = 'choveen_current_user';
  static const String _deletedProjectsKey = 'choveen_deleted_projects';

  // ✅ User Management
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String name,
    required List<String> skills,
    String? profileImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all users
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(json.decode(usersJson));
      
      // Update specific user
      if (users.containsKey(userId)) {
        users[userId]['name'] = name;
        users[userId]['skills'] = skills;
        users[userId]['profileImage'] = profileImage;
        users[userId]['updatedAt'] = DateTime.now().toIso8601String();
        
        // Save back
        await prefs.setString(_usersKey, json.encode(users));
        
        // Update current user if it's the same
        final currentUserJson = prefs.getString(_currentUserKey);
        if (currentUserJson != null) {
          final currentUser = json.decode(currentUserJson);
          if (currentUser['id'] == userId) {
            currentUser['name'] = name;
            currentUser['skills'] = skills;
            currentUser['profileImage'] = profileImage;
            await prefs.setString(_currentUserKey, json.encode(currentUser));
          }
        }
        
        return {'success': true, 'user': users[userId]};
      }
      
      return {'success': false, 'message': 'User not found'};
    } catch (e) {
      print('Backend update profile error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ Get user-specific projects
  Future<List<Project>> getUserProjects(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all projects
      final projectsJson = prefs.getString(_projectsKey) ?? '[]';
      final allProjects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      // Get deleted projects
      final deletedJson = prefs.getString(_deletedProjectsKey) ?? '[]';
      final deletedIds = List<String>.from(json.decode(deletedJson));
      
      // Filter user projects and exclude deleted
      final userProjects = allProjects.where((p) => 
        (p['owner_id'] == userId || 
         (p['team_members'] as List?)?.contains(userId) == true) &&
        !deletedIds.contains(p['id'])
      ).toList();
      
      return userProjects.map((p) => Project.fromJson(p)).toList();
    } catch (e) {
      print('Get user projects error: $e');
      return [];
    }
  }

  // ✅ Create project
  Future<Project?> createProject({
    required String title,
    required String description,
    required List<String> requiredSkills,
    required String ownerId,
    int teamSize = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing projects
      final projectsJson = prefs.getString(_projectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      // Create new project
      final newProject = {
        'id': 'proj_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'description': description,
        'required_skills': requiredSkills,
        'owner_id': ownerId,
        'team_members': [ownerId],
        'status': 'active',
        'team_size': teamSize,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      projects.add(newProject);
      await prefs.setString(_projectsKey, json.encode(projects));
      
      return Project.fromJson(newProject);
    } catch (e) {
      print('Create project error: $e');
      return null;
    }
  }

  // ✅ Delete project permanently
  Future<bool> deleteProject(String projectId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get projects
      final projectsJson = prefs.getString(_projectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      // Check ownership
      final projectIndex = projects.indexWhere((p) => p['id'] == projectId);
      if (projectIndex != -1 && projects[projectIndex]['owner_id'] == userId) {
        // Remove project
        projects.removeAt(projectIndex);
        await prefs.setString(_projectsKey, json.encode(projects));
        
        // Add to deleted list
        final deletedJson = prefs.getString(_deletedProjectsKey) ?? '[]';
        final deletedIds = List<String>.from(json.decode(deletedJson));
        deletedIds.add(projectId);
        await prefs.setString(_deletedProjectsKey, json.encode(deletedIds));
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Delete project error: $e');
      return false;
    }
  }

  // ✅ Get team-based suggestions
  Future<List<Suggestion>> getTeamSuggestions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user
      final currentUserJson = prefs.getString(_currentUserKey);
      if (currentUserJson == null) return [];
      
      final currentUser = json.decode(currentUserJson);
      final userSkills = List<String>.from(currentUser['skills'] ?? []);
      
      // Get all users
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final allUsers = Map<String, dynamic>.from(json.decode(usersJson));
      
      // Team-based project ideas
      final teamProjects = [
        {
          'title': 'Creative Agency Team',
          'description': 'Form a full-service creative agency with designers, developers, and marketers',
          'required_skills': ['Graphic Design', 'Web Development', 'Marketing', 'Content Creation'],
          'team_size': 4,
          'type': 'agency'
        },
        {
          'title': 'E-Learning Platform Team',
          'description': 'Build an educational platform with instructors, developers, and content creators',
          'required_skills': ['Teaching', 'Programming', 'Video Editing', 'UI/UX Design'],
          'team_size': 5,
          'type': 'education'
        },
        {
          'title': 'Mobile App Startup',
          'description': 'Create innovative mobile applications with a diverse tech team',
          'required_skills': ['Flutter', 'Backend Development', 'UI Design', 'Project Management'],
          'team_size': 4,
          'type': 'startup'
        },
        {
          'title': 'Digital Marketing Agency',
          'description': 'Provide comprehensive digital marketing services to businesses',
          'required_skills': ['SEO', 'Social Media', 'Content Writing', 'Analytics'],
          'team_size': 3,
          'type': 'marketing'
        },
        {
          'title': 'Game Development Studio',
          'description': 'Create engaging games with artists, programmers, and designers',
          'required_skills': ['Game Design', 'Unity/Unreal', '3D Modeling', 'Sound Design'],
          'team_size': 6,
          'type': 'gaming'
        }
      ];

      // Generate suggestions based on user skills
      final suggestions = <Suggestion>[];
      
      for (final project in teamProjects) {
        // Check skill match
          final requiredSkills = List<String>.from(project['required_skills'] as List? ?? []);
          final matchingSkills = userSkills.where((skill) => 
          requiredSkills.any((req) => 
            req.toLowerCase().contains(skill.toLowerCase()) ||
            skill.toLowerCase().contains(req.toLowerCase())
          )
        ).toList();
        
        if (matchingSkills.isNotEmpty) {
          // Find potential team members
          final potentialMembers = <String>[];
          allUsers.forEach((uid, userData) {
            if (uid != userId) {
              final otherSkills = List<String>.from(userData['skills'] ?? []);
              final hasComplementarySkills = requiredSkills.any((req) =>
                otherSkills.any((skill) => 
                  skill.toLowerCase().contains(req.toLowerCase()) ||
                  req.toLowerCase().contains(skill.toLowerCase())
                )
              );
              if (hasComplementarySkills) {
                potentialMembers.add(userData['name'] ?? 'User');
              }
            }
          });
          
          final matchScore = matchingSkills.length / requiredSkills.length;
          
          suggestions.add(Suggestion.fromJson({
            'id': 'sugg_${project['type']}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'team_project',
            'project': {
              'id': 'team_${project['type']}_${DateTime.now().millisecondsSinceEpoch}',
              'title': project['title'],
              'description': '${project['description']}. You have ${matchingSkills.length} matching skills. '
                           '${potentialMembers.isNotEmpty ? "Potential team members: ${potentialMembers.take(3).join(", ")}" : ""}',
              'required_skills': requiredSkills,
              'team_size': project['team_size'],
              'team_members': [],
            },
            'description': 'Perfect for building a ${project['team_size']}-person team',
            'match_score': matchScore,
            'created_at': DateTime.now().toIso8601String(),
          }));
        }
      }
      
      // Sort by match score
      suggestions.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      
      return suggestions.take(5).toList();
    } catch (e) {
      print('Get team suggestions error: $e');
      return [];
    }
  }

  // ✅ Initialize demo data
  Future<void> initializeDemoData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if already initialized
      if (prefs.containsKey(_usersKey)) return;
      
      // Demo users with diverse skills
      final demoUsers = {
        'user_photographer': {
          'id': 'user_photographer',
          'name': 'Sarah Photo',
          'email': 'sarah@photo.com',
          'skills': ['Photography', 'Photo Editing', 'Lighting'],
          'created_at': DateTime.now().toIso8601String(),
        },
        'user_designer': {
          'id': 'user_designer',
          'name': 'Ahmed Design',
          'email': 'ahmed@design.com',
          'skills': ['Graphic Design', 'UI/UX', 'Branding'],
          'created_at': DateTime.now().toIso8601String(),
        },
        'user_developer': {
          'id': 'user_developer',
          'name': 'Karwan Dev',
          'email': 'karwan@dev.com',
          'skills': ['Flutter', 'Python', 'Backend Development'],
          'created_at': DateTime.now().toIso8601String(),
        },
        'user_editor': {
          'id': 'user_editor',
          'name': 'Layla Edit',
          'email': 'layla@edit.com',
          'skills': ['Video Editing', 'Motion Graphics', 'Color Grading'],
          'created_at': DateTime.now().toIso8601String(),
        }
      };
      
      await prefs.setString(_usersKey, json.encode(demoUsers));
      await prefs.setString(_projectsKey, json.encode([]));
      await prefs.setString(_deletedProjectsKey, json.encode([]));
      
    } catch (e) {
      print('Initialize demo data error: $e');
    }
  }
}