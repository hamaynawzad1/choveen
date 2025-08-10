import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool? isCurrentUser; // ✅ FIXED: Added for compatibility
  final bool? isAI; // ✅ FIXED: Added for AI detection
  final bool? showAvatar; // ✅ FIXED: Added for avatar control

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isCurrentUser, // ✅ FIXED: Optional parameter
    this.isAI,
    this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Determine message properties
    final bool isCurrentUserMessage = isCurrentUser ?? isMe;
    final bool isAIMessage = isAI ?? message.isAI;
    final bool shouldShowAvatar = showAvatar ?? true;

    return Container(
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isCurrentUserMessage ? 50 : 0,
        right: isCurrentUserMessage ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUserMessage && shouldShowAvatar) _buildAvatarSection(isAIMessage),
          if (!isCurrentUserMessage && shouldShowAvatar) const SizedBox(width: 8),
          Flexible(child: _buildMessageBubble(context, isCurrentUserMessage, isAIMessage)),
          if (isCurrentUserMessage && shouldShowAvatar) const SizedBox(width: 8),
          if (isCurrentUserMessage && shouldShowAvatar) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(bool isAI) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isAI 
                ? const LinearGradient(
                    colors: [Colors.purple, Colors.purpleAccent],
                  )
                : const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isAI ? Icons.psychology : Icons.person,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isCurrentUser, bool isAI) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser 
              ? Colors.blue 
              : (isAI ? Colors.grey[50] : Colors.white),
          border: isAI 
              ? Border.all(color: Colors.purple.withOpacity(0.2), width: 1)
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
            bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAI) _buildAIHeader(),
            Padding(
              padding: EdgeInsets.all(isAI ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI)
                    _buildFormattedAIContent()
                  else
                    _buildRegularMessage(isCurrentUser),
                  const SizedBox(height: 6),
                  _buildMessageFooter(isCurrentUser),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.purple, size: 16),
          const SizedBox(width: 6),
          const Text(
            'AI Assistant',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Online',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAIContent() {
    return _buildMarkdownContent(message.content);
  }

  Widget _buildMarkdownContent(String content) {
    // Simple markdown parsing for AI responses
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Headers
      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line.substring(2, line.length - 2),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ));
      }
      // Bullet points
      else if (line.startsWith('• ') || line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      // Numbered sections
      else if (RegExp(r'^\*\*\d+\.').hasMatch(line)) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            line.replaceAll('**', ''),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ));
      }
      // Emoji headers
      else if (RegExp(r'^[🎯🔧👥📊💡🚀📋🤖✅❌⚡].+').hasMatch(line) && line.contains('**')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line.replaceAll('**', ''),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
        ));
      }
      // Regular text
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            line,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRegularMessage(bool isCurrentUser) {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 15,
        color: isCurrentUser ? Colors.white : Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildMessageFooter(bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: isCurrentUser ? Colors.white70 : Colors.grey[600],
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.done_all,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time only
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            if (message.senderId == 'ai_assistant')
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Regenerate Response'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Regenerating response...')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}