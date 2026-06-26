import '../../../../core/models/chat_message_model.dart';

abstract class AssistantRepository {
  Future<String> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  });
}
