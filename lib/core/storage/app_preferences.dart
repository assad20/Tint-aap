import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

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

  /// المقاطع الترويجيّة التي أعجبت صاحب هذا الجهاز.
  ///
  /// ‼️ **محلّيٌّ لا خادميّ عمداً.** الإعجاب بمقطعٍ ترويجيّ ليس تفضيلاً يُستعاد
  /// على جهازٍ آخر ولا يدخل توصيةً — غايته أن يبقى القلب مضيئاً لمن أضاءه،
  /// وأن يُعَدّ مرّةً على الخادم. وربطُه بحساب العميل كان يعني تخزين سلوك
  /// مشاهدةٍ باسمه مقابل لا شيء.
  bool likedReel(String promoId) =>
      _prefs.getStringList('liked_reels')?.contains(promoId) ?? false;

  /// ‼️ **يُضيف ولا يُبدّل.** الخادم لا يُنقص عدّاده، فإطفاء القلب محلّيّاً كان
  /// يُنتج جهازاً يقول «لم أُعجب» ورقماً يقول «أُعجب» — وهو تناقضٌ لا يُكتشف.
  Future<void> rememberLikedReel(String promoId) async {
    final id = promoId.trim();
    if (id.isEmpty) return;
    final current = _prefs.getStringList('liked_reels') ?? <String>[];
    if (current.contains(id)) return;
    await _prefs.setStringList('liked_reels', [...current, id]);
  }

  /// آخر مقطعٍ ترويجيّ نُقر زرّه — ووقتُه، لنسبة الطلب إليه.
  ///
  /// ‼️ **نقرةٌ واحدة تُحفظ لا سجلٌّ كامل.** «آخر نقرة» هي نموذج النسبة
  /// المختار، وسجلُّ كلّ النقرات كان يعني تخزين سلوك تصفّحٍ على الجهاز مقابل
  /// رقمٍ لا يستعمله.
  String? get lastReelClickId => _prefs.getString('last_reel_click_id');

  int get lastReelClickAt => _prefs.getInt('last_reel_click_at') ?? 0;

  Future<void> rememberReelClick(String promoId) async {
    final id = promoId.trim();
    if (id.isEmpty) return;
    await _prefs.setString('last_reel_click_id', id);
    await _prefs.setInt('last_reel_click_at', DateTime.now().millisecondsSinceEpoch);
  }

  /// ‼️ **تُمحى بعد النسبة لا تُترك.** طلبٌ ثانٍ بعد أسبوعٍ كان سيُنسَب إلى
  /// النقرة نفسها مرّةً أخرى، فيبدو المقطع أضعافَ ما باع.
  Future<void> clearReelClick() async {
    await _prefs.remove('last_reel_click_id');
    await _prefs.remove('last_reel_click_at');
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

  // ── المنتجات المُشاهَدة مؤخّراً ──
  //
  // محلّيّة عمداً: سجلّ تصفّحٍ على الخادم يعني ربط سلوكٍ بهويّة، وهذه الشاشة
  // لا تحتاجه — الجهاز يعرف ما شاهده صاحبه. وتُخزَّن البطاقة كاملةً لا
  // مُعرّفها كي تُعرَض فوراً بلا نداء شبكة.
  static const _recentlyViewedKey = 'recently_viewed_v1';
  static const _recentlyViewedMax = 20;

  List<ProductModel> get recentlyViewed {
    final raw = _prefs.getStringList(_recentlyViewedKey) ?? const <String>[];
    final out = <ProductModel>[];
    for (final line in raw) {
      try {
        final map = jsonDecode(line);
        if (map is Map<String, dynamic>) out.add(ProductModel.fromJson(map));
      } catch (_) {
        // سطرٌ تالف من نسخةٍ أقدم — يُتخطّى ولا يُسقط البقيّة.
      }
    }
    return out;
  }

  Future<void> pushRecentlyViewed(ProductModel product) async {
    if (product.id.isEmpty) return;
    final items = recentlyViewed.where((p) => p.id != product.id).toList();
    items.insert(0, product);
    if (items.length > _recentlyViewedMax) {
      items.removeRange(_recentlyViewedMax, items.length);
    }
    await _prefs.setStringList(
      _recentlyViewedKey,
      items.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  Future<void> clearRecentlyViewed() async {
    await _prefs.remove(_recentlyViewedKey);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove('recent_searches');
  }

  // ─── لقطة الرئيسيّة المحفوظة (فتح لحظيّ: تُعرَض فوراً ثمّ تُحدَّث من الشبكة) ───
  String? get cachedHomeSnapshot => _prefs.getString('home_snapshot_v1');

  Future<void> setCachedHomeSnapshot(String json) async {
    await _prefs.setString('home_snapshot_v1', json);
  }

  /// ─── تخطيط الرئيسيّة من اللوحة (SDUI) — **يُخزَّن خاماً كما وصل** ───
  ///
  /// ‼️ خاماً لا مُحلَّلاً عمداً: التحليل يُطبّق حارس `minAppVersion`، وتخزينُ
  /// نتيجته يُجمّد قراراً اتُّخذ بنسخةٍ قديمة — فقسمٌ أُخفي لأنّه يحتاج `1.4.0`
  /// يبقى مخفيّاً بعد ترقية التطبيق إلى `1.4.0` نفسها. والخام يُعاد تقييمه في
  /// كلّ إقلاع.
  String? get cachedHomeLayout => _prefs.getString('home_layout_v1');

  Future<void> setCachedHomeLayout(String json) async {
    await _prefs.setString('home_layout_v1', json);
  }

  /// يُزيل التخطيط المخزَّن — **حين يقول الخادم إنّه لم يعد منشوراً وحدها**.
  ///
  /// ‼️ وبدونها تبقى رئيسيّةٌ حذفها المالك تعمل على الجهاز بلا نهاية: الكاش
  /// بلا صلاحيّةٍ تنتهي، ولا شيء آخر يمحوه.
  Future<void> clearCachedHomeLayout() async {
    await _prefs.remove('home_layout_v1');
  }

  /// تنقّل التطبيق المخزَّن (المهمّة 3.6) — خاماً كسابقه، وللسبب نفسه.
  String? get cachedAppNavigation => _prefs.getString('app_navigation_v1');

  Future<void> setCachedAppNavigation(String json) async {
    await _prefs.setString('app_navigation_v1', json);
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
