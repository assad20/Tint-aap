import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AccountRemoteDataSource _remoteDataSource;

  @override
  Future<ProfileBundle> fetchProfileBundle() async {
    try {
      final data = await _remoteDataSource.fetchProfileBundle();
      final profile = UserProfileModel.fromJson(
        data['profile'] as Map<String, dynamic>? ?? const {},
      );
      final cards = (data['paymentCards'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PaymentCardModel.fromJson)
          .toList();
      final history = (data['browsingHistory'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
      final sizes = (data['sizeProfiles'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SizeProfileModel.fromJson)
          .toList();
      final giftCards = (data['giftCards'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GiftCardModel.fromJson)
          .toList();
      final stockAlerts = (data['stockAlerts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StockAlertModel.fromJson)
          .toList();

      if (profile.name.isEmpty) {
        return FakeSeedData.profileBundle;
      }

      return ProfileBundle(
        profile: profile,
        paymentCards: cards,
        browsingHistory: history,
        sizeProfiles: sizes,
        giftCards: giftCards,
        stockAlerts: stockAlerts,
      );
    } catch (_) {
      return FakeSeedData.profileBundle;
    }
  }

  @override
  Future<RewardsBundle> fetchRewardsBundle() async {
    try {
      final data = await _remoteDataSource.fetchRewardsBundle();
      final history = (data['history'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RewardTransactionModel.fromJson)
          .toList();
      final coupons = (data['coupons'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CouponModel.fromJson)
          .toList();
      final walletTransactions = (data['walletTransactions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WalletTransactionModel.fromJson)
          .toList();

      return RewardsBundle(
        availablePoints: int.tryParse(data['availablePoints'].toString()) ??
            FakeSeedData.rewardsBundle.availablePoints,
        pendingPoints: int.tryParse(data['pendingPoints'].toString()) ??
            FakeSeedData.rewardsBundle.pendingPoints,
        usedPoints: int.tryParse(data['usedPoints'].toString()) ??
            FakeSeedData.rewardsBundle.usedPoints,
        walletBalance: double.tryParse(data['walletBalance'].toString()) ??
            FakeSeedData.rewardsBundle.walletBalance,
        history: history.isEmpty ? FakeSeedData.rewardsBundle.history : history,
        coupons: coupons.isEmpty ? FakeSeedData.rewardsBundle.coupons : coupons,
        walletTransactions: walletTransactions.isEmpty
            ? FakeSeedData.rewardsBundle.walletTransactions
            : walletTransactions,
      );
    } catch (_) {
      return FakeSeedData.rewardsBundle;
    }
  }

  @override
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final data = await _remoteDataSource.fetchOrders();
      if (data.isEmpty) return FakeSeedData.orders;
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    } catch (_) {
      return FakeSeedData.orders;
    }
  }

  @override
  Future<List<ProductModel>> fetchFavorites() async {
    try {
      final data = await _remoteDataSource.fetchFavorites();
      if (data.isEmpty) return FakeSeedData.favorites;
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      return FakeSeedData.favorites;
    }
  }

  @override
  Future<List<AddressModel>> fetchAddresses() async {
    try {
      final data = await _remoteDataSource.fetchAddresses();
      if (data.isEmpty) return FakeSeedData.addresses;
      return data
          .whereType<Map<String, dynamic>>()
          .map(AddressModel.fromJson)
          .toList();
    } catch (_) {
      return FakeSeedData.addresses;
    }
  }
}
