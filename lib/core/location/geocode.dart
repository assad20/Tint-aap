import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';

import '../../app/config/api_routes.dart';
import '../network/api_client.dart';

/// نتيجة اختيار موقع التوصيل — الإحداثيّات، وما استُنبط منها من عنوان.
@immutable
class PickedDeliveryLocation {
  const PickedDeliveryLocation({
    required this.lat,
    required this.lng,
    this.city,
    this.neighborhood,
    this.street,
    this.shortCode,
  });

  final double lat;
  final double lng;

  /// ‼️ **قد تعود فارغةً والإحداثيّات صحيحة**: الترميز العكسيّ غير متاحٍ على
  /// كلّ جهاز. فالمُستدعي يملأ ما وصله ولا يُسقط الدبّوس لأنّ الاسم لم يصل.
  final String? city;
  final String? neighborhood;

  /// الشارع أو المعلم الأقرب — للعرض وحده، ولا يُحفظ حقلاً مستقلّاً.
  final String? street;

  /// العنوان الوطنيّ المختصر (`RHWA2868`) حين يعرفه الخادم.
  ///
  /// ‼️ **للعرض والطمأنينة لا للتخزين**: هو ما يقرؤه المندوب ويتحقّق به
  /// العميل أنّ الدبّوس على مبناه هو. وحفظُه حقلاً في العنوان يعني عقداً
  /// جديداً مع الخادم لأجل نصٍّ يُشتَقّ من الإحداثيّات متى شئنا.
  final String? shortCode;

  bool get hasAddress =>
      (city?.trim().isNotEmpty ?? false) ||
      (neighborhood?.trim().isNotEmpty ?? false);

  /// سطرٌ واحدٌ يُقرأ: «الحيّ، المدينة» أو ما توفّر منهما.
  String get line {
    final parts = [
      street?.trim(),
      neighborhood?.trim(),
      city?.trim(),
    ].where((p) => p != null && p.isNotEmpty).cast<String>().toList();
    return parts.join('، ');
  }
}

/// عكس الترميز الجغرافيّ **بالعربيّة** — المدينة والحيّ والشارع من الإحداثيّات.
///
/// ‼️ **`Locale('ar')` صريحة**: بدونها يتبع المُحوّل لغة النظام، فيخرج عنوانٌ
/// إنجليزيّ في تطبيقٍ عربيّ — وهو ما يقع في تطبيقاتٍ كبيرة نراها.
///
/// ‼️ **ولا ترمي**: غير متاحةٍ على بعض الأجهزة، وسقوطُها لا يجوز أن يُسقط
/// اختيار الموقع — الإحداثيّات وحدها هي المطلوب، والاسم تحسينٌ فوقها.
Future<PickedDeliveryLocation?> reverseGeocodeArabic(
  double lat,
  double lng, {
  ApiClient? api,
}) async {
  /// ‼️ **الخادم أوّلاً — ومُحوّل النظام ملاذُ رجوعٍ لا بديلٌ مكافئ.**
  ///
  /// قِيس على جهاز: مُحوّل النظام أعاد «Alsahafa» لاتينيّةً، ثمّ حين فُضّلت
  /// العربيّة أعاد «امارة منطقة الرياض» — وهي عربيّةٌ **لا تدلّ على مكان**.
  /// وخريطتنا تكتب «العليا» تحت الدبّوس، فالاسم موجودٌ في البلاطات لا في
  /// المُحوّل.
  ///
  /// وخادمنا يسأل غوغل بمفتاحٍ لا يغادره ويُخزّن النتيجة شهراً — فالأسماء
  /// صحيحة، والمفتاح آمن، والفاتورة تُقاس بعدد الأماكن لا بعدد اللمسات.
  if (api != null) {
    final remote = await _fromServer(api, lat, lng);
    if (remote != null) return remote;
  }

  try {
    final places = await Geocoding()
        .placemarkFromCoordinates(lat, lng, locale: const Locale('ar'));
    if (places.isEmpty) return null;
    final place = places.first;

    return PickedDeliveryLocation(
      lat: lat,
      lng: lng,
      city: _preferArabic([place.locality, place.administrativeArea]),
      neighborhood:
          _preferArabic([place.subLocality, place.subAdministrativeArea]),
      street: _preferArabic([place.thoroughfare, place.name]),
    );
  } catch (error) {
    debugPrint('[geocode] تعذّر استنباط العنوان: $error');
    return null;
  }
}


/// هل في النصّ حرفٌ عربيّ؟
bool _hasArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

/// يختار أوّل قيمةٍ **عربيّة** من المرشّحات، وإلّا أوّل قيمةٍ غير فارغة.
///
/// ‼️ **`Locale('ar')` لا تكفي وحدها.** قِيس على جهاز: نفس النقطة تُعيد
/// «الرياض» عربيّةً و«Alsahafa» لاتينيّةً في السطر نفسه — لأنّ قاعدة المُحوّل
/// لا تحمل الاسم العربيّ لكلّ حقل. فيُقدَّم ما كُتب بالعربيّة على ما كُتب
/// باللاتينيّة **من نفس النقطة**، ولا يُترك الترتيب للصدفة.
///
/// ‼️ **ولا يُحذف اللاتينيّ حين لا بديل**: اسمٌ إنجليزيّ أنفع من فراغٍ —
/// والمندوب يقرأ «Alsahafa» ويعرفها، ولا يقرأ الفراغ.
String _preferArabic(List<String?> candidates) {
  final values = candidates
      .map((c) => c?.trim() ?? '')
      .where((c) => c.isNotEmpty)
      .toList(growable: false);
  for (final value in values) {
    if (_hasArabic(value)) return value;
  }
  return values.isEmpty ? '' : values.first;
}


/// يسأل خادمنا. يُعيد `null` عند أيّ تعثّر — فيسقط المُستدعي على مُحوّل النظام.
///
/// ‼️ **ولا يرمي**: هذه شاشة اختيار موقع، وسقوطُ خدمة أسماءٍ لا يجوز أن يمنع
/// العميل من وضع دبّوسه.
Future<PickedDeliveryLocation?> _fromServer(
  ApiClient api,
  double lat,
  double lng,
) async {
  try {
    final data = await api.getMap(
      ApiRoutes.reverseGeocode,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    // `none` = الخادم بلا مفتاح أو لم يعرف ⇒ جرّب الجهاز.
    if (data['source']?.toString() != 'google') return null;
    final city = data['city']?.toString().trim() ?? '';
    final neighborhood = data['neighborhood']?.toString().trim() ?? '';
    if (city.isEmpty && neighborhood.isEmpty) return null;
    return PickedDeliveryLocation(
      lat: lat,
      lng: lng,
      city: city,
      neighborhood: neighborhood,
      street: data['street']?.toString().trim() ?? '',
      shortCode: data['shortCode']?.toString().trim() ?? '',
    );
  } catch (error) {
    debugPrint('[geocode] الخادم لم يردّ: $error');
    return null;
  }
}
