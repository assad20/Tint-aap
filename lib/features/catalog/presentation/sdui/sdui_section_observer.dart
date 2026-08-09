import 'package:flutter/material.dart';

import 'sdui_tracker.dart';

/// يُبلّغ عن ظهور مكوّنٍ حين يُرى **نصفه على الأقلّ** (معيار 5.1).
///
/// ‼️ **بلا حزمة `visibility_detector`.** الحساب هنا سطران: موضع الصندوق في
/// الشاشة مقابل ارتفاعها. وإضافة اعتمادٍ لأجل ذلك تُثقل حزمةً تُبنى أحياناً على
/// FlutLab بنسخةٍ قديمة — وكلّ اعتمادٍ جديد خطر توافق.
///
/// ‼️ **و«نصفه» لا «أوّل بكسل منه»**: رفٌّ ظهر منه سطرٌ في أسفل الشاشة لم
/// يُشاهَد فعلاً، واحتسابُه ظهوراً يجعل كلّ مكوّنات الصفحة متساويةً في التقرير
/// فيفقد معناه.
class SduiSectionObserver extends StatefulWidget {
  const SduiSectionObserver({
    super.key,
    required this.tracker,
    required this.listName,
    required this.sectionType,
    required this.child,
  });

  final SduiTracker tracker;
  final String? listName;
  final String sectionType;
  final Widget child;

  @override
  State<SduiSectionObserver> createState() => _SduiSectionObserverState();
}

class _SduiSectionObserverState extends State<SduiSectionObserver> {
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    // الأقسام الأولى تكون مرئيّةً قبل أيّ تمرير — فتُفحَص بعد أوّل إطار.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_reported || !mounted || (widget.listName ?? '').isEmpty) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.height <= 0) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;

    // الجزء الظاهر من الصندوق داخل حدود الشاشة.
    final visible = (bottom.clamp(0.0, screenHeight)) - (top.clamp(0.0, screenHeight));
    if (visible <= 0) return;

    /**
     * ‼️ **النسبة إلى الأصغر: ارتفاع المكوّن أو الشاشة.**
     *
     * مكوّنٌ أطول من الشاشة (شبكة منتجاتٍ طويلة) لا يُرى نصفه أبداً، فشرطُ
     * «نصف ارتفاعه» كان يعني أنّه لا يُحتسَب ولو ملأ الشاشة كلّها — ويختفي
     * أكبر مكوّنات الصفحة من التقرير.
     */
    final reference = box.size.height < screenHeight ? box.size.height : screenHeight;
    if (visible / reference < 0.5) return;

    _reported = true;
    widget.tracker.recordImpression(widget.listName, widget.sectionType);
  }

  @override
  Widget build(BuildContext context) {
    if (_reported || (widget.listName ?? '').isEmpty) {
      return widget.child;
    }

    // ‼️ يُفحَص عند التمرير لا بمؤقّت: المؤقّت يعمل والشاشة ساكنة فيستهلك بلا
    //    سبب، والتمرير هو الحدث الوحيد الذي يُغيّر ما يُرى.
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _check();
        return false; // لا نبتلع الإشعار — بقيّة الشجرة تحتاجه.
      },
      child: widget.child,
    );
  }
}
