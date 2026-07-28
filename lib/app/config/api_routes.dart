abstract final class ApiRoutes {
  static const catalogBootstrap = '/catalog/bootstrap';
  // رئيسيّة المتجر — منها بنرات السلايدر (hero.slides) المُدارة من استوديو البنرات.
  static const catalogHome = '/catalog/home';
  static const catalogTrends = '/catalog/trends';
  static const catalogSearch = '/catalog/search';
  static const catalogNavigation = '/catalog/navigation';
  static const catalogCategories = '/catalog/categories'; // + /<slug>
  static const catalogPaymentMethods = '/catalog/payment-methods';

  static const authRequestOtp = '/customer/auth/request-otp';
  static const authVerifyOtp = '/customer/auth/verify-otp';

  static const dashboard = '/customer/me';
  static const rewards = '/me/rewards';
  // مسارات العميل الحقيقيّة على الوسيط (محميّة بتوكن Bearer).
  static const orders = '/customer/orders';
  static const favorites = '/me/favorites';
  static const addresses = '/customer/addresses';

  static const checkout = '/orders/checkout';
  static const tabbyRegisterPending = '/payments/tabby/register-pending';
  static const tabbyConfirm = '/payments/tabby/confirm';
  static const noonInitiate = '/payments/noon/initiate';
  static const noonVerify = '/payments/noon/order'; // + /<noonOrderId>
  static const assistantChat = '/assistant/chat';
}
