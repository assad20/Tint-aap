// شريحة سلايدر — صورة + وجهة اختياريّة. تأتي من بنرات الأدمن
// (`hero` للرئيسيّة، و`category:<slug>` لصفحة القسم).
class HeroSlideModel {
  const HeroSlideModel({required this.image, this.href = ''});

  final String image;
  // وجهة الويب كما يُرجعها الوسيط (مثل `/category/makeup`). تُترجم عند النقر
  // إلى تنقّل داخل التطبيق — لا تُفتح كرابط.
  final String href;

  factory HeroSlideModel.fromJson(Map<String, dynamic> json) {
    // الخادم يُعيد صورة الجوّال منفصلة عن العريضة؛ نُفضّلها إن رُفعت.
    final mobile = json['mobileImage']?.toString() ?? '';
    final wide = json['image']?.toString() ?? '';
    return HeroSlideModel(
      image: mobile.isNotEmpty ? mobile : wide,
      href: json['ctaHref']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'image': image, 'ctaHref': href};
}
