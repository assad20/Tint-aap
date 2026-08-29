import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/tracking/tracking_service.dart';

/// شاشة موافقة التتبّع — وفق نظام حماية البيانات الشخصيّة السعُدّ.
///
/// ‼️ **خياران مستقلّان لا مفتاحٌ واحد.** من يقبل قياس أداء التطبيق لم يقبل
/// بالضرورة تتبّعاً إعلانيّاً، ودمجُهما يجعل الموافقة غير محدّدة — **وهي حينئذٍ
/// ليست موافقةً نظاميّة**.
///
/// ‼️ **ولا زرّ «موافق على الكلّ» بارزاً في مقابل رفضٍ باهت.** تصميمٌ يدفع إلى
/// القبول (dark pattern) يُبطل صفة «الاختيار الحرّ» التي تقوم عليها الموافقة —
/// فالزرّان متساويان في الوزن، والمفتاحان مُطفآن حتّى يقرّر صاحبهما.
///
/// ‼️ **وتُعرَض مرّةً واحدة**: سؤالٌ يتكرّر كلّ إقلاعٍ يُدرَّب المستخدم على رفضه
/// بلا قراءة. ويُعدَّل القرار من الإعدادات متى شاء.
class TrackingConsentPage extends StatefulWidget {
  const TrackingConsentPage({
    super.key,
    required this.tracking,
    this.isSettings = false,
  });

  final TrackingService tracking;

  /// من الإعدادات (تعديل قرارٍ قائم) أم أوّل مرّة؟
  final bool isSettings;

  @override
  State<TrackingConsentPage> createState() => _TrackingConsentPageState();
}

class _TrackingConsentPageState extends State<TrackingConsentPage> {
  /// ‼️ **المفتاحان يظهران مُفعَّلين في أوّل عرضٍ — والقرار يبقى للعميل.**
  ///
  /// طلب المالك (2026-08-29): يراهما مفتوحين فيُغلق ما لا يريد، بدل أن يفتح
  /// ما لا يفهم. وأكثر من يُعرَض عليه اختيارٌ لا يلمسه — فالوضع الابتدائيّ
  /// **هو** القرار عمليّاً.
  ///
  /// ‼️ **ولا يُجمَع شيءٌ قبل أن يضغط.** الظاهر على الشاشة **اقتراح** لا
  /// موافقة: `isDecided` يبقى `false` حتّى يُحفظ الاختيار، والقياس معلَّقٌ
  /// عليه. فالفرق بين «مفتاحٌ مرفوع» و«موافقةٌ مسجَّلة» محفوظٌ كما كان.
  ///
  /// ‼️ **ومن فتحها من الإعدادات يرى اختياره هو** لا الاقتراح — وإلّا بدا أنّ
  /// التطبيق أعاد تشغيل ما أطفأه.
  late bool _analytics = widget.tracking.consent.isDecided
      ? widget.tracking.consent.analytics
      : true;
  late bool _ads = widget.tracking.consent.isDecided
      ? widget.tracking.consent.ads
      : true;
  bool _saving = false;

  Future<void> _save({bool? analytics, bool? ads}) async {
    setState(() => _saving = true);
    await widget.tracking.setConsent(
      analytics: analytics ?? _analytics,
      ads: ads ?? _ads,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TintColors.cream,
      appBar: AppBar(
        title: const Text('الخصوصيّة والقياس'),
        backgroundColor: TintColors.cream,
        elevation: 0,
        // ‼️ لا زرّ رجوع في العرض الأوّل: الخروج بلا قرارٍ يترك الحال «لم يُسأل»
        //    فتُعاد الشاشة عند كلّ إقلاع — وهو ما نتجنّبه.
        automaticallyImplyLeading: widget.isSettings,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'نحترم خصوصيّتك',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر ما تسمح لنا به. تستطيع تغيير قرارك في أيّ وقت من الإعدادات، '
              'ولا يؤثّر رفضك على استخدامك للتطبيق ولا على طلباتك.',
              style: TextStyle(color: TintColors.textMuted, height: 1.7, fontSize: 13),
            ),
            const SizedBox(height: 20),

            _ConsentTile(
              title: 'تحسين التطبيق',
              // ‼️ لغةٌ واضحة لا مصطلحاتٌ تقنيّة: «تحليلات» و«قياس» لا تقولان
              //    للمستخدم ماذا يحدث فعلاً، والموافقة تُشترط أن تكون مستنيرة.
              description:
                  'نعرف أيّ الصفحات تُستعمل وأين تتعثّر التجربة، فنُصلحها. '
                  'بيانات مجمّعة لا تُعرّف بك.',
              value: _analytics,
              onChanged: _saving ? null : (value) => setState(() => _analytics = value),
            ),
            const SizedBox(height: 12),
            _ConsentTile(
              title: 'إعلانات أقرب لاهتمامك',
              description:
                  'نقيس نتائج إعلاناتنا ونعرض لك ما يناسبك بدل إعلاناتٍ عشوائيّة. '
                  'يشمل مشاركة مُعرّف إعلانيّ من جهازك.',
              value: _ads,
              onChanged: _saving ? null : (value) => setState(() => _ads = value),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                // ‼️ الزرّان متساويان في الوزن — انظر تعليق الصنف.
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _save(analytics: false, ads: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: TintColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'رفض الكلّ',
                      style: TextStyle(fontWeight: FontWeight.w800, color: TintColors.charcoal),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(),
                    style: FilledButton.styleFrom(
                      backgroundColor: TintColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      widget.isSettings ? 'حفظ' : 'تأكيد اختياري',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TintColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                      color: TintColors.textMuted, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: TintColors.sand,
          ),
        ],
      ),
    );
  }
}
