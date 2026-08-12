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
  static const _channel = AndroidNotificationChannel(
    'tint_campaigns',
    'عروض تنت',
    description: 'إشعارات العروض والحملات من متجر تنت.',
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
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
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
  static Future<void> show({
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
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
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
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
