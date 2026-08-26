import 'product_model.dart';

/// نتيجة مسح رمزٍ من الكاميرا.
///
/// ‼️ **ثلاث حالاتٍ لا اثنتان** — والثالثة هي التي تُنسى.
///
/// أسهل ما يُكتَب `Future<ProductModel?>`: منتجٌ أو `null`. لكنّ `null` يخلط
/// **«لا نبيع هذا»** بـ**«الشبكة انقطعت»**، وهما لا يشتركان في شيء: الأولى
/// جوابٌ نهائيٌّ صحيح يُنهي المسح، والثانية عارضٌ تُعاد المحاولة بعده. وخلطُهما
/// يعني إمّا أن نقول لمن انقطعت شبكته «هذا المنتج غير موجود» — وهو كذبٌ يجعله
/// يترك متجرنا ويشتريه من غيرنا — أو أن نعرض «أعِد المحاولة» لمن مسح علبة
/// شامبو لا نبيعها، فيُعيد ويُعيد بلا طائل.
sealed class BarcodeLookup {
  const BarcodeLookup();
}

/// وُجد المنتج — يُفتَح مباشرةً بلا شاشة نتائج.
class BarcodeFound extends BarcodeLookup {
  const BarcodeFound(this.product);
  final ProductModel product;
}

/// رمزٌ صحيحٌ لا يقابله منتجٌ في المتجر (`404`).
class BarcodeUnknown extends BarcodeLookup {
  const BarcodeUnknown(this.code);
  final String code;
}

/// تعذّر السؤال — شبكةٌ أو خادم. **قابلٌ لإعادة المحاولة.**
class BarcodeFailed extends BarcodeLookup {
  const BarcodeFailed(this.message);
  final String message;
}
