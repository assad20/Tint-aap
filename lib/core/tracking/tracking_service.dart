import 'dart:async';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config/api_routes.dart';
import '../network/api_client.dart';
import 'tracking_config.dart';
import 'tracking_consent.dart';

/// منظومة القياس — البوّابة الوحيدة لأيّ حدثٍ يخرج من التطبيق.
///
/// ‼️ **لا يُطلق حدثٌ إلّا عبرها.** استدعاءُ `FirebaseAnalytics` مباشرةً من شاشة
/// يتخطّى بوّابة الموافقة وقيد القناة معاً — ويكفي موضعٌ واحد يفعلها ليصير
/// التطبيق مخالِفاً، **بلا خطأٍ في أيّ سجلّ**.
///
/// ‼️ **وترتيب البوّابات مقصود:** القناة ← الموافقة ← الإرسال. فمتجرٌ قناته
/// مُطفأة لا يُقاس ولو وافق مستخدمه، ومستخدمٌ رافض لا يُقاس ولو كانت القناة
/// مفتوحة.
class TrackingService {
  TrackingService(this._apiClient);

  final ApiClient _apiClient;
  final TrackingConsentStore _consentStore = TrackingConsentStore();

  TrackingConfig _config = TrackingConfig.disabled;
  TrackingConsent _consent = TrackingConsent.undecided;
  String? _analyticsId;
  bool _ready = false;

  /// ‼️ **إشارةٌ تُنتظَر، لا مهلةٌ تُخمَّن.**
  ///
  /// كان المستهلك ينتظر ٣ ثوانٍ ثمّ يفحص مرّةً واحدة — ورحلة `config` من
  /// الإنتاج أبطأ من ذلك، فيقع الفحص والقناة ما زالت مُطفأة **فلا تظهر شاشة
  /// الموافقة أبداً**. بلا خطأٍ ولا تحذير.
  ///
  /// ومهلةٌ أطول ليست حلّاً: تراهن على شبكةٍ لا نعرفها. فالجهوزيّة تُعلَن حين
  /// تقع فعلاً.
  final Completer<void> _readySignal = Completer<void>();
  Future<void> get ready => _readySignal.future;

  TrackingConfig get config => _config;
  TrackingConsent get consent => _consent;

  /// ‼️ **المُعرّف المبهم — ولا بيانات شخصيّة فيه أبداً.**
  ///
  /// القاعدة الأولى في التكليف: لا جوّال ولا بريد ولا اسم في أيّ حدثٍ أو خاصيّة
  /// مستخدم. فهذا مُعرّفٌ عشوائيّ يُولَّد مرّةً ويبقى — يربط رحلة الجهاز بلا أن
  /// يقول من صاحبه.
  String? get analyticsId => _analyticsId;

  /// هل يُسأل المستخدم عن الموافقة الآن؟
  bool get needsConsentDecision =>
      _config.channelEnabled && _config.consentRequired && !_consent.isDecided;

  /// يُقرأ عند الإقلاع **قبل تسجيل الدخول**.
  ///
  /// ‼️ **ولا يرمي أبداً**: فشل القياس لا يجوز أن يمنع المتجر من العمل. وعند
  /// أيّ تعثّرٍ تبقى القناة مُطفأة — الصمت أسلم من إرسالٍ بإعداداتٍ مجهولة.
  Future<void> initialize() async {
    try {
      _consent = await _consentStore.read();
      _analyticsId = await _readOrCreateAnalyticsId();

      final raw = await _apiClient.getMap(ApiRoutes.trackingConfig);
      _config = TrackingConfig.fromJson(raw);

      await _applyConsentToFirebase();

      /// ‼️ **`store_id` معاملٌ افتراضيّ لا يُحقَن يدويّاً.**
      ///
      /// معيار القبول يشترطه في **كلّ** حدث. وحقنُه في كلّ نداءٍ يعني نداءً
      /// يُنسى؛ والأسوأ أنّ الواجهة المُهيكلة (`logAddToCart` وأخواتها) لا تمرّ
      /// بدالّتنا العامّة أصلاً — فحقنٌ فيها وحدها كان يترك نصف الأحداث بلا متجر.
      /// و`setDefaultEventParameters` تُلحقه بما يخرج من الحزمة كلّه.
      if (_config.storeId.isNotEmpty) {
        await FirebaseAnalytics.instance
            .setDefaultEventParameters({'store_id': _config.storeId});
      }

      _ready = true;
      debugPrint(
        '[tracking] القناة: ${_config.channelEnabled} · المنصّات: ${_config.platforms.length}',
      );
    } catch (error) {
      _config = TrackingConfig.disabled;
      debugPrint('[tracking] تعذّرت قراءة الإعدادات — القياس مُطفأ: $error');
    } finally {
      // ‼️ **يُكمَل في كلّ الأحوال**: لو أُكمل عند النجاح وحده لانتظر
      //    المستهلك إلى الأبد عند انقطاع الشبكة — شاشةٌ معلَّقة بلا سبب ظاهر.
      if (!_readySignal.isCompleted) _readySignal.complete();
    }
  }

