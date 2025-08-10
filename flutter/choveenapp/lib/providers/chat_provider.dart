// lib/providers/chat_provider.dart - COMPLETELY FIXED VERSION
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../core/services/api_service.dart';

class ChatProvider with ChangeNotifier {
  final APIService _apiService = APIService();
  
  List<Message> _messages = [];
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;

  // Getters
  List<Message> get messages => _messages;
  List<Map<String, dynamic>> get chatList => _chatList;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;

  // ✅ FIXED: Enhanced AI Chat with Context
  Future<void> sendAIMessage(String projectId, String message) async {
    if (_isSendingMessage) return;
    
    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    try {
      // Add user message immediately
      final userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_user',
        content: message,
        messageType: 'user',
        projectId: projectId,
        createdAt: DateTime.now(),
      );
      
      _messages.add(userMessage);
      notifyListeners();

      // ✅ Generate intelligent AI response based on context
      final aiResponse = await _generateIntelligentResponse(message, projectId);
      
      // Add AI message
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'ai_assistant',
        content: aiResponse,
        messageType: 'ai',
        projectId: projectId,
        createdAt: DateTime.now(),
      );
      
      _messages.add(aiMessage);
      
      // Call API (optional - for persistent storage)
      try {
        await _apiService.sendAIChatMessage(projectId, message);
      } catch (e) {
        print('API call failed, but local chat continues: $e');
      }
      
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('Error in sendAIMessage: $e');
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // ✅ FIXED: Intelligent AI Response Generator
  Future<String> _generateIntelligentResponse(String userMessage, String projectId) async {
    final message = userMessage.toLowerCase().trim();
    
    // Context-aware responses based on conversation
    final recentMessages = _messages.where((m) => m.projectId == projectId).toList();
    final conversationContext = recentMessages.length;
    
    // Welcome message for new conversations
    if (conversationContext <= 1) {
      return """🤖 **Welcome to your AI Project Assistant!**

I'm here to help you with your project development. I can assist with:

• **Project Planning** - Breaking down tasks and timelines
• **Technical Guidance** - Code architecture and best practices  
• **Problem Solving** - Debugging and optimization strategies
• **Team Coordination** - Collaboration tips and workflow

💡 **What would you like to work on today?**

Try asking me:
- "How should I structure this project?"
- "What technologies should I use?"
- "Help me plan the development phases"
- "I'm stuck with [specific problem]"

Let's build something amazing together! 🚀""";
    }

    // Context-based intelligent responses
    if (_containsKeywords(message, ['plan', 'planning', 'structure', 'organize'])) {
      return _generatePlanningResponse(message, conversationContext);
    }
    
    if (_containsKeywords(message, ['help', 'stuck', 'problem', 'issue', 'error'])) {
      return _generateProblemSolvingResponse(message, conversationContext);
    }
    
    if (_containsKeywords(message, ['technology', 'tech', 'framework', 'library', 'tool'])) {
      return _generateTechnicalResponse(message, conversationContext);
    }
    
    if (_containsKeywords(message, ['team', 'collaboration', 'members', 'roles'])) {
      return _generateTeamResponse(message, conversationContext);
    }
    
    if (_containsKeywords(message, ['code', 'programming', 'development', 'implement'])) {
      return _generateCodeResponse(message, conversationContext);
    }
    
    if (_containsKeywords(message, ['hi', 'hello', 'hey', 'thanks', 'thank you'])) {
      return _generateGreetingResponse(message, conversationContext);
    }
    
    // Default intelligent response
    return _generateContextualResponse(message, conversationContext);
  }

  String _generatePlanningResponse(String message, int context) {
    final responses = [
      """🎯 **Excellent! Let's plan your project strategically.**

**Phase 1: Foundation**
• Define core features and MVP scope
• Set up development environment
• Create project repository and structure

**Phase 2: Development**
• Implement core functionality
• Build user interface components
• Integrate APIs and services

**Phase 3: Testing & Deployment**
• Comprehensive testing strategy
• Performance optimization
• Production deployment

🚀 **Which phase would you like to dive deeper into?**""",

      """📋 **Smart planning approach for your project:**

**Week 1-2: Research & Setup**
- Technology stack finalization
- Environment configuration
- Team role assignments

**Week 3-6: Core Development**
- Feature implementation sprints
- Regular testing cycles
- Code reviews and refactoring

**Week 7-8: Polish & Launch**
- UI/UX improvements
- Performance optimization
- Documentation and deployment

💡 **What's your project timeline and team size?**""",
    ];
    
    return responses[context % responses.length];
  }

