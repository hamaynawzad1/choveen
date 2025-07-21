import 'dart:convert'; // For json
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For SharedPreferences
import '../core/services/api_service.dart';
import '../core/services/ai_service.dart';
import '../core/constants/api_constants.dart';
import '../models/message_model.dart';
import '../models/project_model.dart';
import 'project_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final EnhancedAIService _aiService = EnhancedAIService();
  
  // Get AI response with enhanced service
  Future<void> _getAIResponse(String projectId, String message) async {
    _setSendingMessage(true);
    
    try {
      // Get project and user context
      Project? project;
      List<String>? userSkills;
      
      try {
        // Get project info safely without BuildContext
        final projects = _getCachedProjects();
        project = projects.firstWhere(
          (p) => p.id == projectId,
          orElse: () => projects.first,
        );
        
        // Get user skills
        userSkills = await _getUserSkills();
      } catch (e) {
        print('Context gathering error: $e');
      }
      
      // Call the enhanced AI service
      final aiResponse = await _aiService.getSmartAIResponse(
        message: message,
        projectTitle: project?.title,
        projectContext: project?.description,
        userSkills: userSkills,
      );
      
      // Create AI message
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'ai_assistant',
        projectId: projectId,
        content: aiResponse,
        messageType: 'ai',
        createdAt: DateTime.now(),
      );
      
      _messages.add(aiMessage);
      updateAIChatLastMessage(projectId, aiResponse);
      
      _error = null;
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      print('Error getting AI response: $e');
      
      // Use enhanced fallback
      final fallbackResponse = await _aiService.getSmartAIResponse(
        message: message,
        projectTitle: 'Your Project',
        userSkills: ['Your Skills'],
      );
      
      final fallbackMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'ai_assistant',
        projectId: projectId,
        content: fallbackResponse,
        messageType: 'ai',
        createdAt: DateTime.now(),
      );
      
      _messages.add(fallbackMessage);
      updateAIChatLastMessage(projectId, fallbackResponse);
      
      notifyListeners();
    } finally {
      _setSendingMessage(false);
    }
  }

  void initializeForUser(String userId) {
  if (_currentUserId != userId) {
    // Clear all data when switching users
    _messages.clear();
    _chatList.clear();
    _aiChats.clear();
    _currentProjectId = null;
    _currentUserId = userId;
    _error = null;
    print('🔄 ChatProvider initialized for user: $userId');
    notifyListeners();
  }
}

  // Helper to get cached projects
  List<Project> _getCachedProjects() {
    // This should be passed from ProjectProvider or stored locally
    return [];
  }

  // Helper to get user skills
  Future<List<String>> _getUserSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('choveen_current_user');
      if (userJson != null) {
        final user = json.decode(userJson);
        return List<String>.from(user['skills'] ?? []);
      }
    } catch (e) {
      print('Error getting user skills: $e');
    }
    return [];
  }

  List<Message> _messages = [];
  List<Map<String, dynamic>> _chatList = [];
  List<Map<String, dynamic>> _aiChats = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;
  String? _currentProjectId;
  String? _currentUserId;

  // Getters
  List<Message> get messages => _messages;
  List<Map<String, dynamic>> get chatList => _chatList;
  List<Map<String, dynamic>> get aiChats => _aiChats;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;
  String? get currentProjectId => _currentProjectId;

void updateAIChatLastMessage(String chatId, String message) {
  final chatIndex = _aiChats.indexWhere((chat) => chat['id'] == chatId);
  if (chatIndex != -1) {
    _aiChats[chatIndex]['lastMessage'] = message;
    _aiChats[chatIndex]['lastMessageTime'] = DateTime.now().toString();
    notifyListeners();
  }
}

Future<void> fetchChatList() async {
  _setLoading(true);
  try {
    final response = await _apiService.get('/chats');
    _chatList = List<Map<String, dynamic>>.from(response['data'] ?? []);
    notifyListeners();
  } catch (e) {
    print('Error fetching chat list: $e');
  } finally {
    _setLoading(false);
  }
}

Future<void> fetchMessages(String chatId) async {
  _setLoading(true);
  try {
    final response = await _apiService.get('/chats/$chatId/messages');
    _messages = (response['data'] as List).map((msg) => Message.fromJson(msg)).toList();
    notifyListeners();
  } catch (e) {
    print('Error fetching messages: $e');
  } finally {
    _setLoading(false);
  }
}

Future<void> sendMessage(String chatId, String content) async {
  try {
    final response = await _apiService.post(
      '/chats/$chatId/messages',
      body: {'content': content},
    );
    _messages.add(Message.fromJson(response['data']));
    notifyListeners();
  } catch (e) {
    print('Error sending message: $e');
  }
}

