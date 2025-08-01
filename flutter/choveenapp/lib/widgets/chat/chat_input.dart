import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;
  final String placeholder;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
    this.placeholder = 'Type a message...',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (hasText) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && !widget.isLoading) {
      widget.onSendMessage(message);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick suggestions row (when input is empty)
              if (!_hasText && !widget.isLoading)
                _buildQuickSuggestions(),
              
              const SizedBox(height: 8),
              
              // Main input row
              Row(
                children: [
                  // Attachment button
                  _buildAttachmentButton(),
                  
                  const SizedBox(width: 8),
                  
                  // Text input field
                  Expanded(
                    child: _buildTextInput(),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  _buildSendButton(),
                ],
              ),
              
              // Loading indicator
              if (widget.isLoading)
                _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      {'text': '💡 Ideas', 'message': 'Give me some project ideas'},
      {'text': '📋 Plan', 'message': 'Help me create a project plan'},
      {'text': '🔧 Tech', 'message': 'What technologies should I use?'},
      {'text': '👥 Team', 'message': 'How should I structure my team?'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => widget.onSendMessage(suggestion['message']!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  suggestion['text']!,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: IconButton(
        onPressed: _showAttachmentOptions,
        icon: Icon(
          Icons.add,
          color: Colors.grey[600],
          size: 20,
        ),
        tooltip: 'Attach file or media',
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 44,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _focusNode.hasFocus 
              ? Colors.purple.withOpacity(0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        enabled: !widget.isLoading,
        onSubmitted: (_) => _sendMessage(),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          border: InputBorder.none,
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    _focusNode.requestFocus();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                )
              : null,
        ),
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _hasText && !widget.isLoading
                  ? const LinearGradient(
                      colors: [Colors.purple, Colors.purpleAccent],
                    )
                  : null,
              color: !_hasText || widget.isLoading
                  ? Colors.grey.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(22),
              boxShadow: _hasText && !widget.isLoading
                  ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: (_hasText && !widget.isLoading) ? _sendMessage : null,
              icon: Icon(
                widget.isLoading ? Icons.hourglass_empty : Icons.send,
                color: (_hasText && !widget.isLoading) 
                    ? Colors.white 
                    : Colors.grey[500],
                size: 20,
              ),
              tooltip: widget.isLoading ? 'Sending...' : 'Send message',
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.purple.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI is thinking...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          _buildTypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_animationController.value - delay).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              height: 4 + (animationValue * 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.5 + (animationValue * 0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attach Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Photos',
                  Colors.green,
                  () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  'Documents',
                  Colors.blue,
                  () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  Icons.code,
                  'Code',
                  Colors.orange,
                  () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}