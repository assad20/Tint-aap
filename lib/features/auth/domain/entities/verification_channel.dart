/// قنوات إرسال رمز التحقّق — **مطابقةٌ حرفيّاً لما يقبله الخادم**.
///
/// ‼️ **والقناة تُرسَل صريحةً دائماً، لا تُترك للخادم.**
///
/// تركُها فارغة يجعله يستعمل «القناة الأساسيّة للمتجر» — فمتجرٌ أساسيّته البريد
/// يرفض من أراد واتساب ويطلب بريداً، ومتجرٌ أساسيّته واتساب يُرسل إلى جوّالٍ
/// لم يُدخله أحد. **اختيار العميل قرارٌ صريح لا يُستنتَج.** وهو نفس ما يفعله
/// الموقع، وغيابه من التطبيق هو سبب أنّ «التحقّق بواتساب» لم يكن يعمل فيه.
enum VerificationChannel {
  whatsapp,
  email;

  String get wire => name;

  String get label => switch (this) {
        VerificationChannel.whatsapp => 'واتساب',
        VerificationChannel.email => 'البريد الإلكترونيّ',
      };

  /// ‼️ **قناةٌ مجهولة تُهمَل ولا تُسقط الشاشة.** الخادم قد يُضيف قناةً
  /// (رسالة نصّيّة مثلاً) قبل أن يعرفها هذا الإصدار، وتطبيقٌ يرمي عند أوّل
  /// اسمٍ لا يعرفه يمنع الدخول كلّه لأجل خيارٍ إضافيّ.
  static VerificationChannel? tryParse(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    for (final channel in VerificationChannel.values) {
      if (channel.name == value) return channel;
    }
    return null;
  }
}

/// ‼️ **نسخةٌ طبق الأصل من `looksLikeSaudiMobile` في الموقع.**
///
/// أيّ اختلافٍ هنا يعني رقماً يقبله أحدهما ويرفضه الآخر — والعميل يقرأ
/// «رقم غير صحيح» لرقمٍ اشترى به أمس من الموقع.
///
/// وتُحوَّل الأرقام العربيّة والفارسيّة أوّلاً: لوحة المفاتيح العربيّة تكتب
/// «٠٥٥…» ورفضُها يمنع فئةً كاملة من المستخدمين بلا سبب ظاهر.
bool looksLikeSaudiMobile(String raw) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final latin = raw.split('').map((char) {
    final a = arabic.indexOf(char);
    if (a >= 0) return '$a';
    final p = persian.indexOf(char);
    if (p >= 0) return '$p';
    return char;
  }).join();

  var digits = latin.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  final local = digits.startsWith('966')
      ? digits.substring(3).replaceFirst(RegExp(r'^0'), '')
      : digits.replaceFirst(RegExp(r'^0'), '');
  return RegExp(r'^5\d{8}$').hasMatch(local);
}
