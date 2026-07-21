import '../../../../core/storage/app_preferences.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
    required AppPreferences preferences,
  })  : _remote = remoteDataSource,
        _tokenStorage = tokenStorage,
        _preferences = preferences;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;
  final AppPreferences _preferences;

  @override
  Future<void> requestOtp({required String phone, required String email}) async {
    await _remote.requestOtp(phone: phone, email: email);
  }

  @override
  Future<AuthCustomer> verifyOtp({required String phone, required String code}) async {
    final res = await _remote.verifyOtp(phone: phone, code: code);
    final token = res['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('لم يصل توكن الدخول من الخادم.');
    }
    // ‼️ هنا يُحفظ التوكن فعلياً (كان saveToken كوداً ميّتاً) → تُفتَح مسارات /customer/*.
    await _tokenStorage.saveToken(token);

    final raw = res['customer'];
    final customer = raw is Map<String, dynamic>
        ? AuthCustomer(
            phone: raw['phone']?.toString() ?? phone,
            name: raw['name']?.toString(),
            email: raw['email']?.toString(),
          )
        : AuthCustomer(phone: phone);

    await _preferences.saveCustomer(
      phone: customer.phone,
      name: customer.name,
      email: customer.email,
    );
    return customer;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  @override
  AuthCustomer? currentCustomer() {
    final phone = _preferences.customerPhone;
    if (phone == null || phone.isEmpty) return null;
    return AuthCustomer(
      phone: phone,
      name: _preferences.customerName,
      email: _preferences.customerEmail,
    );
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clear();
    await _preferences.clearCustomer();
  }
}
