import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../app/config/api_routes.dart';
import '../../app/router/app_router.dart';
import '../network/api_client.dart';
import 'local_notifications.dart';

/// ‼️ **معالِج الرسائل والتطبيق مغلق — يجب أن يكون دالّةً عليا (top-level).**
///
/// أندرويد يُشغّل عزلةً (isolate) جديدة لا تعرف شيئاً عن شجرة الودجات، ويُشترط
/// أن يكون المدخل دالّةً ثابتة مُعلَّمة بـ`@pragma('vm:entry-point')` — وإلّا
/// حُذفت في بناء الإصدار (tree shaking) فيسقط استقبال الرسائل **في الإصدار
/// وحده** بينما يعمل في التطوير. وهو صمتٌ لا يظهر إلّا بعد النشر.
///
@pragma('vm:entry-point')
Future<void> tintFirebaseBackgroundHandler(RemoteMessage message) async {
  // لا عمل هنا اليوم: النظام يعرض إشعار `notification` بنفسه، ولا حاجة إلى
  // تهيئة الشبكة في عزلةٍ عابرة. ووجود المعالِج نفسه شرطٌ لاستقبال رسائل
  // `data` مستقبلاً.
}

/// إشعارات التطبيق (FCM).
///
/// ‼️ **الإذن والتسجيل شيئان منفصلان.** إذن أندرويد إذنُ **عرضٍ** يمنحه النظام؛
/// والموافقة التسويقيّة تُسأل في شاشتنا وتُخزَّن في الخادم. فهذه الخدمة تُسجّل
/// الجهاز ليصله ما يخصّه (طلبه مثلاً)، ولا تعني بذاتها أنّ العميل أذن بالحملات.
///
class PushService {
  PushService(this._apiClient);

  final ApiClient _apiClient;
  StreamSubscription<String>? _refreshSubscription;
  String? _lastRegisteredToken;

  /// يُهيّئ ويسجّل — يُنادى عند إقلاع التطبيق.
  ///
  /// ‼️ **لا يرمي أبداً.** فشلُ الإشعارات لا يجوز أن يمنع المتجر من العمل: جهازٌ
  /// بلا خدمات Google، أو مستخدمٌ رفض الإذن، أو شبكةٌ منقطعة — كلّها أحوالٌ
  /// طبيعيّة، ورميُ الخطأ هنا كان يُسقط الإقلاع كلّه.
  ///
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(tintFirebaseBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      /// ‼️ **يُطلب الإذن ولا يُشترط قبوله للمتابعة.** أندرويد ١٣+ يعرض نافذة
      /// النظام هنا؛ ومن رفض يبقى بلا إشعارات — وهذا قراره. لكنّ الرمز يُسجَّل
      /// على أيّ حال إن وُجد: المستخدم قد يفتح الإذن لاحقاً من إعدادات النظام
      /// **بلا أن يمرّ بنا**، فلا يصله شيء لأنّنا لم نسجّله يومها.
      ///
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      await _register(token);

      /// ‼️ **الرمز يتبدّل بلا إخطارٍ منّا.** إعادة تثبيت · مسح بيانات · خمول
      /// طويل — ولا نعلم إلّا من هذا المجرى. وإهمالُه يعني جهازاً يظنّ نفسه
      /// مشتركاً بينما رمزه المخزَّن عندنا ميّت.
      ///
      _refreshSubscription?.cancel();
      _refreshSubscription = messaging.onTokenRefresh.listen(_register);

      /// ‼️ **حالتان للنقر لا واحدة — وإغفال إحداهما يُسقط نصف النقرات.**
      ///
      /// `getInitialMessage` للنقر **والتطبيق مغلقٌ تماماً** (الحال الأشيع في
      /// الحملات: الإشعار يصل ليلاً ويُضغط صباحاً). و`onMessageOpenedApp` وهو
      /// في الخلفيّة. ولا يُغني أحدهما عن الآخر، ولا ينبّه أحدٌ إلى نقصهما:
      /// الإشعار يُفتح، ويُعرض التطبيق، ولا يذهب إلى شيء — فيبدو سليماً.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openTarget(initial);
      FirebaseMessaging.onMessageOpenedApp.listen(_openTarget);

      /// ‼️ **الرسالة والتطبيق مفتوح: يرسمها التطبيق أو لا تُرسَم.**
      ///
      /// أندرويد لا يعرض إشعار FCM ما دام التطبيق في المقدّمة — يُسلّمه هنا
      /// بصمت. فمن يتصفّح المتجر لحظة إطلاق الحملة كان **لا يرى منها شيئاً**،
      /// وهم أفضل الجمهور. (قِيس بتجربةٍ فاشلة قبل الناجحة.)
      await TintLocalNotifications.initialize();
      FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (error) {
      debugPrint('[push] تعذّرت تهيئة الإشعارات: $error');
    }
  }

  /// يرسم إشعاراً لرسالةٍ وصلت والتطبيق مفتوح.
  ///
  /// ‼️ **الصورة تُقرأ من `data` لا من `notification.android.imageUrl`**: الحقل
  /// الثاني يقرؤه النظام وحده ولا يصل الشيفرة كاملاً على كلّ النسخ. والخادم
  /// يضعها في الاثنين لهذا السبب.
  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    final title = (notification?.title ?? message.data['title'] ?? '').toString().trim();
    final body = (notification?.body ?? message.data['body'] ?? '').toString().trim();
    // ‼️ رسالةٌ بلا عنوانٍ ولا نصّ لا تُرسَم: إشعارٌ فارغ يُقلق ولا يُفيد.
    if (title.isEmpty && body.isEmpty) return;

