import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class AccountRemoteDataSource {
  AccountRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchProfileBundle() {
    return _apiClient.getMap(ApiRoutes.dashboard);
  }

  Future<Map<String, dynamic>> fetchRewardsBundle() {
    return _apiClient.getMap(ApiRoutes.rewards);
  }

  Future<List<dynamic>> fetchOrders() {
    return _apiClient.getList(ApiRoutes.orders);
  }

  Future<List<dynamic>> fetchFavorites() {
    return _apiClient.getList(ApiRoutes.favorites);
  }

  Future<List<dynamic>> fetchAddresses() {
    return _apiClient.getList(ApiRoutes.addresses);
  }
}
