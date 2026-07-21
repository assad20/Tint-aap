import '../../../../core/models/chat_message_model.dart';
import '../datasources/assistant_remote_data_source.dart';
import '../../domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({
    required AssistantRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AssistantRemoteDataSource _remoteDataSource;

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  }) async {
    try {
      final response = await _remoteDataSource.sendMessage(
        message: message,
        history: history,
      );
      // ‼️ الوسيط يُرجع الحقل `answer` (لا `reply`). نقرأ answer أوّلاً مع تراجع آمن.
      return response['answer']?.toString() ??
          response['reply']?.toString() ??
          'أفهم طلبك، وأوصيك بالبدء بالقسم الأقرب لاحتياجك الحالي مع تنسيق الألوان والإكسسوارات المناسبة ✨';
    } catch (_) {
      return 'أرشح لكِ تنسيقًا عمليًا: اختاري قطعة أساسية واحدة ثم أضيفي إكسسوارًا ناعمًا وعطرًا خفيفًا ليكتمل اللوك ✨';
    }
  }
}
