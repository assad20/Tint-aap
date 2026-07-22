class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.tabbyPublicKey,
    required this.tabbyMerchantCode,
    required this.tabbyLanguage,
    required this.currencyCode,
  });

  final String baseUrl;
  final String tabbyPublicKey;
  final String tabbyMerchantCode;
  final String tabbyLanguage;
  final String currencyCode;

  bool get hasTabbyConfig =>
      tabbyPublicKey.trim().isNotEmpty && tabbyMerchantCode.trim().isNotEmpty;

  // أصل الـAPI بلا مسار: http://10.0.2.2:5181/api → http://10.0.2.2:5181
  // يُستخدم لإعادة كتابة روابط الصور المحلّيّة (localhost) لتظهر على المحاكي/الجهاز.
  String get origin {
    final u = Uri.tryParse(baseUrl);
    if (u == null || u.host.isEmpty) return '';
    final port = u.hasPort ? ':${u.port}' : '';
    return '${u.scheme}://${u.host}$port';
  }

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      baseUrl: String.fromEnvironment(
        'TINT_API_BASE_URL',
        // الافتراضيّ = المتجر المنشور (وسيط الإنتاج على Railway)، فأيّ APK يُبنى
        // يتغذّى من المتجر المنشور مباشرةً.
        // للتطوير المحلّيّ تجاوَزه: --dart-define=TINT_API_BASE_URL=http://10.0.2.2:5181/api
        defaultValue: 'https://tint-production-4d38.up.railway.app/api',
      ),
      tabbyPublicKey: String.fromEnvironment(
        'TINT_TABBY_PUBLIC_KEY',
        defaultValue: '',
      ),
      tabbyMerchantCode: String.fromEnvironment(
        'TINT_TABBY_MERCHANT_CODE',
        defaultValue: '',
      ),
      tabbyLanguage: String.fromEnvironment(
        'TINT_TABBY_LANG',
        defaultValue: 'ar',
      ),
      currencyCode: String.fromEnvironment(
        'TINT_CURRENCY_CODE',
        defaultValue: 'SAR',
      ),
    );
  }
}
