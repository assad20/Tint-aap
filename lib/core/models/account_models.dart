import 'product_model.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.name,
    required this.phone,
    required this.membershipTier,
    required this.avatarUrl,
    required this.points,
    required this.couponsCount,
    required this.walletBalance,
  });

  final String name;
  final String phone;
  final String membershipTier;
  final String avatarUrl;
  final int points;
  final int couponsCount;
  final double walletBalance;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      membershipTier: json['membershipTier']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      points: int.tryParse(json['points'].toString()) ?? 0,
      couponsCount: int.tryParse(json['couponsCount'].toString()) ?? 0,
      walletBalance: double.tryParse(json['walletBalance'].toString()) ?? 0,
    );
  }
}

class PaymentCardModel {
  const PaymentCardModel({
    required this.id,
    required this.label,
    required this.maskedNumber,
    required this.brand,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String maskedNumber;
  final String brand;
  final bool isDefault;

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      maskedNumber: json['maskedNumber']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class RewardTransactionModel {
  const RewardTransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.points,
    required this.dateLabel,
    required this.status,
  });

  final int id;
  final String type;
  final String title;
  final String points;
  final String dateLabel;
  final String status;

  factory RewardTransactionModel.fromJson(Map<String, dynamic> json) {
    return RewardTransactionModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? 'earn',
      title: json['title']?.toString() ?? '',
      points: json['points']?.toString() ?? '',
      dateLabel: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class CouponModel {
  const CouponModel({
    required this.id,
    required this.title,
    required this.code,
    required this.subtitle,
    this.badge,
  });

  final String id;
  final String title;
  final String code;
  final String subtitle;
  final String? badge;

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      badge: json['badge']?.toString(),
    );
  }
}

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.amountLabel,
  });

  final String id;
  final String title;
  final String dateLabel;
  final String amountLabel;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      dateLabel: json['date']?.toString() ?? '',
      amountLabel: json['amount']?.toString() ?? '',
    );
  }
}

class AddressModel {
  const AddressModel({
    required this.id,
    required this.title,
    required this.recipient,
    required this.mobile,
    required this.city,
    required this.neighborhood,
    required this.details,
    required this.isDefault,
    this.extraDetails,
    this.shortCode,
    this.buildingNumber,
    this.postalCode,
    this.lat,
    this.lng,
  });

  final String id;
  final String title;
  final String recipient;
  final String mobile;
  final String city;
  final String neighborhood;
  final String details;
  final bool isDefault;

  /// ما يكتبه العميل بيده: الدور · رقم الشقّة · معلمٌ قريب.
  ///
  /// ‼️ **منفصلٌ عن `details` عمداً**: الأوّل يُملأ من الخريطة **ويُقفَل** حتّى
  /// لا يناقض النصُّ إحداثيّاته، والخريطة لا تعرف الدور ولا رقم الشقّة — وهي
  /// أهمّ ما يقرؤه المندوب بعد الرمز الوطنيّ. ودمجُهما يعني إمّا قفلاً يمنع
  /// العميل من كتابة شقّته، أو فتحاً يجعله يمحو ما استنبطته الخريطة.
  final String? extraDetails;

  /// العنوان الوطنيّ المختصر ورقم المبنى والرمز البريديّ — **يُحفَظ الآن**.
  ///
  /// ‼️ كان يُشتقّ من الإحداثيّات ويُعرَض في نافذة الخريطة ثمّ **يضيع عند
  /// الحفظ**، فيغيب عن بطاقة العنوان وعن الطلب. واشتقاقُه عند كلّ عرضٍ بديلٌ
  /// سيّئ: نداءُ غوغل لكلّ بطاقةٍ في كلّ فتحة يستنزف الحصّة ويتأخّر ويفشل بلا
  /// شبكة — لأجل نصٍّ لا يتغيّر.
  ///
  /// ‼️ **واختياريّة**: عناوينٌ حُفظت قبل اليوم لا تحملها.
  final String? shortCode;
  final String? buildingNumber;
  final String? postalCode;

  final double? lat;
  final double? lng;

