import 'package:flutter/foundation.dart';

/// إجراءٌ موحّد كما يُرسله الخادم (المهمّة 3.1): `{ "type": "...", "value": "..." }`.
///
/// ‼️ **الأنواع نصوصٌ لا `enum` مغلق.** الخادم قد يُرسل نوعاً أحدث من هذه
/// النسخة، و`enum` صارم يعني استثناءً عند التحليل يُسقط القسم كلّه. النصّ يمرّ،
/// والمُنفِّذ يتجاهل ما لا يعرف — وهو نفس مبدأ سجلّ المكوّنات.
@immutable
class SduiAction {
  const SduiAction({required this.type, required this.value});

  final String type;
  final String value;

  /// هل يستحقّ هذا الإجراء زرّاً؟ (المهمّة 0.1)
  bool get isActionable => type.isNotEmpty && type != 'none' && value.isNotEmpty;

  static SduiAction? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final type = raw['type']?.toString().trim() ?? '';
    final value = raw['value']?.toString().trim() ?? '';
    if (type.isEmpty) return null;
    return SduiAction(type: type, value: value);
  }

  /// يقرأ الإجراء من عنصرٍ يحمل `action`، **ويقع على الرابط القديم عند غيابه**.
  ///
  /// ‼️ الوقوع ضروريّ: النسخ المخزَّنة في كاش الجهاز قد تكون سابقةً لـ3.1، فلا
  /// `action` فيها. وبلا هذا الوقوع تختفي أزرار من شاشةٍ كانت تعمل حتّى يصل
  /// تحديثٌ من الشبكة.
  static SduiAction? from(Map<String, dynamic> item) {
    final parsed = tryParse(item['action']);
    if (parsed != null) return parsed;

    final href = (item['href'] ?? item['ctaHref'] ?? item['link'])?.toString().trim() ?? '';
    return href.isEmpty ? null : legacyFromHref(href);
  }

  /// ترجمةٌ محلّيّة لرابطٍ قديم — **نسخةٌ مبسّطة من ترجمة الخادم عمداً.**
  ///
  /// ‼️ لا تُوسَّع هنا: الخادم هو المرجع (`toAction`)، وكلّ حالةٍ تُضاف محلّيّاً
  /// تخلق قاموساً ثانياً ينحرف. هذه للتوافق الخلفيّ مع الكاش القديم لا غير.
  static SduiAction? legacyFromHref(String href) {
    final category = RegExp(r'^/category/([^/?#]+)').firstMatch(href);
    if (category != null) {
      return SduiAction(type: 'category', value: Uri.decodeComponent(category.group(1)!));
    }
    return SduiAction(type: 'url', value: href);
  }

  @override
  String toString() => 'SduiAction($type:$value)';
}

/// مُنفِّذ الإجراءات — تُوفّره الشاشة لأنّها وحدها تعرف كيف تُبدّل تبويباً.
///
/// ‼️ **`execute` صريحةٌ لأنّ السؤال يسبق الفعل.** المُصيّر يحتاج أن يعرف «هل
/// يُفتَح هذا؟» **قبل** أن يرسم الزرّ (0.1) — وبعد النقر يكون قد فات الأوان:
/// رأى العميل زرّاً وضغطه ولم يحدث شيء.
///
/// ولا تُسأل بتشغيلها: نداءٌ «تجريبيّ» ينفّذ فعلاً يعني تبديل تبويبٍ لمجرّد
/// رسم زرّ. فالفحص والتنفيذ نداءان بنفس الدالّة وعَلَمٌ يفصل بينهما.
///
/// تُعيد `true` إن كان النوع معروفاً وقابلاً للفتح، و`false` إن كان مجهولاً —
/// وحينها يُتجاهَل **بصمت**.
typedef SduiActionHandler = bool Function(SduiAction action, {required bool execute});
