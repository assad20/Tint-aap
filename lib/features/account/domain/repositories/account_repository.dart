import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';

abstract class AccountRepository {
  Future<ProfileBundle> fetchProfileBundle();

  /// ‼️ **شرط أبل 5.1.1(v)**: ما يُنشَأ من داخل التطبيق يُحذَف من داخله.
  /// وغيابُه رفضٌ مؤكّد في المراجعة لا احتمال.
  Future<void> deleteAccount();

  Future<RewardsBundle> fetchRewardsBundle();

  Future<List<OrderModel>> fetchOrders();

  Future<List<ProductModel>> fetchFavorites();

  // تُعيدان القائمة المحدَّثة، و`null` عند الفشل (أبقِ المعروض).
  Future<List<ProductModel>?> addFavorite(String productId);
  Future<List<ProductModel>?> removeFavorite(String productId);

  Future<List<AddressModel>> fetchAddresses();
}
