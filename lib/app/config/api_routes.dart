abstract final class ApiRoutes {
  static const catalogBootstrap = '/catalog/bootstrap';
  // رئيسيّة المتجر — منها بنرات السلايدر (hero.slides) المُدارة من استوديو البنرات.
  static const catalogHome = '/catalog/home';
  static const catalogTrends = '/catalog/trends';
  // الاكتشاف: أرفف مُهيكلة تُصفّى بتبويب القسم، ومسار «عرض الكل» لكلّ رفّ.
  static const catalogDiscover = '/catalog/discover'; // + /<key>
  // تسجيل تفاعل المتسوّق — منه يُبنى رفّ «الأكثر رواجاً».
  static const catalogEvents = '/catalog/events';
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
  // المفضّلة تحت مظلّة العميل المحميّة كالعناوين — `/me/favorites` لم يكن
  // مُعرَّفاً على الوسيط أصلاً فكان النداء يعود 404 صامتاً.
  static const favorites = '/customer/favorites';
  static const addresses = '/customer/addresses';

  static const checkout = '/orders/checkout';
  static const tabbyRegisterPending = '/payments/tabby/register-pending';
  static const tabbyConfirm = '/payments/tabby/confirm';
  static const noonInitiate = '/payments/noon/initiate';
  static const noonVerify = '/payments/noon/order'; // + /<noonOrderId>
  static const assistantChat = '/assistant/chat';
}
