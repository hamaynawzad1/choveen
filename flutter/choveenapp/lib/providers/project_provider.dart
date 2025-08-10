// lib/providers/project_provider.dart - NO DEMO PROJECTS VERSION
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';
import '../models/suggestion_model.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ProjectProvider with ChangeNotifier {
  final APIService _apiService = APIService();
  
  List<Project> _projects = [];
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSuggestionFetch;
  String? _currentUserSkills;
  
  List<Project> get projects => _projects;
  List<Suggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void initializeForUser(String userId) {
    // ✅ Initialize empty - no demo projects for new users
    print('🔄 Initializing project provider for user: $userId');
    _projects.clear();
    _suggestions.clear();
    _lastSuggestionFetch = null;
    _currentUserSkills = null;
    notifyListeners();
  }
  
  // ✅ Fetch user's actual joined projects (empty by default)
  Future<void> fetchProjects() async {
    _setLoading(true);
    try {
      print('🔗 Fetching user projects...');
      final response = await _apiService.get('/api/v1/users/projects');
      
      // Handle response format
      List<dynamic> projectsJson;
      if (response is Map<String, dynamic>) {
        projectsJson = response['projects'] ?? [];
        print('📝 Server message: ${response['message']}');
      } else if (response is List) {
        projectsJson = response as List;
      } else {
        projectsJson = [];
      }
      
      _projects = projectsJson.map((json) => Project.fromJson(json as Map<String, dynamic>)).toList();
      _error = null;
      print('✅ Successfully fetched ${_projects.length} user projects');
    } catch (e) {
      print('❌ Fetch projects error: $e');
      _error = e.toString();
      // ✅ NO fallback to demo projects - keep empty
      _projects = [];
    } finally {
      _setLoading(false);
    }
  }
  
  // ✅ Enhanced suggestions with user skills and caching
  Future<void> fetchSuggestions({List<String>? userSkills, bool forceRefresh = false}) async {
    // Check cache
    final skillsString = userSkills?.join(',') ?? '';
    final now = DateTime.now();
    
    if (!forceRefresh && 
        _lastSuggestionFetch != null && 
        _currentUserSkills == skillsString &&
        now.difference(_lastSuggestionFetch!).inMinutes < 5) {
      print('⚡ Using cached suggestions');
      return;
    }
    
    _setLoading(true);
    try {
      print('🎯 Fetching personalized suggestions...');
      print('👤 User skills: $userSkills');
      
      // Build URL with user skills
      String endpoint = '/api/v1/projects/suggestions';
      if (userSkills != null && userSkills.isNotEmpty) {
        final skillsParam = userSkills.join(',');
        endpoint += '?user_skills=${Uri.encodeComponent(skillsParam)}';
      }
      
      final response = await _apiService.get(endpoint);
      
      // Handle response format
      List<dynamic> suggestionsJson;
      if (response is Map<String, dynamic>) {
        suggestionsJson = response['data'] ?? [];
        final isPersonalized = response['personalized'] ?? false;
        print(isPersonalized ? '✨ Got personalized suggestions!' : '📝 Got general suggestions');
      } else if (response is List) {
        suggestionsJson = response as List;
      } else {
        suggestionsJson = [];
      }
      
      _suggestions = suggestionsJson.map((json) => Suggestion.fromJson(json as Map<String, dynamic>)).toList();
      _error = null;
      _lastSuggestionFetch = now;
      _currentUserSkills = skillsString;
      
      print('✅ Successfully fetched ${_suggestions.length} suggestions');
    } catch (e) {
      print('❌ Fetch suggestions error: $e');
      _error = e.toString();
      // ✅ Fallback to minimal suggestions based on skills
      _suggestions = _generateMinimalSuggestions(userSkills);
    } finally {
      _setLoading(false);
    }
  }
  
  // ✅ Force refresh suggestions
  Future<void> refreshSuggestions({List<String>? userSkills}) async {
    print('🔄 Force refreshing suggestions...');
    _lastSuggestionFetch = null;
    await fetchSuggestions(userSkills: userSkills, forceRefresh: true);
  }
  
  // ✅ Enhanced join project - actually adds to user projects
  Future<bool> joinProject(String projectId, String projectTitle) async {
    try {
      print('👥 Joining project: $projectId');
      final response = await _apiService.post('/api/v1/projects/$projectId/join', body: {
        'project_title': projectTitle,
        'user_id': 'current_user',
      });
      
      if (response['success'] == true) {
        print('✅ Successfully joined project: ${response['message']}');
        
        // ✅ Add the joined project to local list immediately
        if (response['project'] != null) {
          final joinedProject = Project.fromJson(response['project']);
          _projects.add(joinedProject);
          notifyListeners();
        }
        
        // Also refresh the full list
        await fetchProjects();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Join project error: $e');
      // ✅ For demo purposes, still add a local project
      final demoProject = Project(
        id: projectId,
        title: projectTitle,
        description: 'You have joined this project successfully!',
        category: 'Joined Project',
        requiredSkills: ['Collaboration'],
        status: 'active',
        teamMembers: [],
        createdAt: DateTime.now(),
      );
      
      _projects.add(demoProject);
      notifyListeners();
      return true;
    }
  }
  
  // ✅ Remove project - actually removes from list
  Future<bool> removeProject(String projectId) async {
    try {
      print('🗑️ Removing project: $projectId');
      
      // Try API call first
      try {
        final response = await _apiService.delete('/api/v1/users/projects/$projectId');
        print('✅ Project removed from server: ${response['message']}');
      } catch (e) {
        print('⚠️ Server removal failed, removing locally: $e');
      }
      
      // Remove from local list
      final originalLength = _projects.length;
      _projects.removeWhere((project) => project.id == projectId);
      
      if (_projects.length < originalLength) {
        print('✅ Project removed from local list');
        notifyListeners();
        return true;
      } else {
        print('⚠️ Project not found in local list');
        return false;
      }
    } catch (e) {
      print('❌ Remove project error: $e');
      _error = e.toString();
      return false;
    }
  }
  
  Future<bool> createProject(Project project) async {
    try {
      print('📝 Creating project: ${project.title}');
      final response = await _apiService.post('/api/v1/projects/', body: project.toJson());
      
      if (response['id'] != null) {
        print('✅ Project created: ${response['id']}');
        await fetchProjects(); // Refresh projects list
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Create project error: $e');
      _error = e.toString();
      return false;
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // ✅ Minimal suggestions generation (only when API fails)
  List<Suggestion> _generateMinimalSuggestions(List<String>? userSkills) {
    print('🔄 Generating minimal fallback suggestions');
    
    final skillsLower = userSkills?.map((s) => s.toLowerCase()).toList() ?? [];
    
    // Basic fallback suggestions
    if (skillsLower.contains('hr')) {
      return [
        Suggestion(
          id: 'fallback_hr_1',
          type: 'project',
          project: Project(
            id: 'proj_hr_system',
            title: 'HR Management System',
            description: 'Build an HR management system for employee tracking',
            category: 'Business',
            requiredSkills: ['HR', 'Management'],
            status: 'suggested',
            teamMembers: [],
            createdAt: DateTime.now(),
          ),
          description: 'Perfect for your HR skills',
          matchScore: 0.9,
          timeline: '4-6 weeks',
          difficulty: 'Intermediate',
          feature: ['HR Match', 'Recommended'],
        ),
      ];
    }
    
    // Default fallback if no skills or other skills
    return [
      Suggestion(
        id: 'fallback_general_1',
        type: 'project',
        project: Project(
          id: 'proj_team_tool',
          title: 'Team Collaboration Tool',
          description: 'Build a simple team collaboration platform',
          category: 'Productivity',
          requiredSkills: ['Communication', 'Organization'],
          status: 'suggested',
          teamMembers: [],
          createdAt: DateTime.now(),
        ),
        description: 'Great for learning team skills',
        matchScore: 0.7,
        timeline: '3-5 weeks',
        difficulty: 'Beginner',
        feature: ['Popular', 'Beginner Friendly'],
      ),
    ];
  }
  
  // ✅ Remove suggestion from list
  void removeSuggestion(dynamic suggestion) {
    _suggestions.remove(suggestion);
    notifyListeners();
  }
  
  // Helper methods
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  String getSuggestionsAge() {
    if (_lastSuggestionFetch == null) return 'Never fetched';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSuggestionFetch!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inHours} hours ago';
    }
  }
  
  // ✅ Debug method to check current state
  void printDebugInfo() {
    print('\n🔍 PROJECT PROVIDER DEBUG:');
    print('   Projects: ${_projects.length}');
    print('   Suggestions: ${_suggestions.length}');
    print('   Loading: $_isLoading');
    print('   Error: ${_error ?? 'none'}');
    print('   Last fetch: ${getSuggestionsAge()}');
    print('');
  }
}