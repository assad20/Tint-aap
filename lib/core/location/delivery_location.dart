import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../features/checkout/presentation/pages/location_picker_page.dart';

/// نتيجة اختيار موقع التوصيل — الإحداثيّات، وما استُنبط منها من عنوان.
@immutable
class PickedDeliveryLocation {
  const PickedDeliveryLocation({
    required this.lat,
    required this.lng,
    this.city,
    this.neighborhood,
  });

  final double lat;
  final double lng;

  /// ‼️ **قد تعود فارغةً والإحداثيّات صحيحة**: الترميز العكسيّ غير متاحٍ على
  /// كلّ جهاز. فالمُستدعي يملأ ما وصله ولا يُسقط الدبّوس لأنّ الاسم لم يصل.
  final String? city;
  final String? neighborhood;

  bool get hasAddress =>
      (city?.trim().isNotEmpty ?? false) ||
      (neighborhood?.trim().isNotEmpty ?? false);
}

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
  final picked = await Navigator.of(context).push<LatLng>(
    MaterialPageRoute(builder: (_) => LocationPickerPage(initial: start)),
  );
  if (picked == null) return null;

  final place = await _reverseGeocode(picked.latitude, picked.longitude);
  return PickedDeliveryLocation(
    lat: picked.latitude,
    lng: picked.longitude,
    city: place?.$1,
    neighborhood: place?.$2,
  );
}

/// عكس الترميز الجغرافيّ: المدينة والحيّ من الإحداثيّات (المُحوّل المدمج في
/// النظام — بلا مفتاحٍ خارجيّ).
Future<(String, String)?> _reverseGeocode(double lat, double lng) async {
  try {
    final places = await Geocoding()
        .placemarkFromCoordinates(lat, lng, locale: const Locale('ar'));
    if (places.isEmpty) return null;
    final place = places.first;
    final city = (place.locality?.trim().isNotEmpty ?? false)
        ? place.locality!.trim()
        : (place.administrativeArea?.trim() ?? '');
    final neighborhood = (place.subLocality?.trim().isNotEmpty ?? false)
        ? place.subLocality!.trim()
        : (place.subAdministrativeArea?.trim() ?? '');
    return (city, neighborhood);
  } catch (_) {
    // غير متاحٍ على بعض الأجهزة — تبقى الإحداثيّات وحدها، وهي المطلوب أصلاً.
    return null;
  }
}