  /// سطر العنوان كما يُكتب: «2868 طريق العروبة، العليا، الرياض».
  ///
  /// ‼️ **رقم المبنى يُصدَّر التفاصيل ولا يُفصَل عنها** — هو أوّل ما يبحث عنه
  /// المندوب على الباب، وفصلُه يجعله يضيع حين يُنسَخ العنوان سطراً واحداً.
  String get line {
    final d = details.trim();
    final b = buildingNumber?.trim() ?? '';
    /// ‼️ **لا يُضاف رقم المبنى إن كان في التفاصيل أصلاً.**
    ///
    /// حقل التفاصيل يُملأ من الخريطة بـ«2868 طريق العروبة» (الرقم مُصدَّرٌ
    /// عمداً)، فإضافته هنا ثانيةً تُنتج **«2868 2868 طريق العروبة»** — رُصد
    /// على المحاكي 2026-08-26. والمصدر واحدٌ فالإضافة تقع مرّةً واحدة.
    final street = (b.isNotEmpty && !d.startsWith(b)) ? '$b $d'.trim() : d;
    return [
      street.isEmpty ? null : street,
      neighborhood.trim().isEmpty ? null : neighborhood.trim(),
      city.trim().isEmpty ? null : city.trim(),
    ].whereType<String>().join('، ');
  }

  /// الرمز الوطنيّ والبريديّ معاً — `null` إن لم يُعرَف أيٌّ منهما.
  String? get codesLine {
    final parts = [shortCode?.trim(), postalCode?.trim()]
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  AddressModel copyWith({
    String? id,
    String? title,
    String? recipient,
    String? mobile,
    String? city,
    String? neighborhood,
    String? details,
    bool? isDefault,
    String? extraDetails,
    String? shortCode,
    String? buildingNumber,
    String? postalCode,
    double? lat,
    double? lng,
  }) {
    return AddressModel(
      id: id ?? this.id,
      title: title ?? this.title,
      recipient: recipient ?? this.recipient,
      mobile: mobile ?? this.mobile,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
      extraDetails: extraDetails ?? this.extraDetails,
      shortCode: shortCode ?? this.shortCode,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      postalCode: postalCode ?? this.postalCode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      recipient: json['recipient']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      extraDetails: json['extraDetails']?.toString(),
      shortCode: json['shortCode']?.toString(),
      buildingNumber: json['buildingNumber']?.toString(),
      postalCode: json['postalCode']?.toString(),
      lat: json['lat'] == null ? null : double.tryParse(json['lat'].toString()),
      lng: json['lng'] == null ? null : double.tryParse(json['lng'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'recipient': recipient,
      'mobile': mobile,
      'city': city,
      'neighborhood': neighborhood,
      'details': details,
      'isDefault': isDefault,
      /**
       * ‼️ **تُرسَل ولو فارغةً — بخلاف الإحداثيّات.**
       *
       * الفارغ هنا **قيمةٌ ذات معنى**: نقل الدبّوس إلى موضعٍ لا تعرف غوغل له
       * رمزاً وطنيّاً يجب أن **يمحو** الرمز القديم. وحذفُ الحقل عند فراغه
       * يُبقي رمزاً يخصّ مبنًى آخر — عنوانٌ يناقض إحداثيّاته، وهو أسوأ من
       * عنوانٍ ناقص.
       */
      'extraDetails': extraDetails ?? '',
      'shortCode': shortCode ?? '',
      'buildingNumber': buildingNumber ?? '',
      'postalCode': postalCode ?? '',
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }
}

enum OrderStatus { processing, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.processing:
        return 'قيد المعالجة';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'ملغاة';
    }
  }

  String get key {
    switch (this) {
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromKey(String value) {
    return switch (value) {
      'processing' => OrderStatus.processing,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.processing,
    };
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.product,
    required this.qty,
    required this.variant,
  });

  final ProductModel product;
  final int qty;
  final String variant;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // الخادم (/customer/orders) يرجع السطر مسطّحاً: {sku, qty, price, title, image}
    // — لا كائن product متداخل. ندعم الشكلين تفادياً للتعطّل.
    final nested = json['product'];
    final product = nested is Map<String, dynamic>
        ? ProductModel.fromJson(nested)
        : ProductModel.fromJson({
            'id': json['sku']?.toString() ?? '',
            'brand': (json['brand'] ?? '').toString(),
            'title': (json['title'] ?? json['sku'] ?? '').toString(),
            'price': json['price'] ?? 0,
            'image': (json['image'] ?? '').toString(),
          });
    return OrderItemModel(
      product: product,
      qty: int.tryParse(json['qty'].toString()) ?? 1,
      variant: json['variant']?.toString() ?? '',
    );
  }
}

/// شحنة الطلب كما يُرسلها الخادم للعميل.
///
/// ‼️ **كان الخادم يُرسلها والتطبيق يُهملها بصمت.** الموقع يعرض للمشتري رقم
/// البوليصة ورابط التتبّع، والتطبيق يعرض شريط حالةٍ عامّاً لا أكثر — فمن يشتري
/// من التطبيق لا يعرف رقم شحنته ولا يستطيع متابعتها عند الناقل. لا خطأ، ولا
/// حقل ناقص في أيّ سجلّ: مجرّد بيانٍ يصل ولا يُقرأ.
///
/// ‼️ **ولا يُذكر اسم الناقل للعميل**: قرار التاجر أن يبقى مخفيّاً (نمط شي إن)،
/// والخادم يُرسله لأنّ اللوحة تحتاجه. فيُقرأ هنا ولا يُعرَض.
class OrderShipmentModel {
  const OrderShipmentModel({
    this.awbNumber = '',
    this.trackingUrl = '',
    this.status = '',
  });

  final String awbNumber;
  final String trackingUrl;
  final String status;

  /// لا يُعرَض شيءٌ ما لم يكن هناك ما يُعرَض فعلاً.
  bool get hasAnything => awbNumber.isNotEmpty || trackingUrl.isNotEmpty;

  static OrderShipmentModel? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final row = OrderShipmentModel(
      awbNumber: raw['awbNumber']?.toString() ?? '',
      trackingUrl: raw['trackingUrl']?.toString() ?? '',
      status: raw['status']?.toString() ?? '',
    );
    return row.hasAnything ? row : null;
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.dateLabel,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.address,
    required this.paymentMethod,
    this.shipment,
  });

