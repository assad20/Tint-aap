import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class AccountRemoteDataSource {
  AccountRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchProfileBundle() {
    return _apiClient.getMap(ApiRoutes.dashboard);
  }

  /// حذف الحساب — نفس المسار بفعل `DELETE`.
  ///
  /// ‼️ **ولا رقم في الجسم**: الخادم يحذف صاحب التوكن وحده. وإرسال رقمٍ من
  /// التطبيق يعني بابَ حذفٍ لحساب غيرك بمعرفة رقمه.
  Future<Map<String, dynamic>> deleteAccount() {
    return _apiClient.deleteMap(ApiRoutes.dashboard);
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

  // النقطتان تُعيدان القائمة كاملةً بعد التعديل، فلا نداء ثانٍ للمزامنة.
  Future<List<dynamic>> addFavorite(String productId) {
    return _apiClient.postList(ApiRoutes.favorites, data: {'productId': productId});
  }

  Future<List<dynamic>> removeFavorite(String productId) {
    return _apiClient.deleteList('${ApiRoutes.favorites}/$productId');
  }

  Future<List<dynamic>> fetchAddresses() {
    return _apiClient.getList(ApiRoutes.addresses);
  }

  /// ‼️ **الكتابة كانت غائبةً كلّها.**
  ///
  /// الخادم يُعلن `POST` و`PATCH` و`DELETE` على `/customer/addresses` منذ
  /// البداية، والتطبيق لا ينادي إلّا `GET`. فكلّ عنوانٍ يُضاف أو يُعدَّل كان
  /// يعيش في ذاكرة الكيوبت وحدها **ويختفي عند أوّل إقلاع** — بلا خطأٍ يُنبّه.
  /// ‼️ **الثلاث تُعيد القائمة كاملةً لا العنوان وحده** — هكذا يردّ الخادم
  /// (`Promise<CustomerAddress[]>` في `customer.service`). وطلبُ كائنٍ منها
  /// يُسقط النداء بخطأ تحويلٍ في Dio، فتُقرأ عمليّةٌ ناجحة فشلاً في الاتّصال.
  Future<List<dynamic>> createAddress(Map<String, dynamic> body) {
    return _apiClient.postList(ApiRoutes.addresses, data: body);
  }

  Future<List<dynamic>> updateAddress(String id, Map<String, dynamic> body) {
    return _apiClient.patchList('${ApiRoutes.addresses}/$id', data: body);
  }

  Future<List<dynamic>> deleteAddress(String id) {
    return _apiClient.deleteList('${ApiRoutes.addresses}/$id');
  }

  /// تنبيهات التوفّر — الثلاثة تُعيد القائمة كاملةً.
  Future<List<dynamic>> fetchStockAlerts() {
    return _apiClient.getList(ApiRoutes.stockAlerts);
  }

  Future<List<dynamic>> addStockAlert({
    required String productId,
    required String title,
    required String image,
  }) {
    return _apiClient.postList(
      ApiRoutes.stockAlerts,
      data: {'productId': productId, 'title': title, 'image': image},
    );
  }

  Future<List<dynamic>> removeStockAlert(String productId) {
    return _apiClient.deleteList('${ApiRoutes.stockAlerts}/$productId');
  }
}
