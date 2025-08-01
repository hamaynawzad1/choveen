// lib/core/services/backend_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendService {
  // Singleton pattern
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ✅ Initialize demo data
  Future<void> initializeDemoData() async {
    try {
      if (kDebugMode) {
        print('🚀 Initializing Backend Service with demo data...');
      }

      await _initializeDemoUsers();
      await _initializeDemoProjects();
      await _initializeDemoMessages();
      await _initializeAppSettings();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Backend Service initialized successfully with demo data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Backend Service initialization failed: $e');
      }
    }
  }

  // ✅ Initialize demo users
  Future<void> _initializeDemoUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const demoUsersKey = 'demo_users';

      if (!prefs.containsKey(demoUsersKey)) {
        final demoUsers = [
          {
            'id': 'user_demo_1',
            'name': 'Demo User',
            'email': 'demo@choveen.com',
            'skills': ['Flutter', 'Dart', 'Mobile Development'],
            'created_at': DateTime.now().toIso8601String(),
            'avatar': 'https://via.placeholder.com/150?text=DU',
          },
          {
            'id': 'user_demo_2',
            'name': 'AI Assistant',
            'email': 'ai@choveen.com',
            'skills': ['AI', 'Machine Learning', 'Natural Language Processing'],
            'created_at': DateTime.now().toIso8601String(),
            'avatar': 'https://via.placeholder.com/150?text=AI',
          },
        ];

        await prefs.setString(demoUsersKey, json.encode(demoUsers));
        
        if (kDebugMode) {
          print('📝 Created ${demoUsers.length} demo users');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing demo users: $e');
      }
    }
  }

  // ✅ Initialize demo projects
  Future<void> _initializeDemoProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const demoProjectsKey = 'choveen_projects_user_demo_1';

      if (!prefs.containsKey(demoProjectsKey)) {
        final demoProjects = [
          {
            'id': 'project_demo_1',
            'title': 'Choveen Mobile App',
            'description': 'A comprehensive project management app built with Flutter and AI integration',
            'category': 'Mobile Development',
            'required_skills': ['Flutter', 'Dart', 'Firebase', 'AI'],
            'difficulty': 'intermediate',
            'estimated_duration': '8-10 weeks',
            'status': 'active',
            'owner_id': 'user_demo_1',
            'team_members': [],
            'progress': 0.35,
            'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
            'updated_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
          {
            'id': 'project_demo_2',
            'title': 'AI Chat Assistant',
            'description': 'Intelligent chatbot with context awareness and project management capabilities',
            'category': 'AI Development',
            'required_skills': ['Python', 'FastAPI', 'DeepSeek', 'NLP'],
            'difficulty': 'advanced',
            'estimated_duration': '6-8 weeks',
            'status': 'active',
            'owner_id': 'user_demo_1',
            'team_members': [],
            'progress': 0.60,
            'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'project_demo_3',
            'title': 'Task Management Dashboard',
            'description': 'Web-based dashboard for managing tasks, teams, and project analytics',
            'category': 'Web Development',
            'required_skills': ['React', 'Node.js', 'MongoDB', 'Chart.js'],
            'difficulty': 'intermediate',
            'estimated_duration': '4-6 weeks',
            'status': 'planning',
            'owner_id': 'user_demo_1',
            'team_members': [],
            'progress': 0.10,
            'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
            'updated_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          },
        ];

        await prefs.setString(demoProjectsKey, json.encode(demoProjects));
        
        if (kDebugMode) {
          print('📝 Created ${demoProjects.length} demo projects');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing demo projects: $e');
      }
    }
  }

  // ✅ Initialize demo messages
  Future<void> _initializeDemoMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const demoMessagesKey = 'chat_messages_user_demo_1_project_demo_1';

      if (!prefs.containsKey(demoMessagesKey)) {
        final demoMessages = [
          {
            'id': 'msg_demo_1',
            'sender_id': 'ai_assistant',
            'project_id': 'project_demo_1',
            'content': '''👋 **Welcome to your Choveen Mobile App project!**

I'm your AI Project Assistant, and I'm excited to help you build this amazing mobile app! 

🎯 **Project Overview:**
• **Goal**: Create a comprehensive project management app
• **Technology**: Flutter with AI integration
• **Duration**: 8-10 weeks
• **Current Progress**: 35% completed

💡 **What we can work on today:**
• Plan the next development phase
• Discuss technical challenges
• Review code architecture
• Optimize user experience

What would you like to focus on first?''',
            'message_type': 'ai',
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          },
          {
            'id': 'msg_demo_2',
            'sender_id': 'user_demo_1',
            'project_id': 'project_demo_1',
            'content': 'Hi! I want to work on the user authentication system. What approach do you recommend?',
            'message_type': 'user',
            'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 55)).toIso8601String(),
          },
          {
            'id': 'msg_demo_3',
            'sender_id': 'ai_assistant',
            'project_id': 'project_demo_1',
            'content': '''🔐 **Great choice! User authentication is crucial for your app.**

**Recommended Authentication Strategy:**

**Firebase Authentication** (Recommended)
• Easy Flutter integration
• Multiple sign-in methods (Email, Google, Apple)
• Built-in security features
• Real-time user management

**Implementation Steps:**
1. **Setup Firebase project**
   • Add your app to Firebase console
   • Download configuration files
   • Install firebase_auth package

2. **Create authentication screens**
   • Login screen with email/password
   • Registration with validation
   • Password reset functionality

3. **Add social login options**
   • Google Sign-In integration
   • Apple Sign-In (for iOS)

**Security Best Practices:**
• Input validation on all forms
• Secure password requirements
• Email verification flow
• Biometric authentication option

Would you like me to help you set up Firebase, or do you prefer a different authentication method?''',
            'message_type': 'ai',
            'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 50)).toIso8601String(),
          },
          {
            'id': 'msg_demo_4',
            'sender_id': 'user_demo_1',
            'project_id': 'project_demo_1',
            'content': 'Firebase sounds perfect! Can you help me with the setup steps?',
            'message_type': 'user',
            'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
          },
          {
            'id': 'msg_demo_5',
            'sender_id': 'ai_assistant',
            'project_id': 'project_demo_1',
            'content': '''🚀 **Let's set up Firebase Authentication step by step!**

**Step 1: Firebase Console Setup**
```bash
# 1. Go to https://console.firebase.google.com
# 2. Create new project or select existing
# 3. Add Android/iOS app
# 4. Download google-services.json (Android) / GoogleService-Info.plist (iOS)
```

**Step 2: Flutter Dependencies**
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.1.6
```

**Step 3: Initialize Firebase**
```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

**Step 4: Authentication Service**
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (e) {
      print('Sign in error: e');
      return null;
    }
  }
}
```

Ready to implement any of these steps? Which part would you like to start with?''',
            'message_type': 'ai',
            'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 25)).toIso8601String(),
          },
        ];

        await prefs.setString(demoMessagesKey, json.encode(demoMessages));
        
        if (kDebugMode) {
          print('📝 Created ${demoMessages.length} demo messages');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing demo messages: $e');
      }
    }
  }

  // ✅ Initialize app settings
  Future<void> _initializeAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const appSettingsKey = 'app_settings';

      if (!prefs.containsKey(appSettingsKey)) {
        final defaultSettings = {
          'theme_mode': 'system',
          'language': 'en',
          'notifications_enabled': true,
          'chat_notifications': true,
          'project_notifications': true,
          'ai_notifications': true,
          'sound_enabled': true,
          'vibration_enabled': true,
          'auto_backup': true,
          'analytics_enabled': true,
          'first_launch': true,
          'onboarding_completed': false,
          'last_backup': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
        };

        await prefs.setString(appSettingsKey, json.encode(defaultSettings));
        
        if (kDebugMode) {
          print('⚙️ Initialized app settings');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing app settings: $e');
      }
    }
  }

  // ✅ Get demo data
  Future<Map<String, dynamic>> getDemoData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final users = prefs.getString('demo_users') ?? '[]';
      final projects = prefs.getString('choveen_projects_user_demo_1') ?? '[]';
      final messages = prefs.getString('chat_messages_user_demo_1_project_demo_1') ?? '[]';
      final settings = prefs.getString('app_settings') ?? '{}';

      return {
        'users': json.decode(users),
        'projects': json.decode(projects),
        'messages': json.decode(messages),
        'settings': json.decode(settings),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting demo data: $e');
      }
      return {};
    }
  }

  // ✅ Reset demo data
  Future<void> resetDemoData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all demo data
      await prefs.remove('demo_users');
      await prefs.remove('choveen_projects_user_demo_1');
      await prefs.remove('chat_messages_user_demo_1_project_demo_1');
      await prefs.remove('app_settings');
      
      // Reinitialize
      await initializeDemoData();
      
      if (kDebugMode) {
        print('🔄 Demo data reset successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resetting demo data: $e');
      }
    }
  }

  // ✅ Create sample project
  Future<Map<String, dynamic>> createSampleProject(String userId, String projectTitle) async {
    try {
      final sampleProject = {
        'id': 'project_${DateTime.now().millisecondsSinceEpoch}',
        'title': projectTitle,
        'description': 'A new project created with AI assistance',
        'category': 'Custom Development',
        'required_skills': ['Programming', 'Problem Solving'],
        'difficulty': 'intermediate',
        'estimated_duration': '4-6 weeks',
        'status': 'active',
        'owner_id': userId,
        'team_members': [],
        'progress': 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save to user's projects
      final prefs = await SharedPreferences.getInstance();
      final projectsKey = 'choveen_projects_$userId';
      final existingProjectsJson = prefs.getString(projectsKey) ?? '[]';
      final existingProjects = List<Map<String, dynamic>>.from(json.decode(existingProjectsJson));
      
      existingProjects.add(sampleProject);
      await prefs.setString(projectsKey, json.encode(existingProjects));

      if (kDebugMode) {
        print('✅ Created sample project: $projectTitle');
      }

      return sampleProject;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating sample project: $e');
      }
      return {};
    }
  }

  // ✅ Add welcome message to project
  Future<void> addWelcomeMessage(String userId, String projectId, String projectTitle) async {
    try {
      final welcomeMessage = {
        'id': 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
        'sender_id': 'ai_assistant',
        'project_id': projectId,
        'content': '''👋 **Welcome to your $projectTitle project!**

I'm your AI Project Assistant, ready to help you succeed! Here's how we can get started:

🎯 **Project Planning**
• Define clear objectives and milestones
• Break down tasks into manageable pieces
• Set realistic timelines

🔧 **Technical Guidance**
• Choose the right technology stack
• Follow best practices and patterns
• Solve technical challenges together

📊 **Progress Tracking**
• Monitor development progress
• Identify potential bottlenecks
• Celebrate achievements

💡 **Ready to begin?** Ask me anything about your project - from planning to implementation to deployment!

What would you like to work on first?''',
        'message_type': 'ai',
        'created_at': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'chat_messages_${userId}_$projectId';
      final existingMessagesJson = prefs.getString(messagesKey) ?? '[]';
      final existingMessages = List<Map<String, dynamic>>.from(json.decode(existingMessagesJson));
      
      existingMessages.add(welcomeMessage);
      await prefs.setString(messagesKey, json.encode(existingMessages));

      if (kDebugMode) {
        print('✅ Added welcome message for project: $projectTitle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding welcome message: $e');
      }
    }
  }

  // ✅ Get app statistics
  Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Count projects
      final projectsJson = prefs.getString('choveen_projects_user_demo_1') ?? '[]';
      final projects = List<dynamic>.from(json.decode(projectsJson));
      
      // Count messages
      final messagesJson = prefs.getString('chat_messages_user_demo_1_project_demo_1') ?? '[]';
      final messages = List<dynamic>.from(json.decode(messagesJson));
      
      return {
        'total_projects': projects.length,
        'active_projects': projects.where((p) => p['status'] == 'active').length,
        'completed_projects': projects.where((p) => p['status'] == 'completed').length,
        'total_messages': messages.length,
        'ai_messages': messages.where((m) => m['message_type'] == 'ai').length,
        'user_messages': messages.where((m) => m['message_type'] == 'user').length,
        'last_activity': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting app statistics: $e');
      }
      return {};
    }
  }

  // ✅ Export data
  Future<String> exportData() async {
    try {
      final demoData = await getDemoData();
      final statistics = await getAppStatistics();
      
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data': demoData,
        'statistics': statistics,
      };
      
      return json.encode(exportData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting data: $e');
      }
      return '{}';
    }
  }

  // ✅ Import data
  Future<bool> importData(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      final prefs = await SharedPreferences.getInstance();
      
      // Import users
      if (data['data']['users'] != null) {
        await prefs.setString('demo_users', json.encode(data['data']['users']));
      }
      
      // Import projects
      if (data['data']['projects'] != null) {
        await prefs.setString('choveen_projects_user_demo_1', json.encode(data['data']['projects']));
      }
      
      // Import messages
      if (data['data']['messages'] != null) {
        await prefs.setString('chat_messages_user_demo_1_project_demo_1', json.encode(data['data']['messages']));
      }
      
      // Import settings
      if (data['data']['settings'] != null) {
        await prefs.setString('app_settings', json.encode(data['data']['settings']));
      }
      
      if (kDebugMode) {
        print('✅ Data imported successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error importing data: $e');
      }
      return false;
    }
  }

  // ✅ Update user profile
  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const demoUsersKey = 'demo_users';
      
      final usersJson = prefs.getString(demoUsersKey) ?? '[]';
      final users = List<Map<String, dynamic>>.from(json.decode(usersJson));
      
      // Find and update user
      final userIndex = users.indexWhere((user) => user['id'] == userId);
      if (userIndex != -1) {
        users[userIndex] = {...users[userIndex], ...userData, 'updated_at': DateTime.now().toIso8601String()};
        await prefs.setString(demoUsersKey, json.encode(users));
        
        if (kDebugMode) {
          print('✅ User profile updated for: $userId');
        }
        
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'user': users[userIndex],
        };
      } else {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}',
      };
    }
  }

  // ✅ Get user projects
  Future<List<Map<String, dynamic>>> getUserProjects(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsKey = 'choveen_projects_$userId';
      
      final projectsJson = prefs.getString(projectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      if (kDebugMode) {
        print('✅ Retrieved ${projects.length} projects for user: $userId');
      }
      
      return projects;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user projects: $e');
      }
      return [];
    }
  }

  // ✅ Create project
  Future<Map<String, dynamic>> createProject(String userId, Map<String, dynamic> projectData) async {
    try {
      final newProject = {
        'id': 'project_${DateTime.now().millisecondsSinceEpoch}',
        ...projectData,
        'owner_id': userId,
        'status': 'active',
        'progress': 0.0,
        'team_members': [],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      final projectsKey = 'choveen_projects_$userId';
      final existingProjectsJson = prefs.getString(projectsKey) ?? '[]';
      final existingProjects = List<Map<String, dynamic>>.from(json.decode(existingProjectsJson));
      
      existingProjects.add(newProject);
      await prefs.setString(projectsKey, json.encode(existingProjects));

      // Add welcome message
      await addWelcomeMessage(userId, newProject['id'], newProject['title']);

      if (kDebugMode) {
        print('✅ Created project: ${newProject['title']}');
      }

      return {
        'success': true,
        'message': 'Project created successfully',
        'project': newProject,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating project: $e');
      }
      return {
        'success': false,
        'message': 'Failed to create project: ${e.toString()}',
      };
    }
  }

  // ✅ Update project
  Future<Map<String, dynamic>> updateProject(String userId, String projectId, Map<String, dynamic> updateData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsKey = 'choveen_projects_$userId';
      final projectsJson = prefs.getString(projectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      final projectIndex = projects.indexWhere((project) => project['id'] == projectId);
      if (projectIndex != -1) {
        projects[projectIndex] = {
          ...projects[projectIndex], 
          ...updateData, 
          'updated_at': DateTime.now().toIso8601String()
        };
        await prefs.setString(projectsKey, json.encode(projects));
        
        if (kDebugMode) {
          print('✅ Updated project: $projectId');
        }
        
        return {
          'success': true,
          'message': 'Project updated successfully',
          'project': projects[projectIndex],
        };
      } else {
        return {
          'success': false,
          'message': 'Project not found',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating project: $e');
      }
      return {
        'success': false,
        'message': 'Failed to update project: ${e.toString()}',
      };
    }
  }

  // ✅ Delete project
  Future<Map<String, dynamic>> deleteProject(String userId, String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsKey = 'choveen_projects_$userId';
      final projectsJson = prefs.getString(projectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      final projectIndex = projects.indexWhere((project) => project['id'] == projectId);
      if (projectIndex != -1) {
        final deletedProject = projects.removeAt(projectIndex);
        await prefs.setString(projectsKey, json.encode(projects));
        
        // Also delete associated messages
        final messagesKey = 'chat_messages_${userId}_$projectId';
        await prefs.remove(messagesKey);
        
        if (kDebugMode) {
          print('✅ Deleted project: $projectId');
        }
        
        return {
          'success': true,
          'message': 'Project deleted successfully',
          'project': deletedProject,
        };
      } else {
        return {
          'success': false,
          'message': 'Project not found',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting project: $e');
      }
      return {
        'success': false,
        'message': 'Failed to delete project: ${e.toString()}',
      };
    }
  }

  // ✅ Get project by ID
  Future<Map<String, dynamic>?> getProject(String userId, String projectId) async {
    try {
      final projects = await getUserProjects(userId);
      return projects.firstWhere(
        (project) => project['id'] == projectId,
        orElse: () => {},
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting project: $e');
      }
      return null;
    }
  }
}
