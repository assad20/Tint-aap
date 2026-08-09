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
  /// صفحة منتجٍ بمعرّفه — تُفتَح من رابطٍ عميق لا من بطاقةٍ تحمل الكائن.
  static const catalogProducts = '/catalog/products'; // + /<id>
  // توفّر بنود السلّة — تُراجَع عند فتح السلّة وقبل الدفع، فلا يُكتشف النفاد
  // بعد إدخال العنوان. نفس المطابقة التي يستعملها الخادم عند التسعير.
  static const catalogAvailability = '/catalog/availability';
  static const catalogPaymentMethods = '/catalog/payment-methods';

  /// تخطيط الرئيسيّة من لوحة التحكّم (SDUI).
  ///
  /// ‼️ **`?channel=app` إلزاميّة.** النطاق ثلاثيّ (متجر + قناة + لغة)، وبلا
  /// القناة يسقط الطلب على `web` فيستقبل التطبيق **تخطيط الموقع** — وهو ما كان
  /// يحدث فعلاً قبل توصيل المُعامِل في الكنترولر.
  static const cmsHome = '/cms/public/home?channel=app';

  /// تنقّل التطبيق من اللوحة: قائمةٌ جانبيّة + تبويبات سفليّة (المهمّة 1.6).
  static const cmsAppNavigation = '/cms/public/app-navigation';

  /// قياس ظهور مكوّنات التخطيط ونقراتها — دفعاتٌ لا حدثٌ واحد (المهمّة 5.1).
  static const sduiEvents = '/catalog/sdui-events';
  // طرق الشحن وأسعارها — المصدر الموثوق الذي يعيد الخادم حسابه عند الطلب.
  static const catalogShippingMethods = '/catalog/shipping-methods';

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
  // ‼️ إنشاء جلسة تابي من الخادم لا من الجهاز. حزمة تابي لا ترسل
  // `merchant_urls` إطلاقاً، فتنتهي شاشتها عند «سنعيدك الآن» بلا عنوانٍ تعود
  // إليه. وخادمنا يرسلها كما يفعل في الموقع.
  static const tabbySession = '/payments/tabby/sessions';
  static const tabbyRegisterPending = '/payments/tabby/register-pending';
  static const tabbyConfirm = '/payments/tabby/confirm';
  // تمارا — الجلسة من الخادم كتابي: تصلها عناوين العودة، ويُطبَّق التسعير
  // الموثوق وفحص المخزون قبل صفحة الدفع، ولا يبقى سرٌّ على الجهاز.
  static const tamaraSession = '/payments/tamara/sessions';
  static const tamaraConfirm = '/payments/tamara/confirm';
  // PayTabs — بطاقات. ‼️ عودتها POST بنموذج إلى خادمنا، وهو يُحوّل بـ303 إلى
  // صفحة النتيجة — فالشاشة تراقب **صفحة النتيجة** لا عنوان عودةٍ مباشر.
  static const paytabsSession = '/payments/paytabs/sessions';
  static const paytabsConfirm = '/payments/paytabs/confirm';
  static const noonInitiate = '/payments/noon/initiate';
  static const noonVerify = '/payments/noon/order'; // + /<noonOrderId>
  static const assistantChat = '/assistant/chat';
}
