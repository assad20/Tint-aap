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
}
