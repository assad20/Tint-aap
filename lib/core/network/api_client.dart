import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// ترويسة مفتاح متجر التطبيق (المهمّة 1.8).
///
/// ‼️ **بدونها يُحَلّ التطبيق إلى المتجر الافتراضيّ بملاذ الرجوع** — أي يعمل
/// **بالمصادفة** لأنّ الافتراضيّ هو تِنت. ويوم يُطلَق تطبيقٌ لمتجرٍ آخر يبيع
/// كتالوج تِنت ويَنسب طلباته إليها **بلا خطأٍ في أيّ سجلّ**.
const String kAppKeyHeader = 'x-tint-app-key';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    String appKey = _compiledAppKey,
  })  : _tokenStorage = tokenStorage,
        _appKey = appKey.trim(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            // بعض النقاط (الترندات) بطيئة عند البرودة (~8ث) وتحت حمل الإقلاع المتزامن.
            receiveTimeout: const Duration(seconds: 25),
            sendTimeout: const Duration(seconds: 25),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ‼️ في المعترِض لا في `BaseOptions`: كلّ نداءٍ يحمله بلا استثناء —
          //    ونداءٌ واحد يُغفله يُحَلّ إلى متجرٍ آخر بصمت.
          if (_appKey.isNotEmpty) {
            options.headers[kAppKeyHeader] = _appKey;
          }
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// مفتاح متجر هذه الحزمة. الفراغ = لا ترويسة (السلوك القديم حرفيّاً).
  final String _appKey;

  /// ‼️ **يُحقَن وقت البناء لا وقت التشغيل**: كلّ حزمةٍ تخصّ متجراً واحداً،
  /// وقراءتُه من إعدادٍ يُبدَّل تعني تطبيقاً واحداً يتنقّل بين المتاجر — وهو ما
  /// يجعل طلبات عميلٍ تُنسب لمتجرٍ ثمّ لآخر.
  ///
  /// للبناء: `--dart-define=TINT_APP_KEY=<مفتاح المتجر من لوحة إدارة المتاجر>`
  ///
  /// ‼️ **والافتراضيّ فارغ عمداً**: حزمةٌ بُنيت بلا مفتاح تسلك كاليوم بالضبط
  /// (ملاذ الرجوع إلى المتجر الافتراضيّ) بدل أن تُرسل مفتاحاً مخترعاً يُرفَض.
  static const String _compiledAppKey =
      String.fromEnvironment('TINT_APP_KEY', defaultValue: '');

  /// للتشخيص وحده — يُظهر إن كانت الحزمة تحمل مفتاحاً دون كشف قيمته كاملةً.
  bool get hasAppKey => _appKey.isNotEmpty;

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? <dynamic>[];
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  // نقاطٌ تُعيد مصفوفةً بعد تعديل (المفضّلة تُعيد القائمة المحدَّثة).
  Future<List<dynamic>> postList(
    String path, {
    Object? data,
  }) async {
    try {
      final response = await _dio.post<List<dynamic>>(path, data: data);
      return response.data ?? <dynamic>[];
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<dynamic>> deleteList(String path) async {
    try {
      final response = await _dio.delete<List<dynamic>>(path);
      return response.data ?? <dynamic>[];
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> deleteMap(String path) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(path);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Duration? receiveTimeout,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        // بعض النقاط (المستشار) تستدعي مزوّد ذكاء خارجيّاً وقد تكون أبطأ من الافتراضيّ.
        options: receiveTimeout != null
            ? Options(receiveTimeout: receiveTimeout)
            : null,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  /// تعديلٌ جزئيّ — `PATCH`.
  ///
  /// ‼️ **ولا يُستبدَل بـ`POST`**: نقاط التعديل في الخادم مُعلنةٌ `@Patch`،
  /// و`POST` عليها إمّا يُنشئ سجلّاً ثانياً أو يردّ 404 — والفرق لا يظهر إلّا
  /// بنداءٍ حقيقيّ.
  ///
  /// ‼️ **ويُعيد قائمةً لا كائناً**: نقاط العناوين تردّ القائمة كاملةً بعد
  /// التعديل. وطلبُ `Map` منها يُسقط النداء بخطأ تحويلٍ في Dio **قبل أن يُقرأ
  /// الردّ** — فيُقرأ فشلَ شبكةٍ وهو نجاحٌ كامل.
  Future<List<dynamic>> patchList(
    String path, {
    Object? data,
  }) async {
    try {
      final response = await _dio.patch<List<dynamic>>(path, data: data);
      return response.data ?? <dynamic>[];
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final responseData = error.response?.data;
    final message = switch (responseData) {
      Map<String, dynamic>() => responseData['message']?.toString() ??
          responseData['error']?.toString() ??
          error.message ??
          'حدث خطأ غير متوقع',
      _ => error.message ?? 'حدث خطأ في الاتصال بالسيرفر الوسيط',
    };

    return ApiException(
      message,
      statusCode: error.response?.statusCode,
    );
  }
}
