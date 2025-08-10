import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class Message {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? projectId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  
  // ✅ FIXED: Added chatId field
  final String? chatId;

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.projectId,
    required this.content,
    this.messageType = 'user',
    required this.createdAt,
    this.chatId, // ✅ FIXED: Added chatId parameter
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  // Copy with method for easy updates
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? projectId,
    String? content,
    String? messageType,
    DateTime? createdAt,
    String? chatId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      chatId: chatId ?? this.chatId,
    );
  }

  // Helper getters
  bool get isAI => senderId == 'ai_assistant';
  bool get isUser => !isAI;
  
  // Get chat identifier - uses chatId if available, otherwise projectId
  String? get conversationId => chatId ?? projectId;

  @override
  String toString() {
    return 'Message{id: $id, senderId: $senderId, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}..., messageType: $messageType}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}