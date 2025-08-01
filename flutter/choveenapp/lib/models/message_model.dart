// lib/models/message_model.dart
class Message {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? projectId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.projectId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.metadata,
  });

  // ✅ Factory constructor from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      receiverId: json['receiver_id'] ?? json['receiverId'],
      projectId: json['project_id'] ?? json['projectId'],
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? json['messageType'] ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // ✅ Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'project_id': projectId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_read': isRead,
      'metadata': metadata,
    };
  }

  // ✅ Copy with modifications
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? projectId,
    String? content,
    String? messageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  // ✅ Convenience getters
  bool get isAI => senderId == 'ai_assistant' || messageType == 'ai';
  bool get isUser => messageType == 'user';
  bool get isSystem => messageType == 'system';
  
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get shortContent {
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  // ✅ Message validation
  bool get isValid {
    return id.isNotEmpty && 
           senderId.isNotEmpty && 
           content.isNotEmpty &&
           messageType.isNotEmpty;
  }

  // ✅ Equality and hashCode
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
           other.id == id &&
           other.senderId == senderId &&
           other.content == content &&
           other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           senderId.hashCode ^ 
           content.hashCode ^ 
           createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, messageType: $messageType, content: ${shortContent})';
  }
}

// ✅ Message type enum
enum MessageType {
  user('user'),
  ai('ai'),
  system('system'),
  notification('notification');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.user,
    );
  }
}

// ✅ Message status enum
enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}