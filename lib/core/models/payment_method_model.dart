// وسيلة دفع كما يُرجعها الخادم من /catalog/payment-methods (المفعّلة فقط).
// الرسوم تأتي من الخادم ولا يخترعها التطبيق — لأنّ الخادم يعيد حساب الإجماليّ
// ويرفض أيّ اختلاف، فلا بدّ أن يتطابق ما نعرضه مع ما يحسبه.
class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.label,
    this.description,
    this.fee = 0,
    this.publicKey,
    this.merchantCode,
  });

  final String id;
  final String label;
  final String? description;
  final double fee;

  /// اعتمادات تابي العامّة — من الخادم لا من `dart-define`.
  ///
  /// تثبيتها لحظة البناء يعني نسخةً جديدة على المتجر عند كلّ تبديل مفتاح،
  /// وانتقالاً من الرمل إلى الإنتاج ببناءٍ ومراجعة. وكلاهما عامّ بطبيعته:
  /// المفتاح يُستعمل في ودجت تابي، ورمز المتجر يظهر في رابط الدفع نفسه.
  final String? publicKey;
  final String? merchantCode;

  bool get isCod => id == 'cod';
  bool get hasFee => fee > 0;

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString(),
      fee: double.tryParse(json['fee']?.toString() ?? '') ?? 0,
      publicKey: json['publicKey']?.toString(),
      merchantCode: json['merchantCode']?.toString(),
    );
  }
}
