import 'package:firebase_analytics/firebase_analytics.dart';

import '../models/product_model.dart';
import 'tracking_service.dart';

/// أحداث القمع — **أسماؤها ومعاملاتها مطابقةٌ حرفيّاً لمخطّط المنصّة**.
///
/// ‼️ **الواجهة المُهيكلة لا `logEvent` العامّة.** أحداث التجارة تحمل `items`،
/// و`logEvent` ترفض أيّ قيمةٍ ليست نصّاً أو رقماً — بتأكيدٍ صريح يُسقط النداء
/// (رُصد على المحاكي 2026-08-13، ولم يكشفه فحصٌ ولا اختبار). فالدوالّ
/// المُهيكلة هي الطريق الوحيد، وتمرّ كلّها ببوّابة `guarded`.
///
/// ‼️ **ولا حدث جديد يُخترَع هنا.** التكليف: «أيّ حدث جديد يُعتمد مركزيّاً قبل
/// تنفيذه». فما ليس في القائمة لا يُطلَق ولو بدا مفيداً.
///
/// ‼️ **ولا بياناتٍ شخصيّة في أيّ معامل** — يحرسه `tracking_no_pii_test`.
extension TrackingEvents on TrackingService {
  /// عنصرٌ واحد بصيغة GA4.
  ///
  /// ‼️ **`itemId` معرّف الكتالوج لا رمز SKU**: هو ما يربط الحدث بالطلب في
  /// الخادم وبالمنتج في التقارير، و`sku` قد يكون فارغاً لكثيرٍ من المنتجات.
  static AnalyticsEventItem item(ProductModel product, {int quantity = 1}) {
    return AnalyticsEventItem(
      itemId: product.id,
      itemName: product.title,
      itemBrand: product.brand.isEmpty ? null : product.brand,
      itemCategory: product.category.isEmpty ? null : product.category,
      price: product.price,
      quantity: quantity,
      currency: 'SAR',
    );
  }

  /// مفاتيح العنصر المعتمدة — يقرؤها الحارس الآليّ.
  static Map<String, Object?> itemFields(ProductModel product, {int quantity = 1}) {
    final row = item(product, quantity: quantity);
    return {
      'item_id': row.itemId,
      'item_name': row.itemName,
      'item_brand': row.itemBrand,
      'item_category': row.itemCategory,
      'price': row.price,
      'quantity': row.quantity,
      'currency': row.currency,
    };
  }

  static double total(List<AnalyticsEventItem> items) {
    var sum = 0.0;
    for (final row in items) {
      sum += (row.price ?? 0) * (row.quantity ?? 1);
    }
    // تقريبٌ إلى هللتين: جمع `double` يُنتج 149.99999999 فيبدو المبلغ مريباً.
    return double.parse(sum.toStringAsFixed(2));
  }

  Future<void> logViewItemList({
    required String listId,
    required String listName,
    required List<ProductModel> products,
  }) {
    // ‼️ حدٌّ عند ٢٠: GA4 يقصّ ما زاد، ورفٌّ بمئة منتجٍ يُضخّم الحمولة بلا فائدة.
    final items = products.take(20).map((p) => item(p)).toList();
    if (items.isEmpty) return Future<void>.value();
    return guarded((a) => a.logViewItemList(
          itemListId: listId,
          itemListName: listName,
          items: items,
        ));
  }

  Future<void> logViewItem(ProductModel product) {
    final items = [item(product)];
    return guarded((a) => a.logViewItem(
          currency: 'SAR',
          value: total(items),
          items: items,
        ));
  }

  Future<void> logAddToCart(ProductModel product, {int quantity = 1}) {
    final items = [item(product, quantity: quantity)];
    return guarded((a) => a.logAddToCart(
          currency: 'SAR',
          value: total(items),
          items: items,
        ));
  }

  Future<void> logRemoveFromCart(ProductModel product, {int quantity = 1}) {
    final items = [item(product, quantity: quantity)];
    return guarded((a) => a.logRemoveFromCart(
          currency: 'SAR',
          value: total(items),
          items: items,
        ));
  }

  Future<void> logViewCart(List<AnalyticsEventItem> items) {
    if (items.isEmpty) return Future<void>.value();
    return guarded((a) => a.logViewCart(
          currency: 'SAR',
          value: total(items),
          items: items,
        ));
  }

  Future<void> logBeginCheckout(List<AnalyticsEventItem> items) {
    if (items.isEmpty) return Future<void>.value();
    return guarded((a) => a.logBeginCheckout(
          currency: 'SAR',
          value: total(items),
          items: items,
        ));
  }

  /// ‼️ **`shippingTier` اسمُ الطريقة لا سعرها**: GA4 يُجمّع عليه، وسعرٌ مكان
  /// الاسم يُنتج تقريراً بمئة «فئة شحن» لا معنى لها.
  Future<void> logAddShippingInfo({
    required String tier,
    required List<AnalyticsEventItem> items,
  }) {
    if (items.isEmpty) return Future<void>.value();
    return guarded((a) => a.logAddShippingInfo(
          currency: 'SAR',
          value: total(items),
          shippingTier: tier,
          items: items,
        ));
  }

  Future<void> logAddPaymentInfo({
    required String paymentType,
    required List<AnalyticsEventItem> items,
  }) {
    if (items.isEmpty) return Future<void>.value();
    return guarded((a) => a.logAddPaymentInfo(
          currency: 'SAR',
          value: total(items),
          paymentType: paymentType,
          items: items,
        ));
  }

  /// ‼️ **نصّ البحث قد يحمل بياناً شخصيّاً** (يبحث أحدهم باسمه أو جوّاله).
  /// فيُقصّ عند ١٠٠ حرف: تجزئتُه تُفقده معناه التحليليّ، ومنعُه كلّيّاً يُفقد
  /// أهمّ إشارة نيّةٍ في المتجر.
  Future<void> logSearch(String term) {
    final value = term.trim();
    if (value.isEmpty) return Future<void>.value();
    return guarded(
      (a) => a.logSearch(searchTerm: value.substring(0, value.length.clamp(0, 100))),
    );
  }

  /// ‼️ **`method` وسيلة الدخول لا هويّة الداخل**: `otp` لا رقم الجوّال.
  Future<void> logLogin({String method = 'otp'}) {
    return guarded((a) => a.logLogin(loginMethod: method));
  }
}
