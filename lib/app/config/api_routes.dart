abstract final class ApiRoutes {
  static const catalogBootstrap = '/catalog/bootstrap';
  static const catalogTrends = '/catalog/trends';
  static const catalogSearch = '/catalog/search';

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
  static const assistantChat = '/assistant/chat';
}
