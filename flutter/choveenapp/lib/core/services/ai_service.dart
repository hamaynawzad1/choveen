// lib/core/services/ai_service.dart
import 'dart:convert';
import 'dart:math';

class AIService {
  // Singleton pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize AI service
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      print('✅ AI Service initialized successfully');
    } catch (e) {
      _isInitialized = false;
      print('❌ AI Service initialization failed: $e');
    }
  }

  // ✅ Get Smart AI Response with context awareness
  Future<String> getSmartAIResponse({
    required String message,
    String? projectTitle,
    String? projectContext,
    List<String>? userSkills,
    String? conversationHistory,
  }) async {
    try {
      // Simulate AI processing delay
      await Future.delayed(const Duration(milliseconds: 1500));

      final msgLower = message.toLowerCase();
      final skills = userSkills ?? ['Programming', 'Development'];
      final project = projectTitle ?? 'Your Project';
      
      // Context-aware intelligent responses
      if (_containsGreeting(msgLower)) {
        return _generateGreetingResponse(project, skills);
      }
      
      if (_containsPlanningKeywords(msgLower)) {
        return _generatePlanningResponse(project, skills);
      }
      
      if (_containsTechnicalKeywords(msgLower)) {
        return _generateTechnicalResponse(project, skills);
      }
      
      if (_containsHelpKeywords(msgLower)) {
        return _generateHelpResponse(project);
      }
      
      if (_containsTeamKeywords(msgLower)) {
        return _generateTeamResponse(project);
      }
      
      if (_containsTestingKeywords(msgLower)) {
        return _generateTestingResponse(project, skills);
      }
      
      if (_containsDeploymentKeywords(msgLower)) {
        return _generateDeploymentResponse(project, skills);
      }
      
      // Default intelligent response
      return _generateDefaultResponse(project, message, skills);
      
    } catch (e) {
      print('❌ AI Service error: $e');
      return _generateFallbackResponse(message);
    }
  }

  // ✅ Generate Project Suggestions
  Future<List<Map<String, dynamic>>> generateProjectSuggestions({
    required List<String> userSkills,
    List<String>? interests,
    String difficulty = 'intermediate',
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final suggestions = <Map<String, dynamic>>[];
      final random = Random();
      
      // Base project templates based on skills
      final projectTemplates = _getProjectTemplates(userSkills, difficulty);
      
      for (int i = 0; i < min(5, projectTemplates.length); i++) {
        final template = projectTemplates[i];
        suggestions.add({
          'id': 'ai_proj_${random.nextInt(10000)}',
          'title': template['title'],
          'description': template['description'],
          'required_skills': userSkills.take(3).toList(),
          'category': template['category'],
          'difficulty': difficulty,
          'estimated_duration': template['duration'],
          'match_score': (0.9 - (i * 0.1)).clamp(0.5, 1.0),
          'ai_generated': true,
        });
      }
      
      return suggestions;
      
    } catch (e) {
      print('❌ AI Service error generating suggestions: $e');
      return _getFallbackSuggestions(userSkills, difficulty);
    }
  }

  // ✅ Keyword Detection Methods
  bool _containsGreeting(String msg) {
    return msg.contains(RegExp(r'\b(hello|hi|hey|greetings|سڵاو|سلام)\b'));
  }

  bool _containsPlanningKeywords(String msg) {
    return msg.contains(RegExp(r'\b(plan|planning|organize|roadmap|strategy|schedule)\b'));
  }

  bool _containsTechnicalKeywords(String msg) {
    return msg.contains(RegExp(r'\b(code|coding|programming|development|technical|bug|error|implementation)\b'));
  }

  bool _containsHelpKeywords(String msg) {
    return msg.contains(RegExp(r'\b(help|stuck|problem|issue|challenge|difficult)\b'));
  }

  bool _containsTeamKeywords(String msg) {
    return msg.contains(RegExp(r'\b(team|collaborate|members|communication|meeting)\b'));
  }

  bool _containsTestingKeywords(String msg) {
    return msg.contains(RegExp(r'\b(test|testing|quality|bug|debugging|qa)\b'));
  }

  bool _containsDeploymentKeywords(String msg) {
    return msg.contains(RegExp(r'\b(deploy|deployment|production|launch|release)\b'));
  }

  // ✅ Response Generation Methods
  String _generateGreetingResponse(String project, List<String> skills) {
    final skillsText = skills.take(3).join(', ');
    return '''👋 **Hello! Welcome to your AI Project Assistant**

I'm excited to help you build **$project**! I can see you have great skills in **$skillsText**.

🎯 **Here's how I can assist you today:**

**Project Planning**
• Break down your project into manageable phases
• Create realistic timelines and milestones
• Suggest best development practices

**Technical Guidance**
• Code architecture recommendations
• Technology stack suggestions
• Problem-solving support

**Team Collaboration**
• Workflow optimization
• Communication strategies
• Task management tips

What aspect of your project would you like to focus on first?''';
  }

  String _generatePlanningResponse(String project, List<String> skills) {
    return '''📋 **Smart Project Planning for $project**

🚀 **Recommended Development Phases:**

**Phase 1: Foundation** (Week 1-2)
• Define project requirements clearly
• Set up development environment
• Create basic project structure
• Plan database schema (if needed)

**Phase 2: Core Development** (Week 3-6)
• Implement main features step by step
• Build user interface components
• Add authentication & user management
• Create API endpoints & data handling

**Phase 3: Enhancement** (Week 7-8)
• Add advanced features
• Improve user experience
• Performance optimization
• Error handling & validation

**Phase 4: Finalization** (Week 9-10)
• Comprehensive testing
• Bug fixes & improvements
• Documentation
• Deployment preparation

💡 **Given your ${skills.take(2).join(' & ')} skills, I recommend starting with the core functionality first. What specific feature would you like to tackle?**''';
  }

  String _generateTechnicalResponse(String project, List<String> skills) {
    return '''🔧 **Technical Guidance for $project**

**Architecture Recommendations:**
• Use clean, modular code structure
• Implement proper error handling
• Follow ${skills.contains('Flutter') ? 'Flutter' : skills.contains('React') ? 'React' : 'industry'} best practices
• Consider scalability from the start

**Code Quality Tips:**
• Write descriptive variable and function names
• Add comments for complex logic
• Use version control (Git) consistently
• Implement unit tests where possible

**Common Issues & Solutions:**
• **Performance**: Optimize heavy operations, use lazy loading
• **Security**: Validate all inputs, use secure authentication
• **Maintainability**: Keep functions small and focused
• **User Experience**: Add loading states and error messages

**Debugging Strategy:**
1. Reproduce the issue consistently
2. Check logs and error messages
3. Use breakpoints and debugging tools
4. Test fixes in isolation

What specific technical challenge are you facing right now?''';
  }

  String _generateHelpResponse(String project) {
    return '''🆘 **I'm here to help with $project!**

**Let's solve this together:**

**Step 1: Describe the Problem**
• What exactly isn't working?
• When does the issue occur?
• What error messages do you see?

**Step 2: Gather Information**
• What were you trying to accomplish?
• What steps led to this issue?
• Have you made recent changes?

**Step 3: Troubleshoot**
• Check for typos in code
• Verify file paths and imports
• Look at console/log output
• Test in isolation

**Step 4: Find Solutions**
• Search documentation
• Check Stack Overflow
• Try alternative approaches
• Ask for specific help

**Common Quick Fixes:**
• Restart development server
• Clear cache/storage
• Update dependencies
• Check network connectivity

Tell me more about what you're stuck on, and I'll provide specific guidance!''';
  }

  String _generateTeamResponse(String project) {
    return '''👥 **Team Collaboration for $project**

**Effective Team Communication:**

**Daily Coordination**
• 15-minute daily standup meetings
• Share what you completed yesterday
• Discuss today's goals
• Identify any blockers

**Task Management**
• Use project management tools (Trello, Asana)
• Break work into small, clear tasks
• Assign ownership and deadlines
• Track progress visually

**Code Collaboration**
• Use Git for version control
• Create feature branches
• Write clear commit messages
• Review each other's code

**Knowledge Sharing**
• Document decisions and processes
• Share useful resources
• Conduct mini-learning sessions
• Create a team wiki

**Conflict Resolution**
• Address issues early and directly
• Focus on solutions, not problems
• Listen actively to all perspectives
• Seek compromise when possible

What specific team challenge would you like help with?''';
  }

  String _generateTestingResponse(String project, List<String> skills) {
    return '''🧪 **Testing Strategy for $project**

**Testing Pyramid Approach:**

**Unit Tests (Foundation)**
• Test individual functions and components
• Quick to run and easy to debug
• Should cover core business logic
• Aim for 70-80% of your tests here

**Integration Tests (Middle)**
• Test how components work together
• Verify API endpoints and database operations
• Check user workflows
• 15-20% of your test suite

**End-to-End Tests (Top)**
• Test complete user journeys
• Verify critical business scenarios
• Use tools like Selenium or Cypress
• 5-10% of tests, focus on key features

**${skills.contains('Flutter') ? 'Flutter' : skills.contains('React') ? 'React' : 'Mobile'} Specific Testing:**
• Widget/Component testing
• UI interaction testing
• Performance testing
• Device compatibility testing

**Testing Best Practices:**
• Write tests before fixing bugs
• Keep tests simple and focused
• Use descriptive test names
• Mock external dependencies

What type of testing would you like to implement first?''';
  }

  String _generateDeploymentResponse(String project, List<String> skills) {
    return '''🚀 **Deployment Guide for $project**

**Pre-Deployment Checklist:**

**Code Quality**
• All tests passing ✅
• Code reviewed and approved ✅
• No console errors or warnings ✅
• Performance optimized ✅

**Security**
• Environment variables secured ✅
• API keys and secrets protected ✅
• Input validation implemented ✅
• HTTPS enabled ✅

**${skills.contains('Flutter') ? 'Flutter App' : skills.contains('React') ? 'Web App' : 'Application'} Deployment:**

**Flutter Mobile:**
• Build release APK/IPA
• Test on physical devices
• Upload to Play Store/App Store
• Configure app signing

**Web Application:**
• Build production bundle
• Configure CDN and caching
• Set up domain and SSL
• Deploy to hosting platform

**Backend API:**
• Set up production database
• Configure environment variables
• Deploy to cloud service
• Set up monitoring and logs

**Post-Deployment:**
• Monitor application performance
• Set up error tracking
• Collect user feedback
• Plan future updates

Which deployment platform are you considering?''';
  }

  String _generateDefaultResponse(String project, String message, List<String> skills) {
    return '''🤖 **AI Assistant for $project**

I understand you're asking about: **"$message"**

Based on your ${skills.join(', ')} skills, here are some relevant suggestions:

**Immediate Actions:**
• Break down your question into smaller parts
• Check documentation for specific APIs or frameworks
• Look for similar examples in your codebase
• Consider alternative approaches

**Resources to Explore:**
• Official documentation
• Community forums and discussions
• Video tutorials and courses
• Code examples and repositories

**Next Steps:**
• Try implementing a simple version first
• Test with sample data
• Iterate and improve gradually
• Document your learning process

💡 **For more specific help, try asking:**
• "How do I implement [specific feature]?"
• "What's the best way to handle [specific scenario]?"
• "I'm getting [specific error], how to fix it?"

What specific aspect would you like me to elaborate on?''';
  }

  String _generateFallbackResponse(String message) {
    return '''🔄 **Processing your request: "$message"**

I'm currently working on understanding your question better. While I process this, here are some general tips:

**Development Best Practices:**
• Start with small, working increments
• Test frequently as you build
• Keep your code organized and commented
• Don't hesitate to refactor when needed

**When Stuck:**
• Take a step back and review the bigger picture
• Try explaining the problem to someone else
• Look for similar solutions online
• Break complex problems into smaller parts

**Resources:**
• Documentation is your best friend
• Stack Overflow for specific issues
• GitHub for code examples
• YouTube for step-by-step tutorials

Please feel free to rephrase your question or ask about something more specific!''';
  }

  // ✅ Project Templates
  List<Map<String, dynamic>> _getProjectTemplates(List<String> skills, String difficulty) {
    final templates = <Map<String, dynamic>>[];
    
    if (skills.any((s) => s.toLowerCase().contains('flutter') || s.toLowerCase().contains('mobile'))) {
      templates.addAll([
        {
          'title': 'Personal Task Manager App',
          'description': 'A complete task management app with categories, reminders, and progress tracking',
          'category': 'Mobile Development',
          'duration': '4-6 weeks',
        },
        {
          'title': 'Social Media Dashboard',
          'description': 'Create a social media management app with posting, analytics, and user engagement features',
          'category': 'Social App',
          'duration': '6-8 weeks',
        },
      ]);
    }
    
    if (skills.any((s) => s.toLowerCase().contains('web') || s.toLowerCase().contains('react') || s.toLowerCase().contains('javascript'))) {
      templates.addAll([
        {
          'title': 'E-commerce Website',
          'description': 'Build a full-featured online store with payment integration and admin panel',
          'category': 'Web Development',
          'duration': '8-10 weeks',
        },
        {
          'title': 'Portfolio Website',
          'description': 'Create a professional portfolio showcasing your projects and skills',
          'category': 'Personal Branding',
          'duration': '2-3 weeks',
        },
      ]);
    }
    
    // Add general templates
    templates.addAll([
      {
        'title': 'Learning Management System',
        'description': 'Build a platform for online courses with video streaming and progress tracking',
        'category': 'Education Technology',
        'duration': '10-12 weeks',
      },
      {
        'title': 'Chat Application',
        'description': 'Real-time messaging app with group chats, file sharing, and notifications',
        'category': 'Communication',
        'duration': '6-8 weeks',
      },
    ]);
    
    return templates;
  }

  List<Map<String, dynamic>> _getFallbackSuggestions(List<String> skills, String difficulty) {
    return [
      {
        'id': 'fallback_1',
        'title': 'Skill-Based Project',
        'description': 'A project tailored to your ${skills.join(', ')} skills',
        'required_skills': skills.take(3).toList(),
        'category': 'Custom Development',
        'difficulty': difficulty,
        'estimated_duration': '4-6 weeks',
        'match_score': 0.8,
        'ai_generated': false,
      }
    ];
  }
}