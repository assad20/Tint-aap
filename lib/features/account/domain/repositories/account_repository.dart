import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';

abstract class AccountRepository {
  Future<ProfileBundle> fetchProfileBundle();

  Future<RewardsBundle> fetchRewardsBundle();

  Future<List<OrderModel>> fetchOrders();

  Future<List<ProductModel>> fetchFavorites();

  Future<List<AddressModel>> fetchAddresses();
}