  /// يحفظ قرار المستخدم ويُطبّقه على Firebase فوراً.
  Future<void> setConsent({required bool analytics, required bool ads}) async {
    _consent = _consent.copyWith(analytics: analytics, ads: ads);
    await _consentStore.write(_consent);
    await _applyConsentToFirebase();
  }

  /// ‼️ **`setConsent` يسبق أيّ جمع** — لا بعده.
  ///
  /// وتُضبَط الأربعة صراحةً لا اثنان: `adUserData` و`adPersonalization` حقلان
  /// مستقلّان في Firebase، وإغفالهما يترك الافتراض ساريَ المفعول — فيُجمَع ما
  /// لم يأذن به المستخدم بينما نظنّ أنّنا منعناه.
  Future<void> _applyConsentToFirebase() async {
    try {
      await FirebaseAnalytics.instance.setConsent(
        analyticsStorageConsentGranted: _consent.analytics,
        adStorageConsentGranted: _consent.ads,
        adUserDataConsentGranted: _consent.ads,
        adPersonalizationSignalsConsentGranted: _consent.ads,
      );
      // ‼️ ورفض التحليلات = صمتٌ تامّ على مستوى الحزمة نفسها، لا ترشيحٌ عندنا.
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(_consent.analytics);
    } catch (error) {
      debugPrint('[tracking] تعذّر ضبط الموافقة: $error');
    }
  }

  /// هل يجوز الإرسال الآن؟ — القناة ثمّ الموافقة.
  bool get _mayCollect =>
      _ready && _config.isMeasurable && _consent.analytics;

  /// ينفّذ نداءً مُهيكلاً **بعد المرور بالبوّابات**.
  ///
  /// ‼️ **بوّابةٌ واحدة للواجهتين.** أحداث التجارة في Firebase لها دوالّ
  /// مُهيكلة (`logAddToCart` وأخواتها) لا تقبل `items` عبر `logEvent` العامّة —
  /// وهي ترفضها بتأكيدٍ صريح: «`String` أو `num` فقط». (رُصد على المحاكي
  /// 2026-08-13.) فلو استُدعيت مباشرةً لتخطّت بوّابة الموافقة، ولو مُرّرت عبر
  /// العامّة لسقطت. فتمرّ من هنا: الحارس نفسه، والواجهة الصحيحة.
  Future<void> guarded(
    Future<void> Function(FirebaseAnalytics analytics) action,
  ) async {
    if (!_mayCollect) return;
    try {
      await action(FirebaseAnalytics.instance);
    } catch (error) {
      debugPrint('[tracking] تعذّر إطلاق حدث: $error');
    }
  }

