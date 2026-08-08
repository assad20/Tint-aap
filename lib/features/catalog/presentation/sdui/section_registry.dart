import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/cms_page_model.dart';
import '../../../../core/models/cms_section_model.dart';

/// بانٍ لمكوّنٍ واحد. يُسجَّل باسم النوع كما في `CmsSectionType` بالخادم.
typedef SectionBuilder = Widget Function(BuildContext context, CmsSectionModel section);

/// ما يُبلَّغ به عن مكوّنٍ لم يُعرَض — للتشخيص اليوم، ولقياس 5.1 لاحقاً.
typedef SectionSkipReporter = void Function(String type, Object? error);

/// سجلّ المكوّنات — الجسر الوحيد بين اسمٍ يكتبه المسوّق في اللوحة وودجةٍ تُرسَم.
///
/// ‼️ **الاسم من `CmsSectionType` حصراً** (`product_carousel`, `hero`, …). ولا
/// يُخترع قاموسٌ محلّيّ موازٍ: قاموسان لنفس الشيء يعني مسوّقاً لا يعرف أيّهما
/// يظهر أين، ويُبطل شرط «تخطيطٌ واحد يخدم الويب والتطبيق».
///
/// ‼️ **والسجلّ فارغٌ عند إنشائه — وهذا صحيح.** يملؤه ترحيلُ الودجات القائمة
/// (2.4–2.9)، وحتّى ذلك الحين كلّ نوعٍ «غير مدعوم» فيسقط بهدوء. والفارق بين
/// «نوعٌ لم يُرحَّل بعد» و«نوعٌ اخترعته لوحةٌ أحدث» فارقٌ لا يعني الشاشة: كلاهما
/// لا يُرسَم في هذه النسخة، وكلاهما يُبلَّغ عنه.
class SectionRegistry {
  SectionRegistry({
    Map<String, SectionBuilder>? builders,
    this.onSkipped,
  }) : _builders = {...?builders};

  final Map<String, SectionBuilder> _builders;

  /// يُستدعى عند كلّ مكوّنٍ لم يُرسَم — نوعٌ مجهول أو بانٍ رمى.
  final SectionSkipReporter? onSkipped;

  void register(String type, SectionBuilder builder) {
    _builders[type] = builder;
  }

  bool supports(String type) => _builders.containsKey(type);

  Iterable<String> get knownTypes => _builders.keys;

  /// يبني مكوّناً واحداً — **ولا يرمي أبداً**.
  ///
  /// ‼️ حارسُ الاستثناء ليس احتياطاً نظريّاً: البانيات تقرأ `settings` و`items`
  /// وهي `Mixed` في الخادم — أي أنّ محرّراً واحداً يستطيع أن يضع فيها أيّ شكل.
  /// وبلا هذا الحارس يتحوّل حقلٌ واحد إلى شاشةٍ حمراء في الرئيسيّة.
  ///
  /// ‼️ و`SizedBox.shrink()` لا رسالة «مكوّن غير مدعوم»: العميل لا يملك لها
  /// حلّاً، ووجودها يجعل صفحةً سليمةً في نظره معطوبة. الفشل اللطيف قاعدة.
  Widget build(BuildContext context, CmsSectionModel section) {
    final builder = _builders[section.type];

    if (builder == null) {
      onSkipped?.call(section.type, null);
      debugPrint('[sdui] نوعٌ غير مدعوم في هذه النسخة ⇒ أُسقط: ${section.type}');
      return const SizedBox.shrink();
    }

    try {
      return builder(context, section);
    } catch (error, stack) {
      onSkipped?.call(section.type, error);
      debugPrint('[sdui] تعذّر بناء "${section.type}" ⇒ أُسقط: $error');
      // ‼️ الأثر في وضع التطوير وحده: `debugPrint` يطبع في الإصدار أيضاً، وأثرٌ
      //    كامل لكلّ قسمٍ فاشل يُغرق سجلّ الجهاز فيُخفي ما بعده.
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack, label: '[sdui] ${section.type}');
      }
      return const SizedBox.shrink();
    }
  }

  /// يبني أقسام صفحةٍ بالترتيب.
  ///
  /// ‼️ يُعيد الودجات كلّها بما فيها الفارغة — ولا يُرشّحها. الترشيح هنا يعني
  /// بناءَ كلّ قسمٍ مرّتين (مرّةً للفحص ومرّةً للعرض)، والبانيات تقرأ من الشبكة
  /// والكاش. و`SizedBox.shrink()` بلا كلفة رسمٍ أصلاً.
  List<Widget> buildAll(BuildContext context, CmsPageModel page) =>
      page.sections.map((section) => build(context, section)).toList(growable: false);
}
