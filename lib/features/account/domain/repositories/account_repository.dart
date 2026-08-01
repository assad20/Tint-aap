import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';

abstract class AccountRepository {
  Future<ProfileBundle> fetchProfileBundle();

  Future<RewardsBundle> fetchRewardsBundle();

  Future<List<OrderModel>> fetchOrders();

  Future<List<ProductModel>> fetchFavorites();

  // تُعيدان القائمة المحدَّثة، و`null` عند الفشل (أبقِ المعروض).
  Future<List<ProductModel>?> addFavorite(String productId);
  Future<List<ProductModel>?> removeFavorite(String productId);

  Future<List<AddressModel>> fetchAddresses();
}
