import 'product_model.dart';

/// تبويب قسمٍ في أعلى شاشة الترندات. `slug` = 'all' للتبويب الجامع.
class DiscoverTab {
  const DiscoverTab({required this.slug, required this.name});

  final String slug;
  final String name;

  factory DiscoverTab.fromJson(Map<String, dynamic> json) => DiscoverTab(
        slug: json['slug']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

/// رفٌّ واحد. الخادم لا يرسل رفّاً دون أربعة عناصر، فوجوده هنا يعني أنّ خلفه
/// إشارةً حقيقيّة — لا حاجة لأن تُقرّر الواجهة إخفاءه.
class DiscoverSection {
  const DiscoverSection({
    required this.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.hasMore = false,
  });

  final String key;
  final String title;
  final String? subtitle;
  final List<ProductModel> items;
  final bool hasMore;

  factory DiscoverSection.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return DiscoverSection(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      hasMore: json['hasMore'] == true,
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList()
          : const <ProductModel>[],
    );
  }
}

class DiscoverFeed {
  const DiscoverFeed({
    this.tabs = const [],
    this.sections = const [],
    this.activeCategory = 'all',
  });

  final List<DiscoverTab> tabs;
  final List<DiscoverSection> sections;
  final String activeCategory;

  bool get isEmpty => sections.isEmpty;

  factory DiscoverFeed.fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(dynamic v, T Function(Map<String, dynamic>) parse) =>
        v is List ? v.whereType<Map<String, dynamic>>().map(parse).toList() : <T>[];
    return DiscoverFeed(
      tabs: listOf(json['tabs'], DiscoverTab.fromJson),
      sections: listOf(json['sections'], DiscoverSection.fromJson),
      activeCategory: json['activeCategory']?.toString() ?? 'all',
    );
  }
}

/// صفحةٌ من رفٍّ واحد — تُغذّي شاشة «عرض الكل» وتمريرها اللانهائيّ.
class DiscoverSectionPage {
  const DiscoverSectionPage({
    required this.title,
    required this.items,
    this.page = 1,
    this.hasMore = false,
  });

  final String title;
  final List<ProductModel> items;
  final int page;
  final bool hasMore;

  factory DiscoverSectionPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return DiscoverSectionPage(
      title: json['title']?.toString() ?? '',
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      hasMore: json['hasMore'] == true,
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList()
          : const <ProductModel>[],
    );
  }
}

/// نوع التفاعل المُرسَل إلى `/catalog/events` — وقود رفّ «الأكثر رواجاً».
enum ProductSignalType { view, cart, wishlist }

extension ProductSignalTypeWire on ProductSignalType {
  String get wire => switch (this) {
        ProductSignalType.view => 'view',
        ProductSignalType.cart => 'cart',
        ProductSignalType.wishlist => 'wishlist',
      };
}
