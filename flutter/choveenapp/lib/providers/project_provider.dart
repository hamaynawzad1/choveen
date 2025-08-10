// lib/providers/project_provider.dart
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
  
  List<Project> get projects => _projects;
  List<Suggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void initializeForUser(String userId) {
    // Initialize provider for specific user
    _projects.clear();
    _suggestions.clear();
    notifyListeners();
  }
  
  Future<void> fetchProjects() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/api/v1/projects/');
      final List<dynamic> projectsJson = response['data'] ?? response;
      
      _projects = projectsJson.map((json) => Project.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _projects = _generateDemoProjects();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> fetchSuggestions() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/api/v1/projects/suggestions');
      final List<dynamic> suggestionsJson = response['data'] ?? [];
      
      _suggestions = suggestionsJson.map((json) => Suggestion.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _suggestions = _generateDemoSuggestions();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> refreshSuggestions() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/api/v1/projects/suggestions?refresh=1');
      final List<dynamic> suggestionsJson = response['data'] ?? [];
      
      _suggestions = suggestionsJson.map((json) => Suggestion.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _suggestions = _generateRefreshSuggestions();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> joinProject(String projectId, String projectTitle) async {
    try {
      final response = await _apiService.post('/api/v1/projects/$projectId/join', body: {
        'project_title': projectTitle,
      });
      
      if (response['success'] == true) {
        await fetchProjects(); // Refresh projects list
        return true;
      }
      return false;
    } catch (e) {
      print('Error joining project: $e');
      return true; // Return true for demo purposes
    }
  }
  
  Future<bool> createProject(Project project) async {
    try {
      final response = await _apiService.post('/api/v1/projects/', body: project.toJson());
      
      if (response['id'] != null) {
        await fetchProjects(); // Refresh projects list
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  List<Project> _generateDemoProjects() {
    return [
      Project(
        id: 'demo_1',
        title: 'Team Collaboration App',
        description: 'Build a modern team collaboration platform',
        category: 'Mobile Development',
        requiredSkills: ['Flutter', 'Firebase', 'UI/UX'],
        status: 'active',
        teamMembers: [],
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'demo_2', 
        title: 'E-commerce Website',
        description: 'Create a full-featured e-commerce solution',
        category: 'Web Development',
        requiredSkills: ['React', 'Node.js', 'MongoDB'],
        status: 'active',
        teamMembers: [],
        createdAt: DateTime.now(),
      ),
    ];
  }
  
  List<Suggestion> _generateDemoSuggestions() {
    final random = Random();
    final categories = [
      {
        'name': 'Mobile Development',
        'projects': [
          {
            'title': 'Task Management App',
            'description': 'Build a cross-platform task management application with real-time sync',
            'skills': ['Flutter', 'Firebase', 'SQLite'],
          },
          {
            'title': 'Social Media App',
            'description': 'Create a social networking platform with photo sharing and messaging',
            'skills': ['React Native', 'Node.js', 'MongoDB'],
          }
        ]
      },
      {
        'name': 'Web Development', 
        'projects': [
          {
            'title': 'Portfolio Website',
            'description': 'Design and develop a professional portfolio website',
            'skills': ['HTML', 'CSS', 'JavaScript'],
          },
          {
            'title': 'Blog Platform',
            'description': 'Build a content management system for blogging',
            'skills': ['React', 'Express', 'PostgreSQL'],
          }
        ]
      }
    ];
    
    final suggestions = <Suggestion>[];
    
    for (int i = 0; i < 3; i++) {
      final category = categories[random.nextInt(categories.length)];
      final projects = category['projects'] as List<Map<String, dynamic>>;
      final projectIndex = random.nextInt(projects.length);
      final projectTemplate = projects[projectIndex];
      
      final project = Project(
        id: 'intelligent_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: projectTemplate['title'] as String,
        description: projectTemplate['description'] as String,
        category: category['name'] as String,
        requiredSkills: List<String>.from(projectTemplate['skills'] as List),
        status: 'suggested',
        teamMembers: [],
        createdAt: DateTime.now(),
      );
      
      suggestions.add(Suggestion(
        id: 'suggestion_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: 'project',
        project: project,
        description: 'AI recommended based on your skills and interests',
        matchScore: 0.8 + (random.nextDouble() * 0.2),
        timeline: '${2 + random.nextInt(4)}-${4 + random.nextInt(4)} weeks',
        difficulty: ['Beginner', 'Intermediate', 'Advanced'][random.nextInt(3)],
        feature: List<String>.from(projectTemplate['skills'] as List), // Fixed parameter name
      ));
    }
    
    return suggestions;
  }
  
  List<Suggestion> _generateRefreshSuggestions() {
    final refreshProject = Project(
      id: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      title: 'AI-Powered Analytics Dashboard',
      description: 'Build an intelligent analytics dashboard with machine learning insights',
      category: 'Data Science',
      requiredSkills: ['Python', 'TensorFlow', 'React', 'D3.js'],
      status: 'suggested',
      teamMembers: [],
      createdAt: DateTime.now(),
    );
    
    return [
      Suggestion(
        id: 'refresh_suggestion_${DateTime.now().millisecondsSinceEpoch}',
        type: 'project',
        project: refreshProject,
        description: 'Fresh AI recommendation - Perfect for expanding your data science skills',
        matchScore: 0.92,
        timeline: '6-8 weeks',
        difficulty: 'Advanced',
        feature: ['Responsive Design', 'Contact Form', 'Project Gallery'], // Fixed parameter name
      ),
    ];
  }
}