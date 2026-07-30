class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.images = const [],
    this.shortName,
  });

  final String id;
  final String name;
  final String image;
  /// صور إضافيّة تتبدّل في بطاقة القسم. يُرسلها الخادم فقط حين تتجاوز
  /// الواحدة، فالقسم بصورةٍ واحدة يبقى ثابتاً كما كان.
  final List<String> images;
  // اسم مختصر للعرض في القوائم (من الأدمن)؛ يُرسَل فقط حين يكون مفعّلاً.
  final String? shortName;

  // الاسم المعروض في القوائم: المختصر إن وُجد، وإلا الاسم الحقيقيّ.
  String get displayName =>
      (shortName != null && shortName!.trim().isNotEmpty)
          ? shortName!.trim()
          : name;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['images'];
    final images = raw is List
        ? raw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
        : const <String>[];
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      images: images,
      shortName: json['shortName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      if (images.isNotEmpty) 'images': images,
      if (shortName != null) 'shortName': shortName,
    };
  }

  /// صور العرض مرتّبةً: `images` إن وُجدت، وإلّا الصورة المفردة.
  List<String> get displayImages => images.isNotEmpty ? images : [image];
}
