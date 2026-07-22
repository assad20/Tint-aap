import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  late SharedPreferencesWithCache _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }

  String get activeHomeNav =>
      _prefs.getString('active_home_nav') ?? 'الرئيسية';

  Future<void> setActiveHomeNav(String value) async {
    await _prefs.setString('active_home_nav', value);
  }

  List<String> get recentSearches =>
      _prefs.getStringList('recent_searches') ?? <String>[];

  Future<void> pushRecentSearch(String value) async {
    final searches = [...recentSearches];
    searches.remove(value);
    searches.insert(0, value);
    if (searches.length > 8) {
      searches.removeRange(8, searches.length);
    }
    await _prefs.setStringList('recent_searches', searches);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove('recent_searches');
  }

  // ─── لقطة الرئيسيّة المحفوظة (فتح لحظيّ: تُعرَض فوراً ثمّ تُحدَّث من الشبكة) ───
  String? get cachedHomeSnapshot => _prefs.getString('home_snapshot_v1');

  Future<void> setCachedHomeSnapshot(String json) async {
    await _prefs.setString('home_snapshot_v1', json);
  }

  // ─── بيانات العميل بعد تسجيل الدخول (التوكن نفسه في التخزين الآمن) ───
  String? get customerPhone => _prefs.getString('customer_phone');
  String? get customerName => _prefs.getString('customer_name');
  String? get customerEmail => _prefs.getString('customer_email');

  Future<void> saveCustomer({
    required String phone,
    String? name,
    String? email,
  }) async {
    await _prefs.setString('customer_phone', phone);
    if (name != null && name.isNotEmpty) await _prefs.setString('customer_name', name);
    if (email != null && email.isNotEmpty) await _prefs.setString('customer_email', email);
  }

  Future<void> clearCustomer() async {
    await _prefs.remove('customer_phone');
    await _prefs.remove('customer_name');
    await _prefs.remove('customer_email');
  }
}
