import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  // الوسيط: يُرسل الرمز إلى البريد (الجوّال هو الهويّة). { ok, phone, email, ttl, channel }
  Future<Map<String, dynamic>> requestOtp({
    required String phone,
    required String email,
  }) {
    return _apiClient.postMap(
      ApiRoutes.authRequestOtp,
      data: {'phone': phone, 'email': email},
    );
  }

  // الوسيط: { ok, token, customer:{ phone, name, email } }
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) {
    return _apiClient.postMap(
      ApiRoutes.authVerifyOtp,
      data: {'phone': phone, 'code': code},
    );
  }
}
