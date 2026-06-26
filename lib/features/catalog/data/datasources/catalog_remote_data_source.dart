import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchBootstrapCatalog() {
    return _apiClient.getMap(ApiRoutes.catalogBootstrap);
  }

  Future<List<dynamic>> fetchTrendingProducts() {
    return _apiClient.getList(ApiRoutes.catalogTrends);
  }

  Future<List<dynamic>> searchProducts(String query) {
    return _apiClient.getList(
      ApiRoutes.catalogSearch,
      queryParameters: {'q': query},
    );
  }
}
