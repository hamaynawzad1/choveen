// lib/providers/project_provider.dart - FIXED JOIN LOGIC
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/project_model.dart';
import '../models/suggestion_model.dart';
import '../core/services/backend_service.dart';
import '../core/services/ai_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final BackendService _backendService = BackendService();
  final EnhancedAIService _aiService = EnhancedAIService();
  
  String? _currentUserId;
  
  // Initialize with user ID
  void initializeForUser(String userId) {
    _currentUserId = userId;
    fetchProjects();
    fetchSuggestions();
  }
  
  // ✅ FIXED: Fetch user-specific projects
  Future<void> fetchProjects() async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    try {
      // Try API first
      try {
        final response = await _apiService.get(ApiConstants.projects);
        final List<dynamic> data = response['data'] ?? [];
        _projects = data.map((json) => Project.fromJson(json)).toList();
      } catch (e) {
        // Fallback to local backend service
        _projects = await _backendService.getUserProjects(_currentUserId!);
      }
      
      _error = null;
      print('✅ Loaded ${_projects.length} projects for user $_currentUserId');
    } catch (e) {
      print('❌ Projects Error: $e');
      _error = e.toString();
      _projects = [];
    } finally {
      _setLoading(false);
    }
  }

  // ✅ FIXED: Fetch team-based suggestions
  Future<void> fetchSuggestions() async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    try {
      // Get team-based suggestions from backend service
      _suggestions = await _backendService.getTeamSuggestions(_currentUserId!);
      
      // If no suggestions, generate some
      if (_suggestions.isEmpty) {
        _suggestions = await _generateDefaultTeamSuggestions();
      }
      
      _error = null;
      print('✅ Loaded ${_suggestions.length} team suggestions');
    } catch (e) {
      print('❌ Suggestions Error: $e');
      _error = e.toString();
      _suggestions = await _generateDefaultTeamSuggestions();
    } finally {
      _setLoading(false);
    }
  }

  // ✅ FIXED: Delete project with backend sync
  Future<bool> deleteProject(String projectId) async {
    if (projectId.trim().isEmpty || _currentUserId == null) {
      _error = 'Invalid project ID or user';
      notifyListeners();
      return false;
    }

    try {
      // Delete from backend service
      final success = await _backendService.deleteProject(projectId, _currentUserId!);
      
      if (success) {
        // Remove from local list
        _projects.removeWhere((project) => project.id == projectId);
        _error = null;
        notifyListeners();
        print('✅ Project deleted permanently: $projectId');
        return true;
      } else {
        _error = 'You can only delete your own projects';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Delete project error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ NEW: Generate team-based suggestions
  Future<List<Suggestion>> _generateDefaultTeamSuggestions() async {
    final teamProjects = [
      {
        'title': 'Creative Media Agency',
        'description': 'Combine photography, videography, and graphic design skills to offer complete media solutions',
        'skills': ['Photography', 'Videography', 'Graphic Design', 'Video Editing'],
        'team_size': 4,
      },
      {
        'title': 'Tech Solutions Team', 
        'description': 'Build web and mobile applications with a full development team',
        'skills': ['Flutter', 'Web Development', 'UI/UX Design', 'Backend Development'],
        'team_size': 5,
      },
      {
        'title': 'Digital Marketing Collective',
        'description': 'Offer comprehensive digital marketing services with content creators and strategists',
        'skills': ['Content Writing', 'Social Media', 'SEO', 'Graphic Design'],
        'team_size': 4,
      },
    ];

    return teamProjects.map((proj) => Suggestion.fromJson({
      'id': 'sugg_${DateTime.now().millisecondsSinceEpoch}_${teamProjects.indexOf(proj)}',
      'type': 'team_project',
      'project': {
        'id': 'team_${DateTime.now().millisecondsSinceEpoch}_${teamProjects.indexOf(proj)}',
        'title': proj['title'],
        'description': proj['description'],
        'required_skills': proj['skills'],
        'team_size': proj['team_size'],
        'team_members': [],
      },
      'description': 'Build a ${proj['team_size']}-person professional team',
      'match_score': 0.85 + (teamProjects.indexOf(proj) * 0.05),
      'created_at': DateTime.now().toIso8601String(),
    })).toList();
  }

  // ✅ FIXED: Join/Create project from suggestion
  Future<bool> joinProject(String projectId, {String? projectTitle}) async {
    if (projectId.trim().isEmpty || _currentUserId == null) {
      _error = 'Invalid project or user';
      notifyListeners();
      return false;
    }

    try {
      // For team suggestions, create new project
      if (projectId.startsWith('team_')) {
        final suggestion = _suggestions.firstWhere(
          (s) => s.project?.id == projectId,
          orElse: () => _suggestions.first,
        );
        
        final newProject = await _backendService.createProject(
          title: suggestion.project?.title ?? projectTitle ?? 'Team Project',
          description: suggestion.project?.description ?? 'Team collaboration project',
          requiredSkills: suggestion.project?.requiredSkills ?? [],
          ownerId: _currentUserId!,
          teamSize: suggestion.project?.teamSize ?? 1,
        );
        
        if (newProject != null) {
          _projects.insert(0, newProject);
          notifyListeners();
          print('✅ Created team project: ${newProject.title}');
          return true;
        }
      }
      
      // Try API for regular projects
      try {
        final response = await _apiService.post(
          '${ApiConstants.projects}/$projectId/join',
          body: {'project_title': projectTitle},
        );
        
        if (response['success'] == true) {
          await fetchProjects();
          return true;
        }
      } catch (e) {
        // For demo/offline mode
        if (projectId.contains('_')) {
          await fetchProjects();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Join project error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }


  List<Project> _projects = [];
  List<Suggestion> _suggestions = [];
  Set<String> _deletedProjectIds = {};
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects.where((p) => !_deletedProjectIds.contains(p.id)).toList();
  List<Suggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Refresh suggestions with new ideas
  Future<void> refreshSuggestions() async {
    print('🔄 Starting intelligent suggestion refresh...');
    _setLoading(true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _apiService.get('${ApiConstants.projectSuggestions}?refresh=$timestamp');
      final List<dynamic> data = response['data'] ?? [];
      _suggestions = data.map((json) => Suggestion.fromJson(json)).toList();
      _error = null;
      print('✅ Refreshed ${_suggestions.length} intelligent suggestions');
    } catch (e) {
      print('❌ Refresh suggestions error: $e');
      _error = e.toString();
      
      // Generate new creative fallback suggestions
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp % 1000;
      
      final creativeProjects = [
        {
          "titles": ["Innovation Lab Platform", "Creative Solutions Hub", "Future Tech Incubator"],
          "descriptions": ["Build an experimental platform for innovative technology solutions", "Create a collaborative space for breakthrough innovation", "Develop a comprehensive innovation ecosystem"]
        },
        {
          "titles": ["Smart Productivity Suite", "Intelligent Workflow Engine", "AI-Powered Optimizer"],
          "descriptions": ["Design an intelligent system for optimal productivity", "Build smart automation for enhanced efficiency", "Create AI-driven workflow optimization"]
        },
        {
          "titles": ["Strategic Intelligence Dashboard", "Business Analytics Hub", "Decision Support Platform"],
          "descriptions": ["Develop sophisticated business intelligence tools", "Build comprehensive analytics solutions", "Create strategic decision-making platforms"]
        }
      ];
      
      _suggestions = List.generate(3, (index) {
        final projectSet = creativeProjects[index % creativeProjects.length];
        final titleIndex = (timestamp + index) % (projectSet["titles"]?.length ?? 1);
        final descIndex = (timestamp + index) % (projectSet["descriptions"]?.length ?? 1);
        final uniqueId = '$timestamp${index + 1}$randomSuffix';
        
        return Suggestion.fromJson({
          "id": "creative_$uniqueId",
          "type": "project",
          "project": {
            "id": "proj_creative_$uniqueId",
            "title": projectSet["titles"]?[titleIndex] ?? "Creative Project",
            "description": projectSet["descriptions"]?[descIndex] ?? "Innovative solution",
            "required_skills": ["Innovation", "Technology", "Collaboration"]
          },
          "description": "Intelligent suggestion tailored for your skills and interests",
          "match_score": 0.88 + (index * 0.02),
          "created_at": DateTime.now().toIso8601String(),
        });
      });
      
      print('🎨 Generated ${_suggestions.length} creative fallback suggestions');
    } finally {
      _setLoading(false);
    }
  }

  /// Search projects
  List<Project> searchProjects(String query) {
    if (query.trim().isEmpty) return projects;
    
    final queryLower = query.toLowerCase();
    return projects.where((project) =>
        project.title.toLowerCase().contains(queryLower) ||
        project.description.toLowerCase().contains(queryLower) ||
        project.requiredSkills.any((skill) => 
            skill.toLowerCase().contains(queryLower))
    ).toList();
  }

  /// Get project by ID
  Project? getProjectById(String projectId) {
    try {
      return projects.firstWhere((project) => project.id == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Get suggestion by ID
  Suggestion? getSuggestionById(String suggestionId) {
    try {
      return _suggestions.firstWhere((suggestion) => suggestion.id == suggestionId);
    } catch (e) {
      return null;
    }
  }

  /// Clear deleted projects list
  void clearDeletedProjects() {
    _deletedProjectIds.clear();
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _projects.clear();
    _suggestions.clear();
    _deletedProjectIds.clear();
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      fetchProjects(),
      refreshSuggestions(),
    ]);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_projects': projects.length,
      'total_suggestions': _suggestions.length,
      'deleted_projects': _deletedProjectIds.length,
      'active_projects': projects.where((p) => p.status == 'active').length,
      'has_error': _error != null,
      'is_loading': _isLoading,
    };
  }
}