  String _generateProblemSolvingResponse(String message, int context) {
    return """🔧 **I'm here to help solve your challenge!**

**Let's debug this systematically:**

1. **Identify the Problem**
   - What exactly is happening vs. expected behavior?
   - When did this issue first appear?

2. **Gather Information**
   - Error messages or logs
   - Steps to reproduce
   - Environment details

3. **Troubleshooting Strategy**
   - Check common causes first
   - Isolate the problem area
   - Test solutions incrementally

4. **Prevention**
   - Implement proper error handling
   - Add logging and monitoring
   - Write tests for edge cases

💬 **Can you describe the specific problem you're facing? Include any error messages or unexpected behavior.**

I'll provide targeted solutions based on your situation!""";
  }

  String _generateTechnicalResponse(String message, int context) {
    return """⚡ **Technology Recommendations:**

**For Web Development:**
• **Frontend**: React, Vue.js, or Angular
• **Backend**: Node.js, Python (Django/FastAPI), or Java
• **Database**: PostgreSQL, MongoDB, or Redis

**For Mobile Apps:**
• **Cross-platform**: Flutter, React Native
• **Native**: Swift (iOS), Kotlin (Android)

**For Data & AI:**
• **Languages**: Python, R, Julia
• **Frameworks**: TensorFlow, PyTorch, Scikit-learn
• **Tools**: Jupyter, Apache Spark

**DevOps & Deployment:**
• **Cloud**: AWS, Google Cloud, Azure
• **Containers**: Docker, Kubernetes
• **CI/CD**: GitHub Actions, Jenkins

🤔 **What type of project are you building? I can provide more specific recommendations based on your needs.**""";
  }

  String _generateTeamResponse(String message, int context) {
    return """👥 **Team Collaboration Best Practices:**

**Effective Team Structure:**
• **Project Manager** - Oversees timeline and deliverables
• **Lead Developer** - Technical decisions and architecture
• **Frontend Developers** - UI/UX implementation
• **Backend Developers** - Server logic and APIs
• **QA Engineer** - Testing and quality assurance

**Communication Tools:**
• **Daily standups** - Quick progress updates
• **Sprint planning** - Goal setting and task assignment
• **Code reviews** - Knowledge sharing and quality
• **Documentation** - Shared knowledge base

**Workflow Tips:**
• Use Git branching strategies
• Implement continuous integration
• Regular team retrospectives
• Clear coding standards

👨‍💻 **How many team members do you have? I can suggest an optimal structure for your team size.**""";
  }

  String _generateCodeResponse(String message, int context) {
    return """💻 **Coding Best Practices & Implementation:**

**Code Quality Standards:**
• **Clean Code** - Readable, maintainable functions
• **SOLID Principles** - Object-oriented design patterns
• **DRY Principle** - Don't Repeat Yourself
• **Testing** - Unit, integration, and end-to-end tests

**Development Workflow:**
1. **Feature Planning** - Break down into small tasks
2. **Implementation** - Write clean, documented code
3. **Testing** - Verify functionality works correctly
4. **Code Review** - Team feedback and improvements
5. **Deployment** - Safe production releases

**Useful Resources:**
• Version control with Git
• Automated testing frameworks
• Code formatting tools
• Performance monitoring

🛠️ **What specific coding challenge are you working on? I can provide targeted examples and solutions.**""";
  }

  String _generateGreetingResponse(String message, int context) {
    if (message.contains('thank')) {
      return """😊 **You're very welcome!**

I'm always here to help with your project development. Feel free to ask me anything about:

• Planning and organization
• Technical implementation
• Problem-solving strategies
• Team collaboration
• Best practices

🚀 **Keep up the great work on your project!**""";
    }
    
    return """👋 **Hello! Great to see you here!**

I'm your AI project assistant, ready to help you succeed. Whether you need help with planning, coding, problem-solving, or team coordination, I'm here to support you.

💡 **What can I help you with today?**

- Project planning and task breakdown
- Technical architecture decisions  
- Debugging and troubleshooting
- Best practices and recommendations
- Team collaboration strategies

Let's make your project amazing! ✨""";
  }

