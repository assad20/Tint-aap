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
    this.promoId = '',
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

  /// هويّة المقطع الترويجيّ الثابتة — **مفتاح قياسه**.
  ///
  /// ‼️ **و[id] لا يصلح لذلك**: يُلحق به الخادم لاحقة موضعٍ حين يُذيَّل الشريط
  /// (`-at-end-N`)، ويسقط على اسم المقطع حين لا يُقرأ مُعرّفه — فإعادةُ تسمية
  /// من اللوحة تقطع سلسلة الأرقام، والمقطع الواحد يُنتج مفاتيح بعدد مواضعه.
  ///
  /// ‼️ ويبقى فارغاً على وسيطٍ أقدم لا يبثّه — فلا يُقاس، ولا ينكسر شيء.
  final String promoId;

  bool get isPromo => product == null;

  /// مفتاح القياس: مُعرّف المقطع الترويجيّ أو مُعرّف المنتج.
  ///
  /// ‼️ **واحدٌ للاثنين** كي يبقى صفّ الأرقام في اللوحة واحداً: مشاهدة ونقرة
  /// وإعجاب ومشاركة وطلب — أيّاً كان نوع المقطع. ومفتاحان مختلفان كانا يعنيان
  /// تقريرين لا يُقارَنان.
  ///
  /// ‼️ ويبقى فارغاً حين لا هويّة (وسيطٌ أقدم لا يبثّ `promoId`) — فلا يُقاس،
  /// ولا يُخلَط قياس مقطعين تحت مفتاحٍ فارغ واحد.
  String get statsKey => isPromo ? promoId : (product?.id ?? '');

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
      final promoId = (json['promoId'] ?? '').toString().trim();
      if (id.isEmpty) return null;
      return ReelModel._(
        id: id,
        promoId: promoId,
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
