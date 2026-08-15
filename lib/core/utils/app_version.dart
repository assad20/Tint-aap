import 'package:flutter/foundation.dart';

/// إصدار التطبيق الحاليّ — **يجب أن يطابق `version:` في `pubspec.yaml`**
/// (الجزء قبل `+`).
///
/// ‼️ لماذا ثابتٌ مكتوب لا حزمة `package_info_plus`؟ الحزمة تُضيف شيفرة منصّةٍ
/// لقراءة رقمٍ نعرفه وقت البناء أصلاً، والمشروع يُبنى أحياناً على FlutLab
/// (Dart 3.8.1) حيث كلّ اعتمادٍ جديد خطر توافق. والثمن الوحيد — أن يُنسى
/// تحديثه — يحرسه اختبارٌ يقرأ `pubspec.yaml` ويقارن (`test/app_version_test.dart`).
const String kAppVersion = '1.2.3';

/// يقارن إصدارين رقميّاً بالمقاطع: `-1` إن كان `a` أقدم، `0` تساوٍ، `1` أحدث.
///
/// ‼️ **المقاطع الناقصة أصفار**: `1.4` تساوي `1.4.0` تماماً. والبديل — اعتبار
/// الأقصر أقدم — يجعل لوحةً كُتب فيها `1.4` تُخفي المكوّن عن نسخة `1.4.0`
/// المطابقة لها.
///
/// ‼️ **ويرمي `FormatException` على ما لا يُقرأ** بدل أن يُرجع `0` بصمت: قيمةٌ
/// مثل `v1.4-beta` تُساوي حينها كلّ إصدار، فيظهر المكوّن على نسخةٍ لا تفهمه —
/// وهو بالضبط ما وُجد هذا الحقل لمنعه. والقرار في `supportsMinVersion` أدناه.
int compareVersions(String a, String b) {
  List<int> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('empty version');
    }
    return trimmed.split('.').map((part) {
      final value = int.tryParse(part);
      if (value == null || value < 0) {
        throw FormatException('bad version segment: $part');
      }
      return value;
    }).toList();
  }

  final left = parse(a);
  final right = parse(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l < r ? -1 : 1;
  }
  return 0;
}

/// هل تفهم هذه النسخة مكوّناً حدّه الأدنى `minAppVersion`؟
///
/// ‼️ **الغياب يعني «كلّ الإصدارات» لا «لا أحد».** كلّ الأقسام المنشورة اليوم
/// بلا هذا الحقل، واعتبارُ غيابه تقييداً يُفرغ الرئيسيّة على كلّ جهازٍ لحظة
/// إطلاق هذه النسخة. وهي نفس دلالة `channels` و`audiences` في الخادم.
///
/// ‼️ **وقيمةٌ لا تُقرأ تُخفي المكوّن** — عكسُ الغياب تماماً. الغياب يعني «لم
/// يُقيَّد»، أمّا وجودُ قيمةٍ تالفة فيعني «قُيِّد ولا نعرف بماذا»، والعرض حينها
/// مقامرةٌ بشاشةٍ مكسورة عند العميل. والخادم يرفض هذا الشكل عند الحفظ
/// (`sections.*.minAppVersion`)، فلا تصل إلّا من وثيقةٍ كُتبت قبل ذلك القيد.
bool supportsMinVersion(String? minAppVersion, {String current = kAppVersion}) {
  final min = minAppVersion?.trim() ?? '';
  if (min.isEmpty) return true;

  try {
    return compareVersions(current, min) >= 0;
  } on FormatException catch (error) {
    debugPrint('[sdui] minAppVersion غير صالح ⇒ أُخفي المكوّن: $error');
    return false;
  }
}
