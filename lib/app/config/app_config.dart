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

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      baseUrl: String.fromEnvironment(
        'TINT_API_BASE_URL',
        defaultValue: 'http://10.0.2.2:3000/api',
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
