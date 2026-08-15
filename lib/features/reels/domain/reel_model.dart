import '../../../core/models/product_model.dart';

/// مقطعٌ في شريط الفيديو — **منتجٌ ومعه رابط مقطعه، لا نوعٌ مستقلّ**.
///
/// ‼️ **يحمل `ProductModel` كاملاً لا حقولاً منسوخة منه.** الشريط يحتاج ما
/// تحتاجه أيّ بطاقة: إضافةٌ للسلّة، تبديلُ مفضّلة، حدثُ قياسٍ يحمل السعر
/// والعلامة. ونسخُ الحقول كان يعني أنّ حقلاً يُضاف للبطاقة غداً (لونٌ، شارةٌ،
/// كميّة) يصل كلّ الشاشات إلّا هذه — ولا يظهر ذلك خطأً، بل ميزةً «لم تعمل هنا».
class ReelModel {
  const ReelModel({required this.product, required this.videoUrl});

  final ProductModel product;
  final String videoUrl;

  String get id => product.id;

  /// ‼️ **يُرجع `null` لا كائناً بمقطعٍ فارغ.** الترشيح يقع في الخادم، لكنّ
  /// بياناتٍ قديمة أو حقلاً حُذف يصلان بسلسلةٍ فارغة — ومشغّلٌ يُفتح على لا شيء
  /// يعرض **شاشةً سوداء بلا خطأ**، فيظنّ المشاهد التطبيق متعلّقاً.
  static ReelModel? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final url = (json['videoUrl'] ?? '').toString().trim();
    if (url.isEmpty) return null;
    final product = ProductModel.fromJson(json);
    if (product.id.isEmpty) return null;
    return ReelModel(product: product, videoUrl: url);
  }
}
