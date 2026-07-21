import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  sendingOtp,
  otpSent,
  verifying,
  authenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.phone = '',
    this.email = '',
    this.customer,
    this.error,
  });

  final AuthStatus status;
  final String phone;
  final String email;
  final AuthCustomer? customer;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => status == AuthStatus.sendingOtp || status == AuthStatus.verifying;

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? email,
    AuthCustomer? customer,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      customer: customer ?? this.customer,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    final authed = await _repository.isAuthenticated();
    emit(state.copyWith(
      status: authed ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      customer: _repository.currentCustomer(),
    ));
  }

  Future<void> requestOtp({required String phone, required String email}) async {
    emit(state.copyWith(
      status: AuthStatus.sendingOtp,
      phone: phone.trim(),
      email: email.trim(),
      clearError: true,
    ));
    try {
      await _repository.requestOtp(phone: phone.trim(), email: email.trim());
      emit(state.copyWith(status: AuthStatus.otpSent));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: _msg(e)));
    }
  }

  Future<void> verifyOtp(String code) async {
    emit(state.copyWith(status: AuthStatus.verifying, clearError: true));
    try {
      final customer = await _repository.verifyOtp(phone: state.phone, code: code.trim());
      emit(state.copyWith(status: AuthStatus.authenticated, customer: customer));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.otpSent, error: _msg(e)));
    }
  }

  // العودة لخطوة إدخال الجوّال (تغيير الرقم).
  void editPhone() => emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  String _msg(Object e) {
    if (e is ApiException) return e.message;
    return 'تعذّر إتمام العمليّة، حاول مجدداً.';
  }
}
