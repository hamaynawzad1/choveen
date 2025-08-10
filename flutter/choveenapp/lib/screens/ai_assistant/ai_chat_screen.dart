import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../models/message_model.dart';

class AIChatScreen extends StatefulWidget {
  final Project project;

  const AIChatScreen({super.key, required this.project});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    _addMessage(Message(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'ai_assistant',
      content: "Hello! I'm your AI assistant for the '${widget.project.title}' project. I'm here to help you with:\n\n• Project planning and strategy\n• Technical guidance and best practices\n• Team collaboration tips\n• Problem-solving support\n\nWhat would you like to discuss about your project?",
      messageType: 'ai',
      createdAt: DateTime.now(),
      projectId: widget.project.id,
    ));
  }

  void _addMessage(Message message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    // Add user message
    final userMessage = Message(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      senderId: user.id,
      content: content.trim(),
      messageType: 'user',
      createdAt: DateTime.now(),
      projectId: widget.project.id,
    );
    _addMessage(userMessage);

    // Show loading
    setState(() {
      _isLoading = true;
    });

    // Simulate AI response
    await Future.delayed(const Duration(seconds: 2));

    // Generate AI response
    final aiResponse = _generateAIResponse(content);
    final aiMessage = Message(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'ai_assistant',
      content: aiResponse,
      messageType: 'ai',
      createdAt: DateTime.now(),
      projectId: widget.project.id,
    );

    setState(() {
      _isLoading = false;
    });
    _addMessage(aiMessage);
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    final projectTitle = widget.project.title;
    final skills = widget.project.requiredSkills;

    // Context-aware responses based on project and message content
    if (message.contains('help') || message.contains('how')) {
      return """**🤖 I'm here to help with '$projectTitle'!**

Here are some ways I can assist you:

**🎯 Project Planning:**
• Break down tasks into manageable components
• Create timeline and milestone suggestions
• Identify potential risks and solutions

**🔧 Technical Guidance:**
• Best practices for ${skills.isNotEmpty ? skills.first : 'development'}
• Architecture recommendations
• Code review and optimization tips

**👥 Team Collaboration:**
• Role assignment strategies
• Communication workflows
• Progress tracking methods

What specific area would you like to dive into first?""";
    }

    if (message.contains('plan') || message.contains('start')) {
      return """**📋 Let's create a plan for '$projectTitle'!**

**Phase 1: Foundation (Week 1-2)**
• Project setup and environment configuration
• Team role assignments
• Initial architecture design
• Technology stack finalization

**Phase 2: Core Development (Week 3-6)**
• Core feature implementation
• ${skills.isNotEmpty ? skills.take(2).join(' and ') : 'Key functionality'} development
• Regular testing and code reviews
• Progress check-ins

**Phase 3: Integration & Testing (Week 7-8)**
• Feature integration
• Comprehensive testing
• Bug fixes and optimizations
• Documentation updates

**Phase 4: Launch Preparation (Week 9-10)**
• Final testing and validation
• Deployment preparation
• Launch strategy execution

Would you like me to elaborate on any specific phase?""";
    }

    if (message.contains('tech') || message.contains('technology')) {
      return """**🔧 Technology Recommendations for '$projectTitle':**

**Based on your project requirements:**

**Core Technologies:**
${skills.map((skill) => '• $skill - Essential for project success').join('\n')}

**Development Tools:**
• Version Control: Git with GitHub/GitLab
• Project Management: Trello, Jira, or Asana
• Communication: Slack or Discord
• Documentation: Notion or Confluence

**Best Practices:**
• Follow clean code principles
• Implement proper testing strategies
• Use continuous integration/deployment
• Regular code reviews and pair programming

**Architecture Patterns:**
• Modular design for scalability
• Separation of concerns
• API-first approach if applicable

Need specific guidance on any of these technologies?""";
    }

    if (message.contains('team') || message.contains('member')) {
      return """**👥 Team Structure for '$projectTitle':**

**Recommended Roles:**
• **Project Manager**: Overall coordination and timeline management
• **Lead Developer**: Technical leadership and architecture decisions
• **${skills.isNotEmpty ? skills.first : 'Core'} Specialist**: Primary skill implementation
• **QA/Tester**: Quality assurance and testing
• **Designer**: UI/UX design (if applicable)

**Team Collaboration Tips:**
• Daily standup meetings (15 minutes max)
• Weekly sprint planning sessions
• Regular retrospectives for continuous improvement
• Clear communication channels

**Task Distribution:**
• Break work into 2-4 hour chunks
• Assign based on individual strengths
• Ensure knowledge sharing across team
• Maintain backup expertise for critical areas

**Current Project Needs:**
Based on '${widget.project.title}', you'll especially need expertise in: ${skills.take(3).join(', ')}

How many team members are you planning to work with?""";
    }

    if (message.contains('problem') || message.contains('stuck') || message.contains('issue')) {
      return """**🚨 Problem-Solving Support for '$projectTitle':**

**Debugging Strategy:**
1. **Identify the Issue**: Clearly define what's not working
2. **Reproduce**: Create consistent steps to trigger the problem
3. **Isolate**: Narrow down to specific components
4. **Research**: Check documentation and community resources
5. **Test Solutions**: Try fixes incrementally

**Common Project Challenges:**
• **Technical Debt**: Regular refactoring sessions
• **Scope Creep**: Clear requirements documentation
• **Team Communication**: Established protocols
• **Timeline Pressure**: Realistic milestone setting

**Quick Wins:**
• Break large problems into smaller ones
• Rubber duck debugging with team members
• Take breaks to gain fresh perspective
• Document solutions for future reference

**For '${widget.project.title}' specifically:**
Consider the ${skills.isNotEmpty ? skills.first : 'main technology'} best practices and community solutions.

What specific challenge are you facing right now?""";
    }

    // Default responses for general queries
    final defaultResponses = [
      """**Great question about '$projectTitle'!**

I'd love to help you with this project. Here's what I can assist with:

**🎯 Project Management:**
• Timeline and milestone planning
• Resource allocation
• Risk assessment and mitigation

**💡 Technical Insights:**
• Best practices for ${skills.isNotEmpty ? skills.first : 'your technology stack'}
• Architecture and design patterns
• Performance optimization tips

**🤝 Team Coordination:**
• Effective collaboration strategies
• Role and responsibility definition
• Communication workflows

Could you tell me more about what specific aspect you'd like to focus on?""",

      """**Excellent! Let's dive into '$projectTitle'.**

**Current Project Overview:**
• **Skills Required**: ${skills.join(', ')}
• **Status**: ${widget.project.status}
• **Focus Area**: ${widget.project.category}

**Next Steps I Recommend:**
1. **Define Clear Objectives**: What's the main goal?
2. **Plan MVP Features**: What's the minimum viable version?
3. **Set Up Development Environment**: Get everyone on the same tools
4. **Create Project Timeline**: Realistic milestones and deadlines

**Questions to Consider:**
• What's your target audience or use case?
• What's your biggest technical challenge?
• How can I help make this project successful?

What would you like to tackle first?""",

      """**I'm excited to help with '$projectTitle'!**

**Project Strengths:**
• Strong skill set: ${skills.take(3).join(', ')}
• Clear project scope and objectives
• Good foundation for ${widget.project.category}

**Areas I Can Support:**
• **Planning**: Break down complex tasks
• **Development**: Share best practices and tips
• **Problem-Solving**: Debug issues and find solutions
• **Optimization**: Performance and code quality

**Let's Get Practical:**
• What's working well so far?
• Where do you need the most support?
• What are your immediate priorities?

Feel free to ask me anything about development, planning, or team coordination!"""
    ];

    final randomIndex = DateTime.now().millisecond % defaultResponses.length;
    return defaultResponses[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Assistant', style: TextStyle(fontSize: 18)),
            Text(
              widget.project.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showProjectInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Project Context Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.purple.shade50,
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Assistant Context',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Helping with: ${widget.project.category} • ${widget.project.requiredSkills.take(2).join(', ')}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: _messages.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.senderId == user?.id;

                      return MessageBubble(
                        message: message,
                        isMe: isUser,
                        isCurrentUser: isUser,
                        isAI: message.isAI,
                        showAvatar: true,
                      );
                    },
                  ),
          ),

          // Typing Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.psychology, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('AI is thinking...', style: TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade300),
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: ChatInput(
              onSendMessage: _sendMessage,
              hintText: 'Ask AI about your project...',
              enabled: !_isLoading,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 64, color: Colors.purple.shade200),
          const SizedBox(height: 16),
          Text(
            'AI Assistant Ready!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about "${widget.project.title}"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('How do I start?', '💡'),
                _buildSuggestionChip('Create a plan', '📋'),
                _buildSuggestionChip('Tech advice', '🔧'),
                _buildSuggestionChip('Team tips', '👥'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, String emoji) {
    return InkWell(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.project.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.project.description),
              const SizedBox(height: 16),
              Text(
                'Required Skills:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.project.requiredSkills
                    .map((skill) => Chip(
                          label: Text(skill),
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: Colors.purple,
                            fontSize: 12,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Category: ${widget.project.category}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Status: ${widget.project.status}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}