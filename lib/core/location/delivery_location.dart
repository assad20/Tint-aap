import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../features/checkout/presentation/pages/location_picker_page.dart';
import 'geocode.dart';

export 'geocode.dart' show PickedDeliveryLocation;

/// يفتح خريطة اختيار موقع التوصيل ويُعيد ما اختاره العميل — أو `null` إن ألغى.
///
/// ‼️ **مُستخرَجةٌ من شاشة الدفع لتُشارَك**: كانت محبوسةً في `checkout_page`،
/// فشاشة العناوين في الحساب تحفظ عنواناً **بلا دبّوس** بينما يشترطه الدفع —
/// ونسخُها هناك يعني منطقَي موقعٍ يتباعدان.
Future<PickedDeliveryLocation?> pickDeliveryLocation(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
}) async {
  // نقطة البداية: دبّوسٌ سابق إن وُجد، ثمّ موقع الجهاز إن سُمح، وإلّا الرياض.
  // والعميل يحرّك الخريطة إلى الموضع الدقيق على أيّ حال.
  LatLng start = (initialLat != null && initialLng != null)
      ? LatLng(initialLat, initialLng)
      : const LatLng(24.7136, 46.6753);

  if (initialLat == null || initialLng == null) {
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition()
                  .timeout(const Duration(seconds: 15));
          start = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (_) {
      // بلا موقع جهاز — نبدأ من الرياض. وهذا ليس فشلاً يُبلَّغ به.
    }
  }

  if (!context.mounted) return null;

  // خريطة OpenStreetMap تفاعليّة (بلا مفتاح): العميل يضع الدبّوس بدقّة.
  // ‼️ **المنتقي يُعيد العنوان كاملاً لا الإحداثيّات وحدها**: هو يعرضه للعميل
  //    وهو يختار، فإعادةُ ترميزه هنا رحلةٌ ثانية تُنتج أحياناً اسماً مختلفاً
  //    عمّا رآه — والعميل يحكم على ما رأى.
  return Navigator.of(context).push<PickedDeliveryLocation>(
    MaterialPageRoute(builder: (_) => LocationPickerPage(initial: start)),
  );
}
