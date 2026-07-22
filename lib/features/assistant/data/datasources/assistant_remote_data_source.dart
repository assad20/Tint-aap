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
        // الخادم يقبل {role, content} فقط (تحقّق صارم forbidNonWhitelisted).
        // إرسال createdAt الزائد كان يسبّب 400 فيقع الردّ على التراجع الاحتياطيّ.
        'history': history
            .map((item) => {'role': item.role.name, 'content': item.content})
            .toList(),
      },
    );
  }
}
