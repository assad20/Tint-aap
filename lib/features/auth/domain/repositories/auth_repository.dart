import '../entities/verification_channel.dart';
// عقد المصادقة (OTP عبر الجوّال + البريد) — يطابق نقاط الوسيط /customer/auth/*.
class AuthCustomer {
  const AuthCustomer({required this.phone, this.name, this.email});

  final String phone;
  final String? name;
  final String? email;
}

abstract class AuthRepository {
  Future<OtpDelivery> requestOtp({
    required String phone,
    required String email,
    required VerificationChannel channel,
  });
  Future<AuthCustomer> verifyOtp({required String phone, required String code});
  /// يحفظ الاسم على الحساب — خطوة «تسجيل جديد».
  ///
  /// ‼️ **لا نقطةَ «تسجيل» في الخادم أصلاً**: `verifyOtp` يُنشئ الحساب
  /// بـ`upsert` عند أوّل تحقّق. فالفرق الوحيد بين «دخول» و«تسجيل جديد» هو
  /// **التقاط الاسم**، وهذه هي التي تحفظه.
  Future<AuthCustomer> saveName(String name);

  Future<bool> isAuthenticated();
  AuthCustomer? currentCustomer();
  Future<void> logout();
}

/// ما قاله الخادم عن الإرسال — يقوده العرض، ولا يُخمَّن في الشاشة.
class OtpDelivery {
  const OtpDelivery({
    required this.phone,
    required this.channel,
    required this.target,
    required this.usedFallback,
    required this.availableChannels,
    required this.resendAfterSeconds,
    this.debugCode,
  });

  /// الهويّة كما حلّها الخادم — **لا كما كتبها المستخدم**: من دخل بالبريد لا
  /// يعرف جوّاله، والتحقّق يقع على الهويّة نفسها.
  final String phone;

  /// القناة التي أُرسِل بها **فعلاً** — قد تخالف المطلوبة عند التحويل.
  final VerificationChannel? channel;

  /// العنوان المعروض للمستخدم (مُقنَّعٌ من الخادم).
  final String target;

  /// ‼️ تعذّرت القناة المطلوبة فتُحوّل الخادم — يُقال للمستخدم صراحةً،
  /// وإلّا انتظر رسالةً على قناةٍ لن تصله أبداً.
  final bool usedFallback;

  final List<VerificationChannel> availableChannels;
  final int resendAfterSeconds;

  /// رمز التطوير حين يسمح به الخادم — لا يظهر في الإنتاج.
  final String? debugCode;

  factory OtpDelivery.fromJson(Map<String, dynamic> json) {
    return OtpDelivery(
      phone: json['phone']?.toString() ?? '',
      channel: VerificationChannel.tryParse(json['channel']),
      target: json['target']?.toString() ?? '',
      usedFallback: json['usedFallback'] == true,
      availableChannels: [
        for (final raw in (json['availableChannels'] as List? ?? const []))
          if (VerificationChannel.tryParse(raw) case final c?) c,
      ],
      resendAfterSeconds:
          int.tryParse(json['resendAfterSeconds']?.toString() ?? '') ?? 45,
      debugCode: json['debugCode']?.toString(),
    );
  }
}
