import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/product_model.dart';
import 'package:tint_mobile/core/tracking/tracking_events.dart';

/// حارس «لا بياناتٍ شخصيّة في أحداث القياس».
///
/// ‼️ **لماذا حارسٌ آليّ لا مراجعةٌ بالعين؟** لأنّ خطأه **لا يُلاحَظ أبداً**:
/// حدثٌ يحمل جوّالاً يُقبَل في Firebase ويُخزَّن ويبدو كلّ شيءٍ سليماً — ولا
/// يُحذف بعدها إلّا بطلبٍ رسميّ. والقاعدة الأولى في التكليف تمنعه صراحةً.
///
/// ‼️ **ويحرس الشكل لا النيّة**: يفحص المفاتيح المسموح بها في `items`، فأيّ
/// حقلٍ يُضاف مستقبلاً (`customer_phone` مثلاً) يُسقط الاختبار فوراً بدل أن
/// يمرّ في مراجعةٍ عجلى.
void main() {
  final product = ProductModel(
    id: 'p-1',
    brand: 'NIVEA',
    title: 'كريم ترطيب',
    price: 17.0,
    image: '',
    category: 'skincare',
    isAvailable: true,
  );

  /// المفاتيح المعتمدة في عنصر GA4 — ولا شيء غيرها.
  const allowed = {
    'item_id',
    'item_name',
    'item_brand',
    'item_category',
    'price',
    'quantity',
    'currency',
  };

  group('عنصر القياس', () {
    test('‼️ لا يحمل إلّا المفاتيح المعتمدة', () {
      final row = TrackingEvents.itemFields(product);
      final extra = row.keys.toSet().difference(allowed);
      expect(
        extra,
        isEmpty,
        reason: 'حقلٌ غير معتمد في عنصر GA4: $extra — يُعتمد مركزيّاً قبل إضافته',
      );
    });

    test('‼️ لا يحمل نصّاً يشبه جوّالاً أو بريداً', () {
      final row = TrackingEvents.itemFields(product);
      final blob = row.values.map((v) => v ?? '').join(' ');
      expect(RegExp(r'\b(?:\+?966|05)\d{7,}').hasMatch(blob), isFalse,
          reason: 'يشبه رقم جوّال');
      expect(RegExp(r'[\w.\-]+@[\w\-]+\.\w+').hasMatch(blob), isFalse,
          reason: 'يشبه بريداً إلكترونيّاً');
    });

    test('العملة SAR في العنصر نفسه', () {
      expect(TrackingEvents.itemFields(product)['currency'], 'SAR');
    });

    test('الكميّة تُحترَم', () {
      expect(TrackingEvents.itemFields(product, quantity: 3)['quantity'], 3);
    });

    test('‼️ `item_id` معرّف الكتالوج لا رمز SKU', () {
      // الخادم يربط الحدث بالطلب بهذا المعرّف، و`sku` قد يكون فارغاً أصلاً.
      expect(TrackingEvents.itemFields(product)['item_id'], 'p-1');
    });
  });
}
