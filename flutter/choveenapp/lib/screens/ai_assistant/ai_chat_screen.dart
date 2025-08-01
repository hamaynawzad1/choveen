// lib/screens/ai_assistant/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';

class AIChatScreen extends StatefulWidget {
  final Project project;

  const AIChatScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _sendWelcomeMessage();
    });
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.fetchMessages('ai_${widget.project.id}');
  }

  Future<void> _sendWelcomeMessage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = chatProvider.messages.where((m) => m.projectId == widget.project.id).toList();
    
    if (messages.isEmpty) {
      // Send welcome message
      await chatProvider.sendAIMessage(
        widget.project.id,
        "Welcome! I'm here to help you build your ${widget.project.title}. What would you like to know?"
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Team Advisor'),
            Text(
              widget.project.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final projectMessages = chatProvider.messages
                    .where((m) => m.projectId == widget.project.id)
                    .toList();

                if (chatProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 16),
                        Text('Loading conversation...'),
                      ],
                    ),
                  );
                }

                if (projectMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Start a conversation with AI',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about ${widget.project.title} development',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: projectMessages.length,
                  itemBuilder: (context, index) {
                    final message = projectMessages[index];
                    final isAI = message.messageType == 'ai';
                    final isUser = message.senderId == user?.id;

                    return MessageBubble(
                      message: message,
                      isCurrentUser: isUser,
                      isAI: isAI,
                      showAvatar: true,
                    );
                  },
                );
              },
            ),
          ),

          // Typing Indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.isSendingMessage) {
                return Container(
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
                );
              }
              return const SizedBox.shrink();
            },
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
              onSendMessage: (message) async {
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                await chatProvider.sendAIMessage(widget.project.id, message);
              },
              hintText: 'Ask AI about your project...',
              enabled: !Provider.of<ChatProvider>(context).isSendingMessage,
            ),
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