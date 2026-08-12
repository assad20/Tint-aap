import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// رسمُ الإشعار بأنفسنا — لا بالنظام.
///
/// ‼️ **لماذا نحتاجه أصلاً؟ سببان قِيسا لا فُرضا:**
///
/// ١) **أندرويد لا يعرض إشعار FCM والتطبيق مفتوح.** يُسلّمه للشيفرة بصمت ولا
///    يرسم شيئاً. فمن يتصفّح المتجر لحظة إطلاق الحملة **لا يرى منها شيئاً** —
///    وهم أفضل الجمهور. (كُشف بتجربةٍ فاشلة قبل الناجحة 2026-08-11.)
///
/// ٢) **ولا حقل `largeIcon` في عقد FCM إطلاقاً** — فحصتُ `messaging-api.d.ts`:
///    فيه `imageUrl` (صورةٌ كبيرة عند التوسيع) و`icon` (شكلٌ أحاديّ اللون في
///    شريط الحالة) ولا ثالث. والصورة المصغَّرة **بجانب** النصّ — كالتي في إعلان
///    شي إن — لا تُنال إلّا برسم الإشعار محلّيّاً.
class TintLocalNotifications {
  TintLocalNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// ‼️ **قناةٌ مصرَّحٌ بها مسبقاً.** أندرويد ٨+ يرفض أيّ إشعارٍ بلا قناة —
  /// **بصمت**: لا خطأ، ولا شيء يظهر. وإنشاؤها عند أوّل إشعار سباقٌ مع الزمن،
  /// فتُنشأ عند التهيئة.
  ///
  /// ‼️ **قناتان لا واحدة — وهذا لصالحنا لا لصالح العميل وحده.**
  /// مفتاح النظام الواحد يُطفئ كلّ شيء: من ضاق بحملةٍ ترويجيّة كان يفقد معها
  /// «طلبك شُحن» — فنخسر أثمن قناةٍ لدينا بسبب رسالة تخفيضات.
  ///
  /// ‼️ **وثابتتان بالعدد.** فُحصت ترنديول على جهاز المالك (2026-08-12):
  /// عندها `Campaign` و`Order` — ثمّ **ستّ عشرة** قناةً باسم
  /// «Special Notifications (٣)…(١٦)». وهذا ما يحدث حين تُنشأ قناةٌ لكلّ حملة:
  /// شاشة إعداداتٍ لا تُقرأ، ومستخدمٌ يريد إسكات العروض فلا يعرف أيّ مفتاحٍ
  /// يُطفئ **فيُطفئ الكلّ** — أي نفس الضرر الذي وُجدت القنوات لمنعه.
  /// **فلا قناةَ لكلّ حملة أبداً.**
  ///
  /// ‼️ **وأسماؤها بالعربيّة**: اسم القناة يُثبَّت لحظة إنشائها ولا يتبع
  /// لغة الجهاز بعدها — ولذلك تظهر قنوات ترنديول بالإنجليزيّة على هاتفٍ عربيّ.
  static const campaignsChannel = AndroidNotificationChannel(
    'tint_campaigns',
    'العروض والحملات',
    description: 'عروض وتخفيضات ومنتجات جديدة من تنت.',
    importance: Importance.high,
  );

  static const ordersChannel = AndroidNotificationChannel(
    'tint_orders',
    'تحديثات الطلبات',
    description: 'حالة طلبك: التجهيز والشحن والتسليم.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          // ‼️ نفس أيقونة المانيفست: أيقونتان مختلفتان تعنيان إشعاراً يبدو من
          //    تطبيقين — إحداهما حين يرسمه النظام والأخرى حين نرسمه نحن.
          android: AndroidInitializationSettings('ic_stat_tint'),
        ),
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(campaignsChannel);
      await android?.createNotificationChannel(ordersChannel);
      _ready = true;
    } catch (error) {
      debugPrint('[push] تعذّرت تهيئة الإشعارات المحلّيّة: $error');
    }
  }

  /// يعرض إشعاراً بصورةٍ مصغَّرة جانبيّة وصورةٍ كبيرة عند التوسيع.
  ///
  /// ‼️ **الصورة تُنزَّل قبل العرض ولا تُمرَّر رابطاً.** ودجة الإشعار في أندرويد
  /// لا تجلب من الشبكة — تستقبل بايتات. وتمريرُ الرابط يُنتج إشعاراً بلا صورة
  /// بلا خطأ.
  ///
  /// ‼️ **وفشل الصورة لا يُسقط الإشعار.** شبكةٌ بطيئة أو رابطٌ معطوب يعنيان
  /// إشعاراً نصّيّاً — لا صمتاً. والنصّ هو الرسالة، والصورة زينة.
  /// ‼️ **القناة تُختار بالرسالة لا تُثبَّت.** إشعار طلبٍ يُرسَل على قناة
  /// العروض يُسكَت مع الحملات — فيقول العميل «لم يخبرني أحدٌ أنّ طلبي شُحن»
  /// وهو الذي أطفأ الإعلانات لا الطلبات.
  static Future<void> show({
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
    AndroidNotificationChannel channel = campaignsChannel,
  }) async {
    await initialize();
    if (!_ready) return;

    Uint8List? image;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      image = await _download(imageUrl.trim());
    }

    final style = image == null
        ? null
        : BigPictureStyleInformation(
            ByteArrayAndroidBitmap(image),
            largeIcon: ByteArrayAndroidBitmap(image),
            hideExpandedLargeIcon: true,
          );

    final details = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      // لون العلامة — نفس قيمة المانيفست، فلا يختلف مظهر الإشعارين.
      color: const Color(0xFFC59C8F),
      largeIcon: image == null ? null : ByteArrayAndroidBitmap(image),
      styleInformation: style,
    );

    try {
      await _plugin.show(
        // ‼️ معرّفٌ متغيّر: معرّفٌ ثابت يجعل كلّ إشعارٍ **يستبدل** سابقه، فتضيع
        //    حملةٌ وصلت قبل أن تُقرأ.
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
        payload: payload,
      );
    } catch (error) {
      debugPrint('[push] تعذّر عرض الإشعار المحلّيّ: $error');
    }
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      // ‼️ حدٌّ للحجم: صورةٌ ضخمة تُبطئ ظهور الإشعار وقد تُسقط العمليّة.
      if (response.bodyBytes.length > 2 * 1024 * 1024) return null;
      return response.bodyBytes;
    } catch (error) {
      debugPrint('[push] تعذّر تنزيل صورة الإشعار: $error');
      return null;
    }
  }
}
