import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';

abstract class AccountRepository {
  Future<ProfileBundle> fetchProfileBundle();

  /// ‼️ **شرط أبل 5.1.1(v)**: ما يُنشَأ من داخل التطبيق يُحذَف من داخله.
  /// وغيابُه رفضٌ مؤكّد في المراجعة لا احتمال.
  Future<void> deleteAccount();

  Future<RewardsBundle> fetchRewardsBundle();

  Future<List<OrderModel>> fetchOrders();

  Future<List<ProductModel>> fetchFavorites();

  // تُعيدان القائمة المحدَّثة، و`null` عند الفشل (أبقِ المعروض).
  Future<List<ProductModel>?> addFavorite(String productId);
  Future<List<ProductModel>?> removeFavorite(String productId);

  Future<List<AddressModel>> fetchAddresses();

  /// يحفظ عنواناً — جديداً أو معدَّلاً — ويُعيد **ما أثبته الخادم**.
  ///
  /// ‼️ المُعاد هو المصدر لا المُرسَل: الخادم يُصدر المُعرّف، وقد يُطبّع حقلاً
  /// أو يرفع راية الافتراضيّ عن عنوانٍ آخر. وحفظُ ما أرسلناه يترك في التطبيق
  /// عنواناً بمُعرّفٍ محلّيٍّ لا وجود له عند الخادم — فيفشل أوّل تعديلٍ عليه.
  /// ‼️ **تُعيد القائمة كاملةً كما يردّها الخادم** — لا العنوان وحده: الحفظ قد
  /// يُنزل راية الافتراضيّ عن عنوانٍ آخر، وحذفُ الافتراضيّ يرفعها عن الأوّل.
  /// فقائمةٌ كاملةٌ من المصدر أصدقُ من دمجٍ نُجريه بالتخمين.
  Future<List<AddressModel>> saveAddress(AddressModel address, {required bool isNew});

  Future<List<AddressModel>> deleteAddress(String id);
}