  final String id;
  final String dateLabel;
  final OrderStatus status;
  final List<OrderItemModel> items;
  final double subtotal;
  final double shipping;
  final double total;
  final String address;
  final String paymentMethod;

  /// الشحنة حين يُنشئها التاجر — وإلّا `null`.
  final OrderShipmentModel? shipment;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      dateLabel: json['date']?.toString() ?? '',
      status: OrderStatusX.fromKey(json['status']?.toString() ?? 'processing'),
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList(),
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      shipping: double.tryParse(json['shipping'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      address: json['address']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      shipment: OrderShipmentModel.fromJson(json['shipment']),
    );
  }
}

class SizeProfileModel {
  const SizeProfileModel({
    required this.id,
    required this.title,
    required this.dressSize,
    required this.abayaSize,
    required this.notes,
  });

  final String id;
  final String title;
  final String dressSize;
  final String abayaSize;
  final String notes;

  factory SizeProfileModel.fromJson(Map<String, dynamic> json) {
    return SizeProfileModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      dressSize: json['dressSize']?.toString() ?? '',
      abayaSize: json['abayaSize']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class GiftCardModel {
  const GiftCardModel({
    required this.id,
    required this.title,
    required this.balanceLabel,
    required this.code,
    required this.expiryLabel,
  });

  final String id;
  final String title;
  final String balanceLabel;
  final String code;
  final String expiryLabel;

  factory GiftCardModel.fromJson(Map<String, dynamic> json) {
    return GiftCardModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      balanceLabel: json['balanceLabel']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      expiryLabel: json['expiryLabel']?.toString() ?? '',
    );
  }
}

class StockAlertModel {
  const StockAlertModel({
    required this.productId,
    required this.title,
    required this.image,
    required this.notified,
  });

  /// `tintId` — نفس المفتاح الذي يُفتح به المنتج ويُلغى به التنبيه.
  final String productId;

  /// ‼️ **لقطةٌ من الاسم والصورة لا قراءةٌ من الكتالوج.** الشاشة قائمة، وقراءةُ
  /// منتجٍ لكلّ سطرٍ تعني رحلةً لكلّ صفّ.
  final String title;
  final String image;

  /// أُرسل الإشعار فعلاً — فيُعرَض الصفّ «عاد للتوفّر» لا «ينتظر».
  final bool notified;

  factory StockAlertModel.fromJson(Map<String, dynamic> json) {
    return StockAlertModel(
      productId: json['productId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      notified: json['notified'] == true,
    );
  }
}


class ProfileBundle {
  const ProfileBundle({
    required this.profile,
    required this.paymentCards,
    required this.browsingHistory,
    required this.sizeProfiles,
    required this.giftCards,
    required this.stockAlerts,
  });

  final UserProfileModel profile;
  final List<PaymentCardModel> paymentCards;
  final List<ProductModel> browsingHistory;
  final List<SizeProfileModel> sizeProfiles;
  final List<GiftCardModel> giftCards;
  final List<StockAlertModel> stockAlerts;
}

class RewardsBundle {
  const RewardsBundle({
    required this.availablePoints,
    required this.pendingPoints,
    required this.usedPoints,
    required this.walletBalance,
    required this.history,
    required this.coupons,
    required this.walletTransactions,
  });

  final int availablePoints;
  final int pendingPoints;
  final int usedPoints;
  final double walletBalance;
  final List<RewardTransactionModel> history;
  final List<CouponModel> coupons;
  final List<WalletTransactionModel> walletTransactions;
}
