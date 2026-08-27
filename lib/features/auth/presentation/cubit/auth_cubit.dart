import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/verification_channel.dart';
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
    this.channel = VerificationChannel.whatsapp,
    this.delivery,
  });

  final AuthStatus status;
  final String phone;
  final String email;
  final AuthCustomer? customer;
  final String? error;

  /// القناة التي اختارها العميل — تُرسَل صريحةً مع كلّ طلب.
  final VerificationChannel channel;

  /// ما قاله الخادم عن الإرسال الأخير — تقرأه الشاشة ولا تُخمّنه.
  final OtpDelivery? delivery;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => status == AuthStatus.sendingOtp || status == AuthStatus.verifying;

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? email,
    AuthCustomer? customer,
    String? error,
    bool clearError = false,
    VerificationChannel? channel,
    OtpDelivery? delivery,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      customer: customer ?? this.customer,
      error: clearError ? null : (error ?? this.error),
      channel: channel ?? this.channel,
      delivery: delivery ?? this.delivery,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository, TrackingService? tracking})
      : _repository = repository,
        _tracking = tracking,
        super(const AuthState()) {
    _init();
  }

  final AuthRepository _repository;

  /// ‼️ **اختياريّة عمداً**: الدخول أهمّ من قياسه. فبناءُ الكيوبت في اختبارٍ أو
  /// في سياقٍ بلا قياس يبقى ممكناً، ولا يفشل الدخول لأنّ القياس غائب.
  final TrackingService? _tracking;

  Future<void> _init() async {
    final authed = await _repository.isAuthenticated();
    emit(state.copyWith(
      status: authed ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      customer: _repository.currentCustomer(),
    ));
  }

  /// يطلب الرمز على القناة المختارة.
  ///
  /// ‼️ **الهويّة تُؤخَذ من جواب الخادم لا من الحقل.** من يدخل ببريده لا يكتب
  /// جوّاله، والتحقّق يقع على الهويّة التي حلّها الخادم — وأخذُها من الحقل
  /// كان يجعل «تأكيد الرمز» يبحث عن جوّالٍ فارغ.
  Future<void> requestOtp({
    required String phone,
    required String email,
    VerificationChannel? channel,
  }) async {
    final wanted = channel ?? state.channel;
    emit(state.copyWith(
      status: AuthStatus.sendingOtp,
      phone: phone.trim(),
      email: email.trim(),
      channel: wanted,
      clearError: true,
    ));
    try {
      final delivery = await _repository.requestOtp(
        phone: phone.trim(),
        email: email.trim(),
        channel: wanted,
      );
      emit(state.copyWith(
        status: AuthStatus.otpSent,
        phone: delivery.phone.isNotEmpty ? delivery.phone : state.phone,
        delivery: delivery,
        // ‼️ القناة المعروضة هي التي أُرسِل بها فعلاً، لا التي طُلبت: الخادم
        //    قد يُحوّل، وعرضُ المطلوبة يجعل المستخدم ينتظر على قناةٍ خاطئة.
        channel: delivery.channel ?? wanted,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: _msg(e)));
    }
  }

  void setChannel(VerificationChannel channel) =>
      emit(state.copyWith(channel: channel, clearError: true));

  /// يتحقّق من الرمز، ويحفظ الاسم بعده إن كان تسجيلاً جديداً.
  ///
  /// ‼️ **الاسم يُحفظ بعد التحقّق لا قبله** — نقطة الملفّ الشخصيّ محميّةٌ
  /// بتوكن العميل، ولا توكن قبل التحقّق.
  Future<void> verifyOtp(String code, {String? name}) async {
    emit(state.copyWith(status: AuthStatus.verifying, clearError: true));
    try {
      final customer = await _repository.verifyOtp(phone: state.phone, code: code.trim());

      /// ‼️ **فشلُ حفظ الاسم لا يُسقط الدخول.**
      ///
      /// التحقّق نجح والتوكن محفوظٌ فعلاً؛ فرميُ الخطأ هنا يُخرج الشاشة إلى
      /// حالة «فشل» بينما العميل **داخلٌ بالفعل** — فيُعيد المحاولة على رمزٍ
      /// انتهت صلاحيّته ويُحبَس خارج حسابه المفتوح. والاسم يُعدَّل من الملفّ
      /// الشخصيّ متى شاء، أمّا الدخول فلا يُستعاد.
      var finalCustomer = customer;
      final wanted = name?.trim() ?? '';
      if (wanted.isNotEmpty && (customer.name ?? '').trim() != wanted) {
        try {
          finalCustomer = await _repository.saveName(wanted);
        } catch (_) {
          finalCustomer = AuthCustomer(
            phone: customer.phone,
            name: wanted,
            email: customer.email,
          );
        }
      }

      emit(state.copyWith(status: AuthStatus.authenticated, customer: finalCustomer));
      /// ‼️ **بعد نجاح التحقّق لا عند إرسال الرمز.** ورمزٌ خاطئ لا يُطلق شيئاً —
      /// وإلّا صار «الدخول» يُعدّ محاولاتٍ فاشلة.
      ///
      /// ‼️ **و`method` وسيلةُ الدخول لا هويّة الداخل**: `otp` لا رقم الجوّال —
      /// ولا يُرسَل الجوّال في أيّ معامل.
      unawaited(_tracking?.logLogin() ?? Future<void>.value());
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.otpSent, error: _msg(e)));
    }
  }

  /// يحفظ الاسم لحسابٍ **قائمٍ بلا اسم** — بعد الدخول لا أثناءه.
  ///
  /// ‼️ **ولا يُسقط الجلسة عند الفشل**: العميل داخلٌ فعلاً، والاسم تفصيلٌ
  /// يُعدَّل من الملفّ الشخصيّ متى شاء.
  Future<void> updateName(String name) async {
    final wanted = name.trim();
    if (wanted.isEmpty) return;
    try {
      final customer = await _repository.saveName(wanted);
      emit(state.copyWith(customer: customer));
    } catch (_) {
      emit(state.copyWith(
        customer: AuthCustomer(
          phone: state.customer?.phone ?? state.phone,
          name: wanted,
          email: state.customer?.email,
        ),
      ));
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
