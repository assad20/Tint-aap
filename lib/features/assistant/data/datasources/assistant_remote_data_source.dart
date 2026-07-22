import '../../../../app/config/api_routes.dart';
import '../../../../core/models/chat_message_model.dart';
import '../../../../core/network/api_client.dart';

class AssistantRemoteDataSource {
  AssistantRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  }) {
    return _apiClient.postMap(
      ApiRoutes.assistantChat,
      // مهلة أطول: المستشار ينتظر ردّ مزوّد الذكاء (قد يبرد) — يمنع التراجع المبكّر.
      receiveTimeout: const Duration(seconds: 45),
      data: {
        'message': message,
        'history': history.map((item) => item.toJson()).toList(),
      },
    );
  }
}