Future<void> sendAIMessage(String projectId, String message) async {
  try {
    await sendMessage('ai_$projectId', message);
    await _getAIResponse(projectId, message);
  } catch (e) {
    print('Error in AI chat: $e');
  }
}
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    notifyListeners();
  }

  // Better fallback responses
  String _getEnhancedFallbackResponse(String message) {
    final messageLower = message.toLowerCase();
    
    // Greeting responses
    if (messageLower.contains(RegExp(r'\b(hello|hi|hey|start|begin)\b'))) {
      return "Hello! 👋 I'm your AI project assistant. I can help you with:\n\n"
             "• Project planning and roadmaps\n"
             "• Technical guidance and best practices\n"
             "• Task breakdown and prioritization\n"
             "• Team coordination strategies\n\n"
             "What would you like to work on today?";
    }
    
    // Project planning
    if (messageLower.contains(RegExp(r'\b(plan|planning|organize|structure|roadmap)\b'))) {
      return "📋 Let's create a solid project plan! Here's my approach:\n\n"
             "1. **Define Clear Objectives**: What problem are we solving?\n"
             "2. **Break Down Tasks**: Create manageable work units\n"
             "3. **Set Milestones**: Key deliverables with deadlines\n"
             "4. **Allocate Resources**: Match tasks with team skills\n\n"
             "What's your project's main goal?";
    }
    
    // Team collaboration
    if (messageLower.contains(RegExp(r'\b(team|collaborate|work together|members|communication)\b'))) {
      return "👥 Effective team collaboration is crucial! Consider:\n\n"
             "• **Daily Standups**: 15-min sync meetings\n"
             "• **Clear Roles**: Everyone knows their responsibilities\n"
             "• **Communication Channels**: Slack/Discord for quick chats\n"
             "• **Code Reviews**: Maintain quality standards\n"
             "• **Documentation**: Keep everyone on the same page\n\n"
             "What collaboration challenge are you facing?";
    }
    
    // Technical guidance
    if (messageLower.contains(RegExp(r'\b(code|technical|development|programming|debug|error|bug)\b'))) {
      return "🔧 I'm here to help with technical challenges!\n\n"
             "To provide the best guidance, please share:\n"
             "• The specific issue or error message\n"
             "• Your technology stack (languages, frameworks)\n"
             "• What you've already tried\n"
             "• Any relevant code snippets\n\n"
             "This helps me give you targeted solutions!";
    }
    
    // Task management
    if (messageLower.contains(RegExp(r'\b(task|todo|priority|deadline|schedule)\b'))) {
      return "📝 Let's organize your tasks effectively:\n\n"
             "• **Prioritize**: Use MoSCoW (Must/Should/Could/Won't)\n"
             "• **Time Estimates**: Be realistic, add buffer time\n"
             "• **Dependencies**: Identify blocking tasks\n"
             "• **Daily Goals**: Focus on 3-5 key tasks\n\n"
             "What tasks need organizing?";
    }
    
    // Best practices
    if (messageLower.contains(RegExp(r'\b(best practice|quality|standard|improve|optimize)\b'))) {
      return "✨ Here are key best practices for your project:\n\n"
             "• **Code Quality**: Write clean, self-documenting code\n"
             "• **Testing**: Aim for 80%+ code coverage\n"
             "• **Version Control**: Commit often with clear messages\n"
             "• **Security**: Follow OWASP guidelines\n"
             "• **Performance**: Profile before optimizing\n"
             "• **Documentation**: Keep README updated\n\n"
             "Which area would you like to focus on?";
    }
    
    // Learning resources
    if (messageLower.contains(RegExp(r'\b(learn|tutorial|guide|how to|teach)\b'))) {
      return "📚 I can guide your learning journey!\n\n"
             "Tell me what you'd like to learn about:\n"
             "• Specific technologies or frameworks\n"
             "• Design patterns and architecture\n"
             "• Development methodologies\n"
             "• Problem-solving techniques\n\n"
             "I'll provide tailored resources and explanations!";
    }
    
    // Non-project topics
    if (messageLower.contains(RegExp(r'\b(weather|car|ferrari|bugatti|food|movie|sport|personal)\b'))) {
      return "🤖 I'm focused on helping with your project work.\n\n"
             "I can assist with:\n"
             "• Project planning and management\n"
             "• Technical problem-solving\n"
             "• Team collaboration\n"
             "• Code reviews and optimization\n\n"
             "What project-related topic can I help with?";
    }
    
    // Default helpful response
    return "🚀 I'm here to help with your project!\n\n"
           "I can assist with:\n"
           "• **Planning**: Break down complex projects\n"
           "• **Technical**: Solve coding challenges\n"
           "• **Team**: Improve collaboration\n"
           "• **Quality**: Enhance code standards\n\n"
           "What specific aspect would you like to discuss?";
  }
}