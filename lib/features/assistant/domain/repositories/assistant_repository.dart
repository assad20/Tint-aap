import '../../../../core/models/chat_message_model.dart';
import '../../../../core/models/product_model.dart';

// ردّ المستشار: نصّ + منتجات موصى بها (قد تكون فارغة).
class AssistantReply {
  const AssistantReply({required this.answer, this.products = const []});

  final String answer;
  final List<ProductModel> products;
}

abstract class AssistantRepository {
  Future<AssistantReply> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  });
}
