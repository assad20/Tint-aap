class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.shortName,
  });

  final String id;
  final String name;
  final String image;
  // اسم مختصر للعرض في القوائم (من الأدمن)؛ يُرسَل فقط حين يكون مفعّلاً.
  final String? shortName;

  // الاسم المعروض في القوائم: المختصر إن وُجد، وإلا الاسم الحقيقيّ.
  String get displayName =>
      (shortName != null && shortName!.trim().isNotEmpty)
          ? shortName!.trim()
          : name;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      shortName: json['shortName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      if (shortName != null) 'shortName': shortName,
    };
  }
}
