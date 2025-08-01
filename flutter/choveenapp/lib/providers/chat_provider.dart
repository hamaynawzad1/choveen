// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message_model.dart';
import '../core/services/api_service.dart';
import '../core/services/ai_service.dart';
import '../core/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  List<Map<String, dynamic>> _chatList = [];
  List<Map<String, dynamic>> _aiChats = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;
  String? _currentUserId;
  String? _currentProjectId;
  
  final APIService _apiService = APIService();
  final AIService _aiService = AIService();

  // Getters
  List<Message> get messages => _messages;
  List<Map<String, dynamic>> get chatList => _chatList;
  List<Map<String, dynamic>> get aiChats => _aiChats;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  // ✅ Initialize chat provider
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await fetchAIChats();
    await fetchChatList();
    notifyListeners();
  }

  // ✅ Fetch AI chats from local storage
  Future<void> fetchAIChats() async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProjectsKey = 'choveen_projects_$_currentUserId';
      final projectsJson = prefs.getString(userProjectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      _aiChats = projects.map((project) {
        return {
          'id': 'ai_${project['id']}',
          'name': 'AI Team Advisor',
          'projectId': project['id'],
          'projectTitle': project['title'],
          'lastMessage': 'Ready to help with your project!',
          'lastMessageTime': DateTime.now().toString(),
          'type': 'ai_chat',
          'unreadCount': 0,
          'isOnline': true,
        };
      }).toList();
      
      notifyListeners();
      print('✅ Loaded ${_aiChats.length} AI chats');
      
    } catch (e) {
      print('❌ Error fetching AI chats: $e');
      _aiChats = [];
    }
  }

  // ✅ Enhanced AI message sending with intelligent responses
  Future<void> sendAIMessage(String projectId, String message) async {
    if (message.trim().isEmpty || _currentUserId == null) return;
    
    _setSendingMessage(true);
    try {
      print('🤖 Sending AI message for project: $projectId');
      _currentProjectId = projectId;
      
      // Create user message
      final userMessage = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _currentUserId!,
        projectId: projectId,
        content: message.trim(),
        messageType: 'user',
        createdAt: DateTime.now(),
      );
      
      _messages.add(userMessage);
      notifyListeners();
      
      // Save user message
      await _saveMessage(userMessage);
      
      // Get project context
      final projectContext = await _getProjectContext(projectId);
      final userSkills = await _getUserSkills();
      
      // Get AI response with enhanced context
      final aiResponse = await _aiService.getSmartAIResponse(
        message: message.trim(),
        projectTitle: projectContext['title'],
        projectContext: projectContext['description'],
        userSkills: userSkills,
      );
      
      // Create AI message
      final aiMessage = Message(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'ai_assistant',
        projectId: projectId,
        content: aiResponse,
        messageType: 'ai',
        createdAt: DateTime.now(),
      );
      
      _messages.add(aiMessage);
      await _saveMessage(aiMessage);
      
      // Update AI chat last message
      updateAIChatLastMessage(projectId, aiResponse);
      
      _error = null;
      print('✅ AI response generated successfully');
      
    } catch (e) {
      _error = e.toString();
      print('❌ AI chat error: $e');
      
      // Provide intelligent fallback response
      final fallbackResponse = _generateIntelligentFallback(message, projectId);
      
      final fallbackMessage = Message(
        id: 'msg_fallback_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'ai_assistant',
        projectId: projectId,
        content: fallbackResponse,
        messageType: 'ai',
        createdAt: DateTime.now(),
      );
      
      _messages.add(fallbackMessage);
      await _saveMessage(fallbackMessage);
      updateAIChatLastMessage(projectId, fallbackResponse);
      
    } finally {
      _setSendingMessage(false);
    }
  }

  // ✅ Get project context for AI
  Future<Map<String, String>> _getProjectContext(String projectId) async {
    try {
      // Try to get project from backend/storage first
      final prefs = await SharedPreferences.getInstance();
      final userProjectsKey = 'choveen_projects_$_currentUserId';
      final projectsJson = prefs.getString(userProjectsKey) ?? '[]';
      final projects = List<Map<String, dynamic>>.from(json.decode(projectsJson));
      
      final project = projects.firstWhere(
        (p) => p['id'] == projectId,
        orElse: () => {},
      );
      
      if (project.isNotEmpty) {
        return {
          'title': project['title'] ?? 'Project',
          'description': project['description'] ?? 'Development project',
        };
      }
    } catch (e) {
      print('⚠️ Error getting project context: $e');
    }
    
    return {
      'title': 'Current Project',
      'description': 'Active development project',
    };
  }

  // ✅ Get user skills for context
  Future<List<String>> _getUserSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skillsJson = prefs.getString('user_skills_$_currentUserId') ?? '[]';
      return List<String>.from(json.decode(skillsJson));
    } catch (e) {
      return ['Programming', 'Development', 'Problem Solving'];
    }
  }

  // ✅ Generate intelligent fallback responses
  String _generateIntelligentFallback(String message, String projectId) {
    final msgLower = message.toLowerCase();
    
    // Context-aware responses based on message content
    if (msgLower.contains(RegExp(r'\b(hello|hi|hey|greetings|سڵاو)\b'))) {
      return '''👋 **Hello! I'm your AI Project Assistant**

I'm here to help you succeed with your project! Here's how I can assist:

🎯 **Project Planning & Strategy**
• Break down complex tasks into manageable steps
• Create realistic timelines and milestones
• Suggest best practices and methodologies

💡 **Problem Solving & Guidance**  
• Debug issues and provide solutions
• Recommend tools and technologies
• Share industry insights and tips

📊 **Progress Tracking & Optimization**
• Analyze project performance
• Identify bottlenecks and improvements
• Suggest optimization strategies

What would you like to work on today?''';
    }
    
    if (msgLower.contains(RegExp(r'\b(plan|planning|organize|roadmap)\b'))) {
      return '''📋 **Let's create a solid project plan!**

🚀 **Project Planning Framework:**

**1. Discovery Phase** (Week 1)
• Define clear objectives and goals
• Identify target audience and requirements
• Research competitors and best practices
• Set success metrics

**2. Design Phase** (Week 2-3)  
• Create wireframes and prototypes
• Design user experience flow
• Plan system architecture
• Prepare technical specifications

**3. Development Phase** (Week 4-8)
• Set up development environment
• Implement core features iteratively
• Regular testing and quality assurance
• Code reviews and optimization

**4. Launch Phase** (Week 9-10)
• Final testing and bug fixes
• Deployment and monitoring setup
• User onboarding and documentation
• Performance analysis

Which phase would you like to dive deeper into?''';
    }
    
    if (msgLower.contains(RegExp(r'\b(help|stuck|problem|issue|challenge)\b'))) {
      return '''🔧 **I'm here to help solve challenges!**

🎯 **Problem-Solving Approach:**

**1. Define the Problem**
• What exactly is the issue?
• When does it occur?
• What's the expected vs actual behavior?

**2. Analyze Root Causes**  
• Check recent changes
• Review error logs or messages
• Identify patterns or triggers

**3. Generate Solutions**
• Brainstorm multiple approaches
• Research similar cases online
• Consider alternative methods

**4. Test & Implement**
• Start with simplest solution
• Test in safe environment
• Document what works

**5. Prevent Future Issues**
• Add monitoring or alerts
• Update documentation
• Share learnings with team

📝 **Describe your specific challenge and I'll provide targeted guidance!**''';
    }
    
    if (msgLower.contains(RegExp(r'\b(team|collaborate|members|communication)\b'))) {
      return '''👥 **Building Effective Team Collaboration**

🤝 **Team Success Framework:**

**Communication Channels**
• Daily standups (15 min max)
• Weekly planning sessions
• Async updates in chat
• Clear escalation paths

**Task Management**
• Use project boards (Kanban style)
• Clear task descriptions and acceptance criteria
• Regular progress updates
• Blocker identification and resolution

**Collaboration Best Practices**
• Version control for all work (Git)
• Code/design review processes
• Shared documentation (Wiki/Docs)
• Knowledge sharing sessions

**Team Culture**
• Celebrate achievements together
• Learn from failures constructively
• Support each other's growth
• Maintain work-life balance

🎯 **What specific aspect of team collaboration needs attention?**''';
    }
    
    // Default intelligent response
    return '''🤖 **AI Project Assistant Ready!**

I'm here to help with your project success. Here are some ways I can assist:

🎯 **Project Management**
• Planning and roadmap creation
• Task breakdown and prioritization
• Timeline and milestone planning
• Resource allocation guidance

🔧 **Technical Support**  
• Best practices and recommendations
• Problem-solving and debugging
• Code review and optimization
• Tool and technology suggestions

👥 **Team Collaboration**
• Communication strategies
• Workflow optimization
• Role definition and delegation
• Conflict resolution

📊 **Quality & Performance**
• Testing strategies
• Performance optimization
• Quality assurance processes
• Metrics and analytics

💡 **Ask me specific questions like:**
• "How should we organize our development workflow?"
• "What's the best approach for user authentication?"
• "How can we improve team communication?"
• "What testing strategy should we use?"

What would you like help with today?''';
  }

  // ✅ Message persistence
  Future<void> _saveMessage(Message message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'chat_messages_${_currentUserId}_${message.projectId}';
      final messagesJson = prefs.getString(messagesKey) ?? '[]';
      final messages = List<Map<String, dynamic>>.from(json.decode(messagesJson));
      
      messages.add(message.toJson());
      await prefs.setString(messagesKey, json.encode(messages));
      
    } catch (e) {
      print('⚠️ Failed to save message: $e');
    }
  }

  // ✅ Load messages for project
  Future<void> fetchMessages(String chatId) async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    try {
      print('📨 Loading messages for chat: $chatId');
      
      // Extract project ID from chat ID
      String projectId = chatId;
      if (chatId.startsWith('ai_')) {
        projectId = chatId.substring(3);
      }
      
      // Load from local storage
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'chat_messages_${_currentUserId}_$projectId';
      final messagesJson = prefs.getString(messagesKey) ?? '[]';
      final messagesData = List<Map<String, dynamic>>.from(json.decode(messagesJson));
      
      _messages = messagesData.map((data) => Message.fromJson(data)).toList();
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      print('✅ Loaded ${_messages.length} messages');
      _error = null;
      
    } catch (e) {
      print('❌ Error loading messages: $e');
      _error = e.toString();
      _messages = [];
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Update AI chat last message
  void updateAIChatLastMessage(String chatId, String message) {
    final chatIndex = _aiChats.indexWhere((chat) => chat['id'] == chatId);
    if (chatIndex != -1) {
      _aiChats[chatIndex]['lastMessage'] = message.length > 50 
          ? '${message.substring(0, 50)}...' 
          : message;
      _aiChats[chatIndex]['lastMessageTime'] = DateTime.now().toString();
    } else {
      // Create new AI chat entry
      _aiChats.add({
        'id': chatId,
        'name': 'AI Assistant',
        'projectId': chatId,
        'lastMessage': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        'lastMessageTime': DateTime.now().toString(),
        'type': 'ai_chat',
      });
    }
    notifyListeners();
  }

  // ✅ Regular chat functionality
  Future<void> fetchChatList() async {
    _setLoading(true);
    try {
      // For now, return empty list - implement when needed
      _chatList = [];
      _error = null;
    } catch (e) {
      print('❌ Error fetching chat list: $e');
      _error = e.toString();
      _chatList = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (content.trim().isEmpty || _currentUserId == null) return;
    
    try {
      print('📤 Sending message to chat: $chatId');
      
      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _currentUserId!,
        receiverId: chatId,
        content: content.trim(),
        messageType: 'user',
        createdAt: DateTime.now(),
      );
      
      _messages.add(message);
      await _saveMessage(message);
      notifyListeners();
      
    } catch (e) {
      print('❌ Error sending message: $e');
      _error = e.toString();
    }
  }

  // ✅ Clear messages for project
  Future<void> clearMessages(String projectId) async {
    try {
      if (_currentUserId == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'chat_messages_${_currentUserId}_$projectId';
      await prefs.remove(messagesKey);
      
      _messages.clear();
      notifyListeners();
      
      print('✅ Messages cleared for project: $projectId');
    } catch (e) {
      print('❌ Error clearing messages: $e');
    }
  }

  // ✅ Get chat statistics
  Map<String, dynamic> getChatStatistics() {
    return {
      'total_messages': _messages.length,
      'user_messages': _messages.where((m) => m.messageType == 'user').length,
      'ai_messages': _messages.where((m) => m.messageType == 'ai').length,
      'current_project': _currentProjectId,
      'current_user': _currentUserId,
      'has_error': _error != null,
      'is_loading': _isLoading,
    };
  }

  // ✅ Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _messages.clear();
    _chatList.clear();
    _aiChats.clear();
    _currentProjectId = null;
    _currentUserId = null;
    _error = null;
    notifyListeners();
  }

  // ✅ Test AI response
  Future<void> testAIResponse() async {
    if (_currentUserId == null) return;
    
    await sendAIMessage(
      'test_project_${DateTime.now().millisecondsSinceEpoch}',
      'Hello AI, can you help me with project planning?'
    );
  }
}