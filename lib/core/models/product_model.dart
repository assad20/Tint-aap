class ProductModel {
  const ProductModel({
    required this.id,
    required this.brand,
    required this.title,
    required this.price,
    required this.image,
    required this.category,
    this.oldPrice,
    this.tag,
    this.views,
    this.isAvailable = true,
    this.sku,
    this.barcode,
    this.quantity,
  });

  final String id;
  final String brand;
  final String title;
  final double price;
  final double? oldPrice;
  final String image;
  final String category;
  final String? tag;
  final String? views;
  final bool isAvailable;
  // السكيو والباركود (يُستخدمان في توصيات المستشار لعرض رمز المنتج).
  final String? sku;
  final String? barcode;

  /// الكميّة المتاحة كما يقولها الخادم.
  ///
  /// ‼️ `null` = **صنف غير متتبَّع** (الحقل غائب من الاستجابة) ⇒ لا يُحجب.
  /// و`0` = **نفد فعلاً** ⇒ يُحجب. كان النوع `int` بافتراضيّ `0`، فيمتزج
  /// المعنيان ويصير النفاد غير قابلٍ للتمييز — ولذلك كان مكتوباً أنّ «0 تعني
  /// لم يُزامَن المخزون فلا تُعرض كنفاد». ذاك صحّ حين كان حارس المخزون مُطفأً؛
  /// وهو مُفعَّل الآن ويرفض الطلب، فصار الصمت يعني مشترياً يدفع ثمّ يُرفض.
  ///
  /// هذه هي قاعدة الخادم نفسها (`typeof doc.quantity === 'number'`).
  final int? quantity;

  /// نفد فعلاً — لا «غير متتبَّع».
  bool get isSoldOut => quantity != null && quantity! <= 0;

  /// يقارب النفاد: تُعرض «بقي N» عند 1..5 فقط.
  bool get isLowStock => quantity != null && quantity! > 0 && quantity! <= 5;

  double? get discountPercent {
    if (oldPrice == null || oldPrice == 0) {
      return null;
    }
    return ((oldPrice! - price) / oldPrice!) * 100;
  }

  ProductModel copyWith({
    String? id,
    String? brand,
    String? title,
    double? price,
    double? oldPrice,
    String? image,
    String? category,
    String? tag,
    String? views,
    bool? isAvailable,
    String? sku,
    String? barcode,
    int? quantity,
  }) {
    return ProductModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      title: title ?? this.title,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      image: image ?? this.image,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      views: views ?? this.views,
      isAvailable: isAvailable ?? this.isAvailable,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double? parseNullableNum(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      oldPrice: parseNullableNum(json['oldPrice']),
      image: json['image']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tag: json['tag']?.toString(),
      views: json['views']?.toString(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      // بلا `?? 0`: غياب الحقل يبقى `null` (غير متتبَّع) ولا يُقرأ نفاداً.
      quantity: json['quantity'] == null
          ? null
          : int.tryParse(json['quantity'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'title': title,
      'price': price,
      'oldPrice': oldPrice,
      'image': image,
      'category': category,
      'tag': tag,
      'views': views,
      'isAvailable': isAvailable,
      'sku': sku,
      'barcode': barcode,
      'quantity': quantity,
    };
  }
}
