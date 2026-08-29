import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// قرار المستخدم في التتبّع.
///
/// ‼️ **خياران مستقلّان لا واحد** (نظام حماية البيانات السعُدّ): من يقبل قياس
/// أداء التطبيق لم يقبل بالضرورة تتبّعاً إعلانيّاً. ودمجُهما في مفتاحٍ واحد
/// يجعل الموافقة غير محدّدة — وهي حينئذٍ ليست موافقةً نظاميّة.
class TrackingConsent {
  const TrackingConsent({
    required this.analytics,
    required this.ads,
    required this.decidedAt,
  });

  final bool analytics;
  final bool ads;

  /// لحظة القرار — تُرسَل ضمن `trackingContext.consent.at`.
  ///
  /// ‼️ **و`null` تعني «لم يُسأل بعد» لا «رفض»**، والفرق جوهريّ: الأولى تُوجب
  /// عرض الشاشة، والثانية تُوجب الصمت واحترام القرار.
  final DateTime? decidedAt;

  bool get isDecided => decidedAt != null;

  /// ‼️ **الحال الافتراضيّة: رفضٌ تامّ حتّى يُسأل.** «لا جمع قبل قرار
  /// المستخدم» — فالافتراض الصامت لا يجوز أن يكون الجمع.
  /// الحال قبل أن يقرّر العميل — **مُفعَّلةٌ افتراضيّاً بقرار المالك
  /// (2026-08-29).**
  ///
  /// ‼️ **وقرارٌ سعُدٌّ لا عامّ.** فُحص ما يجمعه التطبيق قبل اتّخاذه: لا
  /// معرّف إعلانيّ يُقرأ بأنفسنا، والموافقة تُمرَّر إلى **وضع الموافقة في
  /// Firebase Analytics** وحده — وفايربيس على iOS لا يقرأ IDFA افتراضيّاً،
  /// فلا نافذة تتبّعٍ من آبل تلزم. وPlay يطلب إفصاحاً في «أمان البيانات» لا
  /// شاشةً حاجزة.
  ///
  /// ‼️ **وفي أوروبا هذا مخالف.** اللائحة تشترط موافقةً صريحةً سابقة، ووضعاً
  /// ابتدائيّاً مطفأً. فمن يبيع هناك يوماً: يُعاد الوضع الابتدائيّ ليتبع **بلد
  /// الجهاز** — وتُعاد الشاشة الحاجزة معه (انظر `main_shell_page`).
  ///
  /// ‼️ **ويبقى الإطفاء بيد العميل** في «حسابي ← الخصوصيّة والقياس» — وهو
  /// شرط المقبوليّة: افتراضٌ مفتوحٌ بلا مخرجٍ ظاهر ليس اختياراً.
  static const TrackingConsent undecided =
      TrackingConsent(analytics: true, ads: true, decidedAt: null);

  Map<String, dynamic> toJson() => {
        'analytics': analytics,
        'ads': ads,
        'decidedAt': decidedAt?.toIso8601String(),
      };

  factory TrackingConsent.fromJson(Map<String, dynamic> json) {
    final at = json['decidedAt'];
    return TrackingConsent(
      analytics: json['analytics'] == true,
      ads: json['ads'] == true,
      decidedAt: at is String ? DateTime.tryParse(at) : null,
    );
  }

  TrackingConsent copyWith({bool? analytics, bool? ads}) => TrackingConsent(
        analytics: analytics ?? this.analytics,
        ads: ads ?? this.ads,
        decidedAt: DateTime.now().toUtc(),
      );
}

/// تخزين قرار الموافقة على الجهاز.
///
/// ‼️ **يبقى بعد إغلاق التطبيق ولا يُعاد السؤال** — سؤالٌ يتكرّر كلّ إقلاع
/// يُدرَّب المستخدم على رفضه بلا قراءة. ويُعدَّل من الإعدادات متى شاء.
class TrackingConsentStore {
  static const _key = 'tint_tracking_consent_v1';

  Future<TrackingConsent> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return TrackingConsent.undecided;
      return TrackingConsent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // ‼️ قراءةٌ فاشلة تُقرأ «لم يُسأل» لا «وافق»: الخطأ نحو الصمت.
      return TrackingConsent.undecided;
    }
  }

  Future<void> write(TrackingConsent consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(consent.toJson()));
    } catch (_) {
      // لا يُسقط التطبيق — والقرار يُعاد سؤاله في الإقلاع التالي.
    }
  }
}
