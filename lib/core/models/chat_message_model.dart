enum ChatRole { user, assistant }

class ChatMessageModel {
  const ChatMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final ChatRole role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
