// عقد المصادقة (OTP عبر الجوّال + البريد) — يطابق نقاط الوسيط /customer/auth/*.
class AuthCustomer {
  const AuthCustomer({required this.phone, this.name, this.email});

  final String phone;
  final String? name;
  final String? email;
}

abstract class AuthRepository {
  Future<void> requestOtp({required String phone, required String email});
  Future<AuthCustomer> verifyOtp({required String phone, required String code});
  Future<bool> isAuthenticated();
  AuthCustomer? currentCustomer();
  Future<void> logout();
}
