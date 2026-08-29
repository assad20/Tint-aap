import 'package:flutter/foundation.dart';

/// إعداد شريحة آبل باي كما يقوله **الخادم** — لا كما يُكتب في التطبيق.
///
/// ‼️ **ولا تُثبَّت هذه القيم في الشيفرة**: مُعرّف التاجر والشبكات المقبولة
/// تتبدّل من لوحة الإدارة ومن حساب PayTabs، وتثبيتُها هنا يعني نسخةً جديدة على
/// المتجر عند كلّ تبديل — ومراجعةَ أبل معها. وهو نفس المبدأ المكتوب في
/// `tabby_checkout_service`.
@immutable
class ApplePayConfigModel {
  const ApplePayConfigModel({
    required this.available,
    required this.merchantIdentifier,
    required this.displayName,
    required this.countryCode,
    required this.currencyCode,
    required this.supportedNetworks,
    required this.merchantCapabilities,
  });

  /// ‼️ **الحاكم الوحيد لعرض الزرّ**: الخادم يجمع فيه شرطين — أنّ آبل باي
  /// مفعَّلةٌ للمتجر، وأنّ PayTabs مُهيّأةٌ فعلاً. وعرضُ زرٍّ بلا هذا يعني
  /// شريحةً تُفتَح ثمّ يُرفض الدفع بعد بصمة العميل — وهو أسوأ من غياب الزرّ.
  final bool available;

  final String merchantIdentifier;
  final String displayName;
  final String countryCode;
  final String currencyCode;

  /// أسماء الشبكات كما تفهمها آبل: `mada` · `visa` · `masterCard` · `amex`.
  final List<String> supportedNetworks;

  /// عادةً `supports3DS` — وهي **شرطٌ لا خيار** لدى مصدري البطاقات السعُدّة.
  final List<String> merchantCapabilities;

  static const empty = ApplePayConfigModel(
    available: false,
    merchantIdentifier: '',
    displayName: '',
    countryCode: 'SA',
    currencyCode: 'SAR',
    supportedNetworks: <String>[],
    merchantCapabilities: <String>[],
  );

  /// ‼️ **لا ترمي**: إعدادٌ تالف أو نقطةٌ لا تردّ ⇒ `available: false` ⇒ يختفي
  /// الزرّ وحده، ولا تسقط شاشة الدفع كلّها لأجل وسيلةٍ واحدة.
  factory ApplePayConfigModel.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic raw) => raw is List
        ? raw
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final merchantId = json['merchantIdentifier']?.toString().trim() ?? '';
    return ApplePayConfigModel(
      // مُعرّفٌ فارغ = لا شريحة مهما قال العلَم: `PKPaymentRequest` بلا مُعرّفٍ
      // يُرفَض من النظام نفسه.
      available: json['available'] == true && merchantId.isNotEmpty,
      merchantIdentifier: merchantId,
      displayName: json['displayName']?.toString().trim() ?? 'Tint',
      countryCode: json['countryCode']?.toString().trim() ?? 'SA',
      currencyCode: json['currencyCode']?.toString().trim() ?? 'SAR',
      supportedNetworks: strings(json['supportedNetworks']),
      merchantCapabilities: strings(json['merchantCapabilities']),
    );
  }

  /// إعداد حزمة `pay` — تُبنى من ردّ الخادم لا من ملفٍّ في الأصول.
  Map<String, dynamic> toPayPluginConfig() => {
        'provider': 'apple_pay',
        'data': {
          'merchantIdentifier': merchantIdentifier,
          'displayName': displayName,
          'merchantCapabilities': merchantCapabilities.isEmpty
              ? const ['3DS']
              : merchantCapabilities
                  // ‼️ آبل تسمّيها `3DS` في `PKMerchantCapability`، والخادم
                  //    يقولها بلغة الويب `supports3DS`. والاسمان لشيءٍ واحد،
                  //    وتمريرُ اسم الويب كما هو يُنتج شريحةً لا تُفتَح.
                  .map((c) => c == 'supports3DS' ? '3DS' : c)
                  .toList(growable: false),
          'supportedNetworks': supportedNetworks,
          'countryCode': countryCode,
          'currencyCode': currencyCode,
        },
      };
}
