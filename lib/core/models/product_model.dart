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
    };
  }
}
