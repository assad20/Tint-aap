import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_mobile/core/models/product_model.dart';
import 'package:tint_mobile/features/cart/presentation/cubit/cart_cubit.dart';

/// بقاء السلّة بعد إغلاق التطبيق.
///
/// ‼️ الحادثة: السلّة كانت في الذاكرة وحدها. من يجمع خمسة منتجات ثمّ يُغلق
/// التطبيق ليردّ على مكالمة يعود فيجدها فارغة — فيُعيد الجمع أو يترك الشراء.
/// ولا خطأ يظهر، بل «متجرٌ نسي ما اخترتُه».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProductModel product(String id) => ProductModel.fromJson({
        'id': id,
        'title': 'منتج $id',
        'brand': 'تِنت',
        'price': 25.0,
        'image': 'https://x/$id.jpg',
        'quantity': 10,
      });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('‼️ ما يُضاف يعود بعد إعادة الإقلاع', () async {
    final first = CartCubit();
    first.addProduct(product('A'));
    first.addProduct(product('B'));
    // الحفظ يجري في `onChange` بلا انتظار — تُترك دورةٌ لينتهي.
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final revived = CartCubit();
    await revived.restore();

    expect(revived.state.items.length, 2);
    expect(revived.state.items.map((i) => i.product.id).toSet(), {'A', 'B'});
  });

  test('‼️ الكميّة تُحفظ لا العدد وحده', () async {
    final first = CartCubit();
    first.addProduct(product('A'));
    first.addProduct(product('A')); // نفس المنتج ⇒ كميّة 2
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final revived = CartCubit();
    await revived.restore();

    expect(revived.state.items.length, 1);
    expect(revived.state.items.first.quantity, 2);
  });

  test('‼️ الإفراغ يُمحى ولا يعود', () async {
    // حفظٌ يُضاف عند الإضافة وينسى الحذف يُنتج سلّةً تتذكّر ما أُلغي — وهو
    // أسوأ من ألّا تحفظ: المشتري يجد ما حذفه عائداً.
    final first = CartCubit();
    first.addProduct(product('A'));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    first.clear();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final revived = CartCubit();
    await revived.restore();
    expect(revived.state.items, isEmpty);
  });

  test('بيانات محفوظة تالفة لا تُسقط الإقلاع', () async {
    SharedPreferences.setMockInitialValues({'tint_cart_v1': 'ليست JSON'});
    final cubit = CartCubit();
    await cubit.restore();
    expect(cubit.state.items, isEmpty);
  });
}
