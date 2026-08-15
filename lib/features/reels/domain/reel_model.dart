import '../../../core/models/product_model.dart';

/// شريحةٌ في شريط الفيديو — **منتجٌ أو مقطعٌ ترويجيّ**.
///
/// ‼️ **نوعٌ واحد بحالتين لا نوعان.** الشريط يُمرّرهما في `PageView` واحد،
/// ويشغّلهما بمشغّلٍ واحد، ويقيسهما بالمنطق نفسه. وفصلُهما إلى نوعين كان يعني
/// شرطاً في كلّ موضع يلمس الشريحة — ونسيانَ أحدها يُسقط الشاشة عند أوّل مقطع
/// ترويجيّ يمرّ.
class ReelModel {
  const ReelModel._({
    required this.videoUrl,
    required this.poster,
    this.product,
    this.title = '',
    this.note = '',
    this.eyebrow = '',
    this.ctaLabel = '',
    this.ctaHref = '',
    this.id = '',
  });

  /// المنتج — حاضرٌ في شريحة المنتج، غائبٌ في الترويج.
  final ProductModel? product;

  final String videoUrl;
  final String poster;

  /// حقول الترويج — تُقرأ حين لا يكون هناك منتج.
  final String title;
  final String note;
  final String eyebrow;
  final String ctaLabel;
  final String ctaHref;
  final String id;

  bool get isPromo => product == null;

  String get key => product?.id ?? id;

  /// ‼️ **يُرجع `null` لا كائناً بمقطعٍ فارغ.** الترشيح يقع في الخادم، لكنّ
  /// بياناتٍ قديمة أو حقلاً حُذف يصلان بسلسلةٍ فارغة — ومشغّلٌ يُفتح على لا شيء
  /// يعرض **شاشةً سوداء بلا خطأ**، فيظنّ المشاهد التطبيق متعلّقاً.
  static ReelModel? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final url = (json['videoUrl'] ?? '').toString().trim();
    if (url.isEmpty) return null;

    // ‼️ الافتراضُ منتجٌ عند غياب `kind`: ردود الخادم الأقدم لا تحمله، وقراءتها
    //    ترويجاً تُسقط كلّ منتجاتها من الشريط.
    final isPromo = json['kind'] == 'promo';

    if (isPromo) {
      final id = (json['id'] ?? '').toString().trim();
      if (id.isEmpty) return null;
      return ReelModel._(
        id: id,
        videoUrl: url,
        poster: (json['image'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
        eyebrow: (json['eyebrow'] ?? '').toString(),
        ctaLabel: (json['ctaLabel'] ?? '').toString(),
        ctaHref: (json['ctaHref'] ?? '').toString(),
      );
    }

    final product = ProductModel.fromJson(json);
    if (product.id.isEmpty) return null;
    return ReelModel._(
      product: product,
      videoUrl: url,
      poster: product.image,
      title: product.title,
    );
  }
}
