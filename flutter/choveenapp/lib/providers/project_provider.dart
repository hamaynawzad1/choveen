// lib/providers/project_provider.dart
import 'package:flutter/foundation.dart';
import '../core/services/backend_service.dart';
import '../core/services/ai_service.dart';
import '../models/project_model.dart';

class ProjectProvider extends ChangeNotifier {
  final BackendService _backendService = BackendService();
  final AIService _aiService = AIService();

  List<Project> _projects = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;
  String? _error;
  String? _currentUserId;
  Project? _selectedProject;

  // Getters
  List<Project> get projects => _projects;
  List<Map<String, dynamic>> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get error => _error;
  Project? get selectedProject => _selectedProject;
  
  List<Project> get activeProjects => _projects.where((p) => p.isActive).toList();
  List<Project> get completedProjects => _projects.where((p) => p.isCompleted).toList();
  List<Project> get pausedProjects => _projects.where((p) => p.isPaused).toList();
  
  int get totalProjects => _projects.length;
  int get activeProjectsCount => activeProjects.length;
  int get completedProjectsCount => completedProjects.length;

  // ✅ Initialize project provider
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await fetchProjects();
    notifyListeners();
  }

  // ✅ Fetch user projects
  Future<void> fetchProjects() async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    try {
      final projectsData = await _backendService.getUserProjects(_currentUserId!);
      
      _projects = projectsData.map((data) => Project.fromJson(data)).toList();
      
      // Sort by updated date (most recent first)
      _projects.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      
      _error = null;
      print('✅ Loaded ${_projects.length} projects');
      
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching projects: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Create new project
  Future<bool> createProject({
    required String title,
    required String description,
    required String category,
    required List<String> requiredSkills,
    String difficulty = 'intermediate',
    String estimatedDuration = '4-6 weeks',
  }) async {
    if (_currentUserId == null) return false;
    
    _setLoading(true);
    try {
      final projectData = {
        'title': title,
        'description': description,
        'category': category,
        'required_skills': requiredSkills,
        'difficulty': difficulty,
        'estimated_duration': estimatedDuration,
      };
      
      final result = await _backendService.createProject(_currentUserId!, projectData);
      
      if (result['success'] == true) {
        final newProject = Project.fromJson(result['project']);
        _projects.insert(0, newProject); // Add at beginning
        
        _error = null;
        print('✅ Project created: $title');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to create project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating project: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Update project
  Future<bool> updateProject(String projectId, Map<String, dynamic> updateData) async {
    if (_currentUserId == null) return false;
    
    _setLoading(true);
    try {
      final result = await _backendService.updateProject(_currentUserId!, projectId, updateData);
      
      if (result['success'] == true) {
        final updatedProject = Project.fromJson(result['project']);
        final index = _projects.indexWhere((p) => p.id == projectId);
        
        if (index != -1) {
          _projects[index] = updatedProject;
          
          // Update selected project if it's the same one
          if (_selectedProject?.id == projectId) {
            _selectedProject = updatedProject;
          }
        }
        
        _error = null;
        print('✅ Project updated: $projectId');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to update project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating project: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Delete project
  Future<bool> deleteProject(String projectId) async {
    if (_currentUserId == null) return false;
    
    _setLoading(true);
    try {
      final result = await _backendService.deleteProject(_currentUserId!, projectId);
      
      if (result['success'] == true) {
        _projects.removeWhere((p) => p.id == projectId);
        
        // Clear selected project if it was deleted
        if (_selectedProject?.id == projectId) {
          _selectedProject = null;
        }
        
        _error = null;
        print('✅ Project deleted: $projectId');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to delete project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error deleting project: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Get project by ID
  Project? getProject(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      print('❌ Project not found: $projectId');
      return null;
    }
  }

  // ✅ Set selected project
  void setSelectedProject(Project? project) {
    _selectedProject = project;
    notifyListeners();
  }

  // ✅ Update project progress
  Future<bool> updateProjectProgress(String projectId, double progress) async {
    return await updateProject(projectId, {'progress': progress.clamp(0.0, 1.0)});
  }

  // ✅ Update project status
  Future<bool> updateProjectStatus(String projectId, String status) async {
    return await updateProject(projectId, {'status': status});
  }

  // ✅ Add team member to project
  Future<bool> addTeamMember(String projectId, String memberId) async {
    final project = getProject(projectId);
    if (project == null) return false;
    
    if (!project.teamMembers.contains(memberId)) {
      final updatedMembers = [...project.teamMembers, memberId];
      return await updateProject(projectId, {'team_members': updatedMembers});
    }
    
    return true;
  }

  // ✅ Remove team member from project
  Future<bool> removeTeamMember(String projectId, String memberId) async {
    final project = getProject(projectId);
    if (project == null) return false;
    
    final updatedMembers = project.teamMembers.where((id) => id != memberId).toList();
    return await updateProject(projectId, {'team_members': updatedMembers});
  }

  // ✅ Generate AI project suggestions
  Future<void> generateSuggestions({
    required List<String> userSkills,
    List<String>? interests,
    String difficulty = 'intermediate',
  }) async {
    _setLoadingSuggestions(true);
    try {
      final suggestions = await _aiService.generateProjectSuggestions(
        userSkills: userSkills,
        interests: interests,
        difficulty: difficulty,
      );
      
      _suggestions = suggestions;
      _error = null;
      
      print('✅ Generated ${suggestions.length} project suggestions');
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      print('❌ Error generating suggestions: $e');
      notifyListeners();
    } finally {
      _setLoadingSuggestions(false);
    }
  }

  // ✅ Create project from suggestion
  Future<bool> createProjectFromSuggestion(Map<String, dynamic> suggestion) async {
    return await createProject(
      title: suggestion['title'] ?? 'New Project',
      description: suggestion['description'] ?? 'Project created from AI suggestion',
      category: suggestion['category'] ?? 'General',
      requiredSkills: List<String>.from(suggestion['required_skills'] ?? []),
      difficulty: suggestion['difficulty'] ?? 'intermediate',
      estimatedDuration: suggestion['estimated_duration'] ?? '4-6 weeks',
    );
  }

  // ✅ Search projects
  List<Project> searchProjects(String query) {
    if (query.isEmpty) return _projects;
    
    final lowercaseQuery = query.toLowerCase();
    return _projects.where((project) {
      return project.title.toLowerCase().contains(lowercaseQuery) ||
             project.description.toLowerCase().contains(lowercaseQuery) ||
             project.category.toLowerCase().contains(lowercaseQuery) ||
             project.requiredSkills.any((skill) => 
                 skill.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // ✅ Filter projects by category
  List<Project> getProjectsByCategory(String category) {
    return _projects.where((project) => 
        project.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // ✅ Filter projects by status
  List<Project> getProjectsByStatus(String status) {
    return _projects.where((project) => 
        project.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // ✅ Filter projects by difficulty
  List<Project> getProjectsByDifficulty(String difficulty) {
    return _projects.where((project) => 
        project.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();
  }

  // ✅ Get projects by skill match
  List<Project> getProjectsBySkillMatch(List<String> userSkills, {double minMatch = 0.3}) {
    return _projects.where((project) => 
        project.getSkillMatch(userSkills) >= minMatch).toList()
      ..sort((a, b) => b.getSkillMatch(userSkills).compareTo(a.getSkillMatch(userSkills)));
  }

  // ✅ Get overdue projects
  List<Project> getOverdueProjects() {
    return _projects.where((project) => project.isOverdue).toList();
  }

  // ✅ Get recent projects
  List<Project> getRecentProjects({int limit = 5}) {
    final sortedProjects = [..._projects];
    sortedProjects.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return sortedProjects.take(limit).toList();
  }

  // ✅ Get project statistics
  Map<String, dynamic> getProjectStatistics() {
    final totalProgress = _projects.fold<double>(
        0.0, (sum, project) => sum + project.progress);
    final avgProgress = _projects.isNotEmpty ? totalProgress / _projects.length : 0.0;
    
    final categoryCount = <String, int>{};
    final difficultyCount = <String, int>{};
    
    for (final project in _projects) {
      categoryCount[project.category] = (categoryCount[project.category] ?? 0) + 1;
      difficultyCount[project.difficulty] = (difficultyCount[project.difficulty] ?? 0) + 1;
    }
    
    return {
      'total_projects': totalProjects,
      'active_projects': activeProjectsCount,
      'completed_projects': completedProjectsCount,
      'paused_projects': pausedProjects.length,
      'average_progress': avgProgress,
      'overdue_projects': getOverdueProjects().length,
      'categories': categoryCount,
      'difficulties': difficultyCount,
      'total_team_members': _projects.fold<int>(
          0, (sum, project) => sum + project.teamSize),
    };
  }

  // ✅ Refresh projects
  Future<void> refreshProjects() async {
    await fetchProjects();
  }

  // ✅ Clear suggestions
  void clearSuggestions() {
    _suggestions.clear();
    notifyListeners();
  }

  // ✅ Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingSuggestions(bool loading) {
    _isLoadingSuggestions = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _projects.clear();
    _suggestions.clear();
    _selectedProject = null;
    _currentUserId = null;
    _error = null;
    notifyListeners();
  }

  // ✅ Demo project creation
  Future<void> createDemoProjects() async {
    if (_currentUserId == null) return;
    
    final demoProjects = [
      {
        'title': 'Flutter E-commerce App',
        'description': 'Build a complete e-commerce mobile app with payment integration',
        'category': 'Mobile Development',
        'required_skills': ['Flutter', 'Dart', 'Firebase', 'Payment APIs'],
        'difficulty': 'intermediate',
        'estimated_duration': '8-10 weeks',
      },
      {
        'title': 'AI Chat Assistant',
        'description': 'Create an intelligent chatbot with natural language processing',
        'category': 'AI Development',
        'required_skills': ['Python', 'NLP', 'Machine Learning', 'APIs'],
        'difficulty': 'advanced',
        'estimated_duration': '6-8 weeks',
      },
      {
        'title': 'Personal Portfolio Website',
        'description': 'Design and develop a professional portfolio website',
        'category': 'Web Development',
        'required_skills': ['HTML', 'CSS', 'JavaScript', 'React'],
        'difficulty': 'beginner',
        'estimated_duration': '2-3 weeks',
      },
    ];

    for (final projectData in demoProjects) {
      await createProject(
        title: projectData['title']!,
        description: projectData['description']!,
        category: projectData['category']!,
        requiredSkills: List<String>.from(projectData['required_skills']!),
        difficulty: projectData['difficulty']!,
        estimatedDuration: projectData['estimated_duration']!,
      );
    }
  }

  // ✅ Get popular categories
  List<String> getPopularCategories() {
    final statistics = getProjectStatistics();
    final categories = statistics['categories'] as Map<String, int>;
    
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.map((entry) => entry.key).take(5).toList();
  }

  // ✅ Get recommended skills
  Set<String> getRecommendedSkills() {
    final allSkills = <String>{};
    for (final project in _projects) {
      allSkills.addAll(project.requiredSkills);
    }
    return allSkills;
  }
}