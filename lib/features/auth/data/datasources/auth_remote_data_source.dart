import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// يطلب رمز التحقّق على **القناة التي اختارها العميل**.
  ///
  /// الجواب: `{ ok, phone, channel, target, usedFallback, availableChannels,
  /// resendAfterSeconds, ttl, debugCode? }`
  ///
  /// ‼️ **الحقل الفارغ لا يُرسَل.** من اختار واتساب قد لا يملك بريداً، ومن
  /// اختار البريد لا يعرف جوّاله. وإرسال مفتاحٍ بقيمةٍ فارغة يجعل الخادم
  /// يتحقّق منه ويرفض الطلب بـ«أدخل بريداً صحيحاً» — والشاشة لا تعرض حقل
  /// بريدٍ أصلاً. طريقٌ مسدود: خطأٌ يطلب ما لا سبيل لإدخاله.
  Future<Map<String, dynamic>> requestOtp({
    required String phone,
    required String email,
    required String channel,
  }) {
    return _apiClient.postMap(
      ApiRoutes.authRequestOtp,
      data: {
        // ‼️ **`phone` يُرسَل دائماً ولو فارغاً — `email` لا.**
        //
        //    عقد الخادم يُعلن `phone` إلزاميّاً (`@IsString`) و`email`
        //    اختياريّاً (`@IsOptional`). فإسقاط `phone` عند اختيار البريد
        //    يُرجع «phone must be a string» — خطأٌ إنجليزيّ يقرؤه المشتري
        //    ولا يفهم منه شيئاً، ولا يدلّه على حيلة. (رُصد بالتشغيل
        //    2026-08-13، ولم يكشفه تحليلٌ ولا اختبار.)
        //
        //    وإرسال `email` فارغاً يُسقط `@IsEmail` بخطأٍ مماثل. فلكلّ حقلٍ
        //    حكمُه، ولا يُعمَّم قياسٌ من أحدهما على الآخر.
        'phone': phone,
        if (email.isNotEmpty) 'email': email,
        'channel': channel,
      },
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
