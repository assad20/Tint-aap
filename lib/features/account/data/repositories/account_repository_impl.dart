import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

// ‼️ سياسة v1: نُظهر بيانات الخادم الحقيقيّة حيث توجد (الملف/الطلبات/العناوين عبر
// /customer/*)، ونُعيد فارغاً — لا بيانات وهميّة — للميزات التي لا خادم لها بعد
// (النقاط/المحفظة/المفضّلة/بطاقات الهديّة/المقاسات/تنبيهات المخزون/سجلّ التصفّح).
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AccountRemoteDataSource _remoteDataSource;

  static const _emptyProfile = ProfileBundle(
    profile: UserProfileModel(
      name: '',
      phone: '',
      membershipTier: '',
      avatarUrl: '',
      points: 0,
      couponsCount: 0,
      walletBalance: 0,
    ),
    paymentCards: [],
    browsingHistory: [],
    sizeProfiles: [],
    giftCards: [],
    stockAlerts: [],
  );

  @override
  Future<ProfileBundle> fetchProfileBundle() async {
    try {
      // /customer/me يُعيد كائن العميل المسطّح (name/phone/email).
      final data = await _remoteDataSource.fetchProfileBundle();
      final profile = UserProfileModel.fromJson(data);
      if (profile.name.isEmpty && profile.phone.isEmpty) return _emptyProfile;
      return ProfileBundle(
        profile: profile,
        paymentCards: const [],
        browsingHistory: const [],
        sizeProfiles: const [],
        giftCards: const [],
        stockAlerts: const [],
      );
    } catch (_) {
      return _emptyProfile; // غير مسجّل / خطأ — بلا وهم
    }
  }

  @override
  Future<RewardsBundle> fetchRewardsBundle() async {
    // لا خادم لنظام النقاط/المحفظة بعد.
    return const RewardsBundle(
      availablePoints: 0,
      pendingPoints: 0,
      usedPoints: 0,
      walletBalance: 0,
      history: [],
      coupons: [],
      walletTransactions: [],
    );
  }

  @override
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final data = await _remoteDataSource.fetchOrders(); // /customer/orders (محميّ)
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    } catch (_) {
      return const <OrderModel>[];
    }
  }

  @override
  Future<List<ProductModel>> fetchFavorites() async {
    // لا خادم للمفضّلة بعد.
    return const <ProductModel>[];
  }

  @override
  Future<List<AddressModel>> fetchAddresses() async {
    try {
      final data = await _remoteDataSource.fetchAddresses(); // /customer/addresses (محميّ)
      return data
          .whereType<Map<String, dynamic>>()
          .map(AddressModel.fromJson)
          .toList();
    } catch (_) {
      return const <AddressModel>[];
    }
  }
}