    unawaited(
      TintLocalNotifications.show(
        title: title,
        body: body,
        imageUrl: (notification?.android?.imageUrl ?? message.data['image'])?.toString(),
        // ‼️ القناة من الرسالة: إشعار طلبٍ على قناة العروض يُسكَت مع الحملات.
        channel: (message.data['channel'] ?? '').toString() == 'orders'
            ? TintLocalNotifications.ordersChannel
            : TintLocalNotifications.campaignsChannel,
      ),
    );
  }

  /// يفتح وجهة الإشعار.
  ///
  /// ‼️ **الوجهة تُقرأ من `data` لا من `notification`.** ما في الثانية يعرضه
  /// النظام ولا يصل الشيفرة والتطبيق مغلق — فوضعُها هناك يعني إشعاراً يُفتَح
  /// ولا يذهب إلى شيء. والخادم يرسلها في `data` لهذا السبب.
  ///
  /// ‼️ **ووجهةٌ مجهولة لا تفعل شيئاً** — يبقى المستخدم على الرئيسيّة بهدوء.
  /// النسخ المثبَّتة لا تُحدَّث بأمرنا، فحملةٌ بوجهةٍ أضيفت بعد نسخة الجهاز
  /// يجب أن تفتح التطبيق لا أن تُعطّله.
  void _openTarget(RemoteMessage message) {
    final kind = (message.data['targetKind'] ?? '').toString().trim();
    final value = (message.data['targetValue'] ?? '').toString().trim();
    if (kind.isEmpty || kind == 'none') return;

    try {
      switch (kind) {
        case 'product':
          if (value.isNotEmpty) AppRouter.router.push('/product/${Uri.encodeComponent(value)}');
          break;
        case 'category':
          // مسارٌ قائمٌ من قبل (`CategoryDeepLinkPage`) — يبدّل تبويب القشرة
          // وينتظر وصول التنقّل إن فُتح التطبيق من البارد.
          if (value.isNotEmpty) AppRouter.router.push('/category/${Uri.encodeComponent(value)}');
          break;
        case 'url':
          /// ‼️ **الروابط الداخليّة وحدها.** فتحُ رابطٍ خارجيّ يأتي من الخادم
          /// يعني أنّ من يملك اللوحة يقود عملاءنا إلى أيّ موقع. والمسار
          /// الداخليّ يُصفّى بالموجّه نفسه: ما لا يُعرَف يقع على الرئيسيّة.
          if (value.startsWith('/')) AppRouter.router.push(value);
          break;
        default:
          debugPrint('[push] وجهةٌ لا تعرفها هذه النسخة: $kind');
      }
    } catch (error) {
      // ‼️ لا يُسقط التطبيق: وجهةٌ معطوبة تُفتَح على الرئيسيّة لا على شاشةٍ بيضاء.
      debugPrint('[push] تعذّر فتح الوجهة: $error');
    }
  }

  /// يرسل الرمز إلى الخادم.
  ///
  /// ‼️ **لا يُرسَل الرمز نفسه مرّتين في الجلسة الواحدة.** `getToken` ومجرى
  /// التحديث قد يعطيان القيمة نفسها عند الإقلاع، ونداءان متطابقان يستهلكان
  /// حدّ المعدّل بلا فائدة. أمّا الإقلاع التالي فيُعيد التسجيل عمداً — وهو ما
  /// يُبقي `lastSeenAt` حيّاً في الخادم.
  ///
  Future<void> _register(String? token) async {
    final value = (token ?? '').trim();
    if (value.isEmpty || value == _lastRegisteredToken) return;

    try {
      await _apiClient.postMap(
        ApiRoutes.pushDevices,
        data: {
          'token': value,
          // ‼️ ثابتٌ اليوم لأنّ البناء أندرويد فقط. ويوم يُبنى iOS تُقرأ
          //    المنصّة من `Platform` — ولا يُخمَّن هنا شيء.
          'platform': 'android',
          'locale': 'ar',
        },
      );
      _lastRegisteredToken = value;
      debugPrint('[push] سُجّل رمز الجهاز (${value.length} حرفاً).');
    } catch (error) {
      // ‼️ يُبتلع الخطأ ويُسجَّل: انقطاعُ شبكةٍ لحظة الإقلاع لا يُسقط التطبيق،
      //    والإقلاع التالي يُعيد المحاولة.
      debugPrint('[push] تعذّر تسجيل الرمز: $error');
    }
  }

  /// إلغاء التسجيل — عند الخروج أو سحب الموافقة.
  Future<void> unregister() async {
    final token = _lastRegisteredToken;
    if (token == null) return;
    try {
      await _apiClient.postMap(ApiRoutes.pushDevicesUnregister, data: {'token': token});
      _lastRegisteredToken = null;
    } catch (error) {
      debugPrint('[push] تعذّر إلغاء التسجيل: $error');
    }
  }

  void dispose() {
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }
}
