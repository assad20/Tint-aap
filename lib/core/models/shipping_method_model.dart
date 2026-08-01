/// طريقة شحن كما يُرجعها الخادم من `/catalog/shipping-methods`.
///
/// كان التطبيق يكتب الطرق وأسعارها في شيفرته (`aramex` بـ25 و`smsa` مجّاناً)
/// بينما يعرف الخادم `standard` و`express` — فيسقط على أوّل طريقةٍ عنده ويحسب
/// شحناً مختلفاً، ثمّ يرفض الطلب لأنّ إجماليّه أعلى ممّا أرسله العميل.
class ShippingMethodModel {
  const ShippingMethodModel({
    required this.id,
    required this.label,
    this.price = 0,
    this.freeOverThreshold = 0,
    this.etaMinDays,
    this.etaMaxDays,
  });

  final String id;
  final String label;
  final double price;

  /// عتبة الشحن المجّانيّ (0 = لا عتبة).
  final double freeOverThreshold;

  final int? etaMinDays;
  final int? etaMaxDays;

  /// كلفة الشحن لسلّةٍ بهذا المجموع — نسخةٌ طبق الأصل من `resolveShipping`
  /// على الخادم. أيّ اختلافٍ هنا يعني رفض الطلب.
  double costFor(double subtotal) {
    if (freeOverThreshold > 0 && subtotal >= freeOverThreshold) return 0;
    return price < 0 ? 0 : price;
  }

  String get etaLabel {
    if (etaMinDays == null && etaMaxDays == null) return '';
    if (etaMinDays != null && etaMaxDays != null && etaMinDays != etaMaxDays) {
      return 'التوصيل خلال $etaMinDays-$etaMaxDays أيام عمل';
    }
    final d = etaMaxDays ?? etaMinDays;
    return 'التوصيل خلال $d أيام عمل';
  }

  factory ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    double num_(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    int? int_(dynamic v) => int.tryParse(v?.toString() ?? '');
    return ShippingMethodModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      price: num_(json['price']),
      freeOverThreshold: num_(json['freeOverThreshold']),
      etaMinDays: int_(json['etaMinDays']),
      etaMaxDays: int_(json['etaMaxDays']),
    );
  }
}
