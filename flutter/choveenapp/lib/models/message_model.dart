class Message {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? projectId;
  final String content;
  final String messageType;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.projectId,
    required this.content,
    required this.messageType,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'],
      projectId: json['project_id'],
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'user',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'project_id': projectId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}