  /// يُطلق حدثاً بعد المرور بالبوّابات.
  ///
  /// ‼️ **`store_id` يُضاف هنا لا في مواضع النداء**: معيار القبول يشترطه في
  /// **كلّ** حدث، وإضافتُه يدويّاً في عشرين موضعاً تعني موضعاً يُنسى — وحدثٌ
  /// بلا متجر يُقبَل في Firebase ويُخزَّن ولا يُنسَب لأحد.
  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]) async {
    if (!_mayCollect) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        // `store_id` يأتي من `setDefaultEventParameters` — لا يُكرّر هنا.
        parameters: <String, Object>{
          for (final entry in params.entries)
            if (entry.value != null) entry.key: entry.value!,
        },
      );
    } catch (error) {
      debugPrint('[tracking] تعذّر إطلاق $name: $error');
    }
  }

  /// ‼️ **الهويّة `user_id` لا الجوّال.** الرقم نفسه المستعمل في الوِب — ولا
  /// يُرسَل جوّالٌ ولا بريدٌ خاصيّةً للمستخدم أبداً.
  Future<void> setUserId(String? userId) async {
    if (!_mayCollect) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: userId);
    } catch (error) {
      debugPrint('[tracking] تعذّر ضبط الهويّة: $error');
    }
  }

  /// يُطلق `purchase` **مرّةً واحدة لكلّ طلب**، ويقول هل خرج فعلاً.
  ///
  /// ‼️ **والحارس على القرص لا في الذاكرة.** مسارات الدفع الخمسة ليست واحدة:
  /// تابي وتمارا وPayTabs ونون تمرّ بويب‑ڤيو ورجوعٍ إلى التطبيق، وقد يُعاد
  /// بناء العمليّة كلّها بينها. وحارسٌ في الذاكرة يضيع عندها فيُحتسب الشراء
  /// مرّتين — وعدٌّ مزدوج في الإيراد أسوأ من غيابه: يُبنى عليه قرار إنفاق.
  /// وحتّى بلا ذلك، مُستمع الحالة في الشاشة يُعيد النداء عند كلّ انبعاث.
  ///
  /// ‼️ **ويُرجع `false` عند المنع** — لا يبتلعه بصمت. فمن ينادي يحتاج أن
  /// يعرف: علامة «رآه المتصفّح» تُرسَل للخادم **فقط إن خرج الحدث**، وإرسالها
  /// بلا إطلاقٍ يمنع استدراك الخادم فيضيع الشراء من الطرفين معاً.
  Future<bool> logPurchase({
    required String transactionId,
    required List<AnalyticsEventItem> items,
    required double value,
    double shipping = 0,
    String? coupon,
  }) async {
    final id = transactionId.trim();
    if (id.isEmpty || items.isEmpty) return false;
    if (!await _markPurchaseOnce(id)) return false;
    if (!_mayCollect) return false;
    try {
      await FirebaseAnalytics.instance.logPurchase(
        transactionId: id,
        currency: 'SAR',
        value: value,
        shipping: shipping,
        coupon: (coupon != null && coupon.isNotEmpty) ? coupon : null,
        items: items,
      );
      return true;
    } catch (error) {
      debugPrint('[tracking] تعذّر إطلاق purchase: $error');
      return false;
    }
  }

  static const _purchasesKey = 'tint_logged_purchases_v1';

  /// `true` إن كان هذا الطلب جديداً (ويُسجَّل)، و`false` إن سبق تسجيله.
  Future<bool> _markPurchaseOnce(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_purchasesKey) ?? const <String>[];
      if (seen.contains(orderId)) return false;
      // آخر خمسين طلباً تكفي للحراسة، والقائمة لا تنمو بلا حدّ على الجهاز.
      final next = [...seen, orderId];
      await prefs.setStringList(
        _purchasesKey,
        next.length > 50 ? next.sublist(next.length - 50) : next,
      );
      return true;
    } catch (_) {
      // تعذّر القرص: الأسلم ألّا يُطلَق. شراءٌ ضائع خطأٌ في تقرير،
      // وشراءٌ مكرّر خطأٌ في قرار.
      return false;
    }
  }

  static const _analyticsIdKey = 'tint_analytics_id_v1';

  Future<String?> _readOrCreateAnalyticsId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_analyticsIdKey);
      if (existing != null && existing.isNotEmpty) return existing;

      // ‼️ عشوائيٌّ محض — لا يُشتقّ من جوّالٍ ولا بريدٍ ولا مُعرّف جهاز:
      //    مُعرّفٌ مشتقٌّ من بيانٍ شخصيّ يبقى بياناً شخصيّاً مهما جُزّئ.
      final random = Random.secure();
      final id = List<String>.generate(
        32,
        (_) => random.nextInt(16).toRadixString(16),
      ).join();
      await prefs.setString(_analyticsIdKey, id);
      return id;
    } catch (_) {
      return null;
    }
  }
}
