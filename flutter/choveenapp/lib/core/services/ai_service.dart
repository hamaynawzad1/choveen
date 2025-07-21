// lib/core/services/enhanced_ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class EnhancedAIService {
  static final EnhancedAIService _instance = EnhancedAIService._internal();
  factory EnhancedAIService() => _instance;
  EnhancedAIService._internal();
  
  final StorageService _storage = StorageService();
  
  // AI Providers (you can get free API keys)
  static const String OPENAI_API_KEY = 'YOUR_OPENAI_KEY'; // Get from openai.com
  static const String COHERE_API_KEY = 'YOUR_COHERE_KEY'; // Get from cohere.ai (free tier)
  static const String ANTHROPIC_API_KEY = 'YOUR_CLAUDE_KEY'; // Get from anthropic.com
  
  // ✅ Smart AI Response with fallback
  Future<String> getSmartAIResponse({
    required String message,
    String? projectTitle,
    String? projectContext,
    List<String>? userSkills,
  }) async {
    try {
      // Try primary AI first
      final response = await _tryPrimaryAI(message, projectTitle, projectContext);
      if (response != null) return response;
      
      // Try secondary AI
      final secondaryResponse = await _trySecondaryAI(message, projectTitle);
      if (secondaryResponse != null) return secondaryResponse;
      
      // Use smart fallback
      return _generateSmartFallback(message, projectTitle, projectContext, userSkills);
      
    } catch (e) {
      print('AI Service Error: $e');
      return _generateSmartFallback(message, projectTitle, projectContext, userSkills);
    }
  }
  
  // ✅ Try primary AI (Cohere - Free tier available)
  Future<String?> _tryPrimaryAI(String message, String? projectTitle, String? context) async {
    if (COHERE_API_KEY == 'YOUR_COHERE_KEY') return null;
    
    try {
      final prompt = _buildPrompt(message, projectTitle, context);
      
      final response = await http.post(
        Uri.parse('https://api.cohere.ai/v1/generate'),
        headers: {
          'Authorization': 'Bearer $COHERE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'command',
          'prompt': prompt,
          'max_tokens': 300,
          'temperature': 0.7,
          'k': 0,
          'stop_sequences': [],
          'return_likelihoods': 'NONE'
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['generations']?[0]?['text']?.trim();
      }
      
      return null;
    } catch (e) {
      print('Cohere AI Error: $e');
      return null;
    }
  }
  
  // ✅ Try secondary AI (Your backend)
  Future<String?> _trySecondaryAI(String message, String? projectTitle) async {
    try {
      final token = await _storage.getToken();
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
          'project_title': projectTitle ?? 'Project',
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'];
      }
      
      return null;
    } catch (e) {
      print('Backend AI Error: $e');
      return null;
    }
  }
  
  // ✅ Smart context-aware prompt building
  String _buildPrompt(String message, String? projectTitle, String? context) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an AI assistant helping with a project management app called Choveen.');
    
    if (projectTitle != null) {
      buffer.writeln('Current project: "$projectTitle"');
    }
    
    if (context != null) {
      buffer.writeln('Project context: $context');
    }
    
    buffer.writeln('\nUser message: $message');
    buffer.writeln('\nProvide a helpful, specific response focused on the project:');
    
    return buffer.toString();
  }
  
  // ✅ Enhanced smart fallback system
  String _generateSmartFallback(
    String message, 
    String? projectTitle, 
    String? context,
    List<String>? userSkills,
  ) {
    final msgLower = message.toLowerCase();
    final project = projectTitle ?? 'your project';
    
    // Context-aware responses
    final responses = <String, String>{
      // Greetings
      r'(hi|hello|hey|start|سڵاو|سلاو)': '''
👋 Hello! I'm your AI assistant for $project.

I can help you with:
• Project planning and roadmaps
• Task breakdown and prioritization  
• Technical guidance for: ${userSkills?.join(', ') ?? 'your skills'}
• Team collaboration strategies
• Best practices and optimization

What would you like to work on today?
''',

      // Project planning
      r'(plan|planning|roadmap|timeline|strategy)': '''
📋 Let's create a solid plan for $project!

**Project Planning Framework:**

1. **Define Objectives** 🎯
   - What problem are we solving?
   - Who is our target audience?
   - What's our success criteria?

2. **Break Down Phases** 📊
   - Phase 1: Foundation (2-3 weeks)
   - Phase 2: Core Features (4-6 weeks)
   - Phase 3: Polish & Testing (2 weeks)
   - Phase 4: Launch & Iterate

3. **Task Prioritization** ⚡
   - Must Have (P0): Core functionality
   - Should Have (P1): Important features
   - Nice to Have (P2): Enhancements

4. **Resource Allocation** 👥
   - Assign tasks based on skills
   - Set realistic deadlines
   - Plan for reviews

Which phase should we detail first?
''',

      // Technical help
      r'(code|bug|error|technical|implement|develop)': '''
🔧 I'll help you solve technical challenges in $project.

**Debugging Approach:**

1. **Identify the Issue** 🔍
   - What's the expected behavior?
   - What's actually happening?
   - Any error messages?

2. **Isolate the Problem** 🎯
   - Which component is affected?
   - When did it start?
   - What changed recently?

3. **Solution Strategy** 💡
   - Quick fixes vs. proper solutions
   - Performance implications
   - Future maintainability

Share your specific technical challenge, and I'll provide targeted solutions!
''',

      // Team collaboration
      r'(team|collaborate|member|communication|work together)': '''
👥 Effective team collaboration for $project:

**Team Success Framework:**

1. **Communication Channels** 💬
   - Daily standups (15 min)
   - Weekly planning sessions
   - Async updates in chat
   - Code review process

2. **Task Management** 📝
   - Clear task descriptions
   - Defined acceptance criteria
   - Regular progress updates
   - Blocker identification

3. **Collaboration Tools** 🛠️
   - Version control (Git)
   - Project boards (Kanban)
   - Documentation (Wiki)
   - Design handoffs

4. **Team Culture** 🌟
   - Celebrate wins
   - Learn from failures
   - Share knowledge
   - Support each other

What aspect of team collaboration needs attention?
''',

      // Getting started
      r'(start|begin|how to|first step|get started)': '''
🚀 Let's get $project started the right way!

**Quick Start Guide:**

1. **Setup Phase** (Today)
   ✓ Define project goals
   ✓ List required features
   ✓ Identify team skills
   ✓ Choose tech stack

2. **Planning Phase** (This week)
   ✓ Create project structure
   ✓ Design basic wireframes
   ✓ Set up development environment
   ✓ Initialize version control

3. **Execution Phase** (Next 2 weeks)
   ✓ Build core features
   ✓ Regular testing
   ✓ Daily progress updates
   ✓ Weekly team reviews

Ready to tackle the first step? Let's define your project goals!
''',

      // Best practices
      r'(best practice|quality|standard|improve|optimize)': '''
✨ Best practices for $project success:

**Code Quality** 📝
• Write self-documenting code
• Follow consistent naming conventions
• Add meaningful comments
• Keep functions small and focused

**Development Process** 🔄
• Commit early and often
• Write descriptive commit messages
• Create feature branches
• Review before merging

**Testing Strategy** 🧪
• Write tests as you code
• Aim for 80% coverage
• Test edge cases
• Automate where possible

**Performance** ⚡
• Optimize after profiling
• Cache expensive operations
• Lazy load when appropriate
• Monitor metrics

Which area would you like to improve first?
''',

      // Help and guidance
      r'(help|guide|tutorial|learn|teach)': '''
📚 I'm here to guide you through $project!

**Learning Resources:**

1. **For Beginners** 🌱
   - Start with fundamentals
   - Follow tutorials step-by-step
   - Practice with small projects
   - Join community forums

2. **Intermediate Level** 🌿
   - Study design patterns
   - Contribute to open source
   - Build real-world projects
   - Learn from code reviews

3. **Advanced Topics** 🌳
   - System architecture
   - Performance optimization
   - Security best practices
   - Scaling strategies

What specific topic would you like to explore?
'''
    };
    
    // Find matching response
    for (final pattern in responses.keys) {
      if (RegExp(pattern).hasMatch(msgLower)) {
        return responses[pattern]!;
      }
    }
    
    // Default intelligent response
    return '''
🤖 I'm here to help with $project!

Based on your message, I can assist with:

• **Technical Solutions**: Debug issues, optimize code, implement features
• **Project Management**: Plan sprints, track progress, prioritize tasks  
• **Team Coordination**: Improve collaboration, resolve blockers
• **Best Practices**: Code quality, testing, documentation

Could you please be more specific about what you need help with? 

For example:
- "Help me plan the next sprint"
- "How do I implement user authentication?"
- "What's the best way to organize our team?"

I'm ready to provide detailed, actionable guidance! 💪
''';
  }
  
  // ✅ Generate team-based AI suggestions
  Future<List<Map<String, dynamic>>> generateTeamProjectIdeas(List<String> userSkills) async {
    final ideas = [
      {
        'title': 'Digital Creative Agency',
        'skills_needed': ['Graphic Design', 'Web Development', 'Marketing', 'Photography'],
        'description': 'Form a full-service creative agency offering branding, web design, and digital marketing',
        'team_size': 4,
      },
      {
        'title': 'E-Learning Platform Team',
        'skills_needed': ['Teaching', 'Video Editing', 'Programming', 'Content Writing'],
        'description': 'Create online courses with instructors, editors, and developers working together',
        'team_size': 5,
      },
      {
        'title': 'Mobile App Startup',
        'skills_needed': ['Flutter', 'UI/UX Design', 'Backend Development', 'Marketing'],
        'description': 'Build innovative mobile apps with a complete development and marketing team',
        'team_size': 4,
      },
      {
        'title': 'Content Production House',
        'skills_needed': ['Photography', 'Videography', 'Editing', 'Social Media'],
        'description': 'Professional content creation for brands and businesses',
        'team_size': 4,
      },
      {
        'title': 'Tech Consultancy Firm',
        'skills_needed': ['Programming', 'Project Management', 'Business Analysis', 'DevOps'],
        'description': 'Provide technical consulting and development services to businesses',
        'team_size': 5,
      }
    ];
    
    // Score and filter based on user skills
    final scoredIdeas = ideas.map((idea) {
      final requiredSkills = List<String>.from(idea['skills_needed'] as List);
      final matchCount = userSkills.where((skill) =>
        requiredSkills.any((req) => 
          skill.toLowerCase().contains(req.toLowerCase()) ||
          req.toLowerCase().contains(skill.toLowerCase())
        )
      ).length;
      
      return {
        ...idea,
        'match_score': matchCount / requiredSkills.length,
        'your_role': userSkills.first,
      };
    }).where((idea) => (idea['match_score'] as double) > 0).toList();
    
    scoredIdeas.sort((a, b) => 
      (b['match_score'] as double).compareTo(a['match_score'] as double)
    );
    
    return scoredIdeas.take(3).toList();
  }
}