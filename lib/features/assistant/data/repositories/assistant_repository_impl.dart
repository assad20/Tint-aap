import '../../../../core/models/chat_message_model.dart';
import '../../../../core/models/product_model.dart';
import '../datasources/assistant_remote_data_source.dart';
import '../../domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({
    required AssistantRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AssistantRemoteDataSource _remoteDataSource;

  @override
  Future<AssistantReply> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  }) async {
    try {
      final response = await _remoteDataSource.sendMessage(
        message: message,
        history: history,
      );
      // ‼️ الوسيط يُرجع الحقل `answer` (لا `reply`). نقرأ answer أوّلاً مع تراجع آمن.
      final answer = response['answer']?.toString() ??
          response['reply']?.toString() ??
          'أفهم طلبك، وأوصيك بالبدء بالقسم الأقرب لاحتياجك الحالي مع تنسيق الألوان والإكسسوارات المناسبة ✨';
      final products = _parseProducts(response['products']);
      return AssistantReply(answer: answer, products: products);
    } catch (_) {
      return const AssistantReply(
        answer:
            'أرشح لكِ تنسيقًا عمليًا: اختاري قطعة أساسية واحدة ثم أضيفي إكسسوارًا ناعمًا وعطرًا خفيفًا ليكتمل اللوك ✨',
      );
    }
  }

  // بطاقات الخادم: {id, slug, name, nameEn, price, oldPrice, image, sku, barcode}.
  List<ProductModel> _parseProducts(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((j) {
      double? toNum(dynamic v) => v == null ? null : double.tryParse(v.toString());
      return ProductModel(
        id: (j['slug'] ?? j['id'] ?? '').toString(),
        brand: (j['nameEn'] ?? '').toString(),
        title: (j['name'] ?? '').toString(),
        price: toNum(j['price']) ?? 0,
        oldPrice: toNum(j['oldPrice']),
        image: (j['image'] ?? '').toString(),
        category: '',
        sku: j['sku']?.toString(),
        barcode: j['barcode']?.toString(),
      );
    }).toList();
  }
}