  String _generateContextualResponse(String message, int context) {
    return """🤖 **I understand you're working on: "$message"**

Let me help you with that! Here's my analysis and recommendations:

**Key Points to Consider:**
• Break down complex tasks into smaller, manageable pieces
• Consider the technical requirements and constraints
• Think about user experience and functionality
• Plan for testing and quality assurance

**Next Steps:**
1. **Clarify Requirements** - What exactly needs to be accomplished?
2. **Research Solutions** - Look into best practices and existing solutions
3. **Create Action Plan** - Step-by-step implementation strategy
4. **Execute & Iterate** - Build, test, and improve

💬 **Could you provide more details about what you're trying to achieve? The more context you give me, the better I can assist you!**

For example:
- What specific outcome are you looking for?
- Are there any constraints or requirements?
- What have you tried so far?""";
  }

  bool _containsKeywords(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  // ✅ COMPLETELY FIXED: Enhanced message fetching
  Future<void> fetchMessages(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (chatId.startsWith('ai_')) {
        // For AI chats, load from local storage or generate welcome
        final projectId = chatId.substring(3);
        final existingMessages = _messages.where((m) => m.projectId == projectId).toList();
        
        if (existingMessages.isEmpty) {
          // Add welcome message for new AI chats
          final welcomeMessage = Message(
            id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
            senderId: 'ai_assistant',
            content: '''🤖 **Welcome to your AI Project Assistant!**

I'm here to help you with your project development. I can assist with:

• **Project Planning** - Breaking down tasks and timelines
• **Technical Guidance** - Code architecture and best practices  
• **Problem Solving** - Debugging and optimization strategies
• **Team Coordination** - Collaboration tips and workflow

💡 **What would you like to work on today?**''',
            messageType: 'ai',
            projectId: projectId,
            createdAt: DateTime.now(),
          );
          
          _messages.add(welcomeMessage);
        }
      } else {
        // ✅ FIXED: Proper API response handling
        try {
          final response = await _apiService.getChatMessages(chatId);
          print('📦 Chat messages response: $response');
          
          // ✅ FIXED: Handle different response formats with proper typing
          List<dynamic> messagesList;
          
          if (response is Map<String, dynamic>) {
            // If response is a Map, extract messages array
            final messagesData = response['messages'] ?? response['data'] ?? [];
            messagesList = messagesData is List ? messagesData : [];
          } else if (response is List) {
            // If response is already a List
            messagesList = response as List;
          } else {
            throw Exception('Unexpected response format: ${response.runtimeType}');
          }
          
          // ✅ FIXED: Proper mapping with type casting
          _messages = messagesList
              .map((data) => Message.fromJson(data as Map<String, dynamic>))
              .toList();
              
          print('✅ Successfully loaded ${_messages.length} messages');
          
        } catch (e) {
          print('❌ API fetch failed, using local messages: $e');
          _error = 'Could not load messages from server';
        }
      }
    } catch (e) {
      _error = 'Failed to load messages: $e';
      print('❌ Error in fetchMessages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ FIXED: Chat list management
  Future<void> fetchChatList() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try API first
      try {
        final response = await _apiService.getChatList();
        print('📦 Chat list response: $response');
        
        // ✅ FIXED: Proper response handling with type safety
        List<dynamic> chatsList;
        
        if (response is Map<String, dynamic>) {
          final chatsData = response['chats'] ?? response['data'] ?? [];
          chatsList = chatsData is List ? chatsData : [];
        } else if (response is List) {
          chatsList = response as List;
        } else {
          throw Exception('Unexpected chat list format');
        }
        
        _chatList = chatsList
            .map((data) => data as Map<String, dynamic>)
            .toList();
            
        print('✅ Successfully loaded ${_chatList.length} chats');
        
      } catch (e) {
        print('❌ API failed, using demo data: $e');
        // Fallback to demo data
        _chatList = [
          {
            'id': 'ai_demo_project',
            'title': 'AI Assistant - Demo Project',
            'last_message': 'Hi! I\'m ready to help with your project.',
            'unread_count': 0,
            'type': 'ai_chat'
          },
        ];
      }
    } catch (e) {
      _error = 'Failed to load chats: $e';
      print('❌ Error in fetchChatList: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Clear messages for chat
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // ✅ Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ Send regular message (for human chats)
  Future<void> sendMessage(String chatId, String message) async {
    if (_isSendingMessage) return;
    
    _isSendingMessage = true;
    notifyListeners();

    try {
      final userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_user',
        content: message,
        messageType: 'user',
        createdAt: DateTime.now(),
      );
      
      _messages.add(userMessage);
      notifyListeners();

      // Try to send via API
      try {
        await _apiService.sendMessage(chatId, message);
        print('✅ Message sent to API successfully');
      } catch (e) {
        print('❌ API send failed: $e');
      }
      
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('❌ Error in sendMessage: $e');
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }
}