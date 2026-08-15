import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/addresses_form_page.dart';
import '../../features/account/presentation/pages/addresses_page.dart';
import '../../features/account/presentation/pages/browsing_history_page.dart';
import '../../features/account/presentation/pages/coupons_page.dart';
import '../../features/account/presentation/pages/favorites_page.dart';
import '../../features/account/presentation/pages/gift_cards_page.dart';
import '../../features/account/presentation/pages/order_detail_page.dart';
import '../../features/account/presentation/pages/orders_page.dart';
import '../../features/account/presentation/pages/payment_methods_page.dart';
import '../../features/account/presentation/pages/points_page.dart';
import '../../features/account/presentation/pages/profile_page.dart';
import '../../features/account/presentation/pages/size_profiles_page.dart';
import '../../features/account/presentation/pages/stock_alerts_page.dart';
import '../../features/account/presentation/pages/wallet_page.dart';
import '../../features/assistant/presentation/pages/assistant_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../core/models/product_model.dart';
import '../../features/catalog/presentation/pages/category_deep_link_page.dart';
import '../../features/catalog/presentation/pages/preview_page.dart';
import '../../features/catalog/presentation/pages/product_by_id_page.dart';
import '../../features/catalog/presentation/pages/product_detail_page.dart';
import '../../features/catalog/presentation/pages/discover_section_page.dart';
import '../../features/catalog/presentation/pages/search_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../core/tracking/tracking_service.dart';
import '../../features/reels/presentation/pages/reels_page.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';

class AppRouter {
  /// ‼️ **يُترجَم رابط `tint://` إلى مسارٍ داخليّ قبل أن يراه الموجّه.**
  ///
  /// نظام أندرويد يُسلّم `tint://category/makeup` بمضيفٍ `category` ومسارٍ
  /// `/makeup` — أي أنّ **الجزء المهمّ يقع في `host` لا في `path`**. وتمريرُه
  /// كما هو يجعل الموجّه يبحث عن `/makeup` فيفتح شاشةً بيضاء.
  ///
  /// وترجمةُ الوجهات نفسها تبقى في `SduiAction` — هذه تُصلح الشكل فقط.
  static String normalizeDeepLink(Uri uri) {
    if (uri.scheme != 'tint') {
      return uri.path.isEmpty ? '/' : uri.path;
    }
    final segments = [uri.host, ...uri.pathSegments].where((s) => s.isNotEmpty);
    return segments.isEmpty ? '/' : '/${segments.join('/')}';
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    /**
     * ‼️ **الوجهةُ المجهولة تفتح الرئيسيّة ولا تُظهر خطأً.**
     *
     * الروابط تُنشَر في رسائل وإعلانات وتبقى سنوات، ونوعٌ نحذفه لاحقاً يترك
     * روابط حيّة في الدنيا. وشاشةُ «٤٠٤» في تطبيقٍ تبدو عطلاً لا رابطاً قديماً.
     */
    errorBuilder: (context, state) => const MainShellPage(),
    redirect: (context, state) {
      final uri = state.uri;

      /// ‼️ **التقاط معرّفات النقرة هنا لا في شاشة**: كلّ رابطٍ عميق يمرّ
      /// بهذه الدالّة مهما كانت وجهته، ووصلُ الالتقاط بشاشةٍ بعينها يُضيّع
      /// كلّ نقرةٍ تفتح شاشةً أخرى — وهي الأكثر.
      ///
      /// ولا يُنتظَر: الإسناد لا يجوز أن يؤخّر فتح الشاشة.
      if (uri.queryParameters.isNotEmpty) {
        unawaited(context.read<TrackingService>().captureClickIds(uri));
      }

      if (uri.scheme != 'tint') return null;
      final normalized = normalizeDeepLink(uri);
      return normalized == state.matchedLocation ? null : normalized;
    },
    routes: [
      /**
       * ‼️ **`category` وحده اليوم من بين وجهات الروابط العميقة.**
       *
       * و`product` و`page` **غير ممكنتين بعد** — ونقصٌ في التطبيق لا في العقد:
       *  · مسار `/product` القائم يفتح المنتج بكائنٍ مُمرَّر (`extra`) لا
       *    بمعرّف، فلا يستطيع رابطٌ فتحه. يلزمه مسار `product/:id` يجلب المنتج
       *    من `/catalog/products/:id` ثمّ يعرضه.
       *  · ولا شاشة لعرض صفحات CMS في التطبيق أصلاً.
       *
       * ورابطٌ لأيّهما يفتح الرئيسيّة بهدوء (`errorBuilder`) بدل شاشةٍ بيضاء.
       */
      GoRoute(
        path: '/category/:slug',
        builder: (context, state) =>
            CategoryDeepLinkPage(slug: state.pathParameters['slug'] ?? ''),
      ),
      /**
       * ‼️ **مسارٌ ثانٍ للمنتج بجانب `/product` لا بدلاً منه.**
       *
       * القائم يستقبل الكائن جاهزاً (`extra`) وهو الطريق السريع من البطاقة —
       * لا رحلة شبكةٍ ولا وميض تحميل. وهذا يستقبل معرّفاً ويجلبه، وهو الطريق
       * الوحيد الممكن لرابطٍ خارجيّ. ودمجُهما كان يُبطئ الطريق الشائع لأجل
       * الطريق النادر.
       */
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductByIdPage(productId: state.pathParameters['id'] ?? ''),
      ),
      /**
       * معاينة مسودّةٍ على الجهاز — `tint://preview/<token>` (المهمّة 4.3).
       *
       * ‼️ التوكن يحمل نطاقه داخل توقيعه، فلا يُمرَّر متجرٌ ولا قناةٌ من هنا.
       */
      GoRoute(
        path: '/preview/:token',
        builder: (context, state) =>
            PreviewPage(token: state.pathParameters['token'] ?? ''),
      ),
      /**
       * شريط فيديو المنتجات — **خارج القشرة عمداً**.
       *
       * ‼️ داخل `MainShellPage` كان الشريط السفليّ يبقى فوق المقطع فيقتطع
       * سُدسَ الشاشة من تجربةٍ كلّ قيمتها في ملء الشاشة. وخارجها يملأ الإطار
       * ويعود منه المستخدم بزرٍّ واحد.
       */
      GoRoute(
        path: '/reels',
        builder: (context, state) => const ReelsPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShellPage(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: 'product',
            builder: (context, state) => state.extra is ProductModel
                ? ProductDetailPage(product: state.extra as ProductModel)
                : const Scaffold(
                    body: Center(child: Text('المنتج غير متاح')),
                  ),
          ),
          // «عرض الكل» لرفّ اكتشاف. `extra` = slug القسم النشط كي تُفتح الشاشة
          // على القسم نفسه الذي كان المستخدم يتصفّحه.
          GoRoute(
            path: 'discover/:key',
            builder: (context, state) => DiscoverSectionPageView(
              sectionKey: state.pathParameters['key'] ?? '',
              category: state.extra is String ? state.extra as String : 'all',
            ),
          ),
          GoRoute(
            path: 'assistant',
            builder: (context, state) => const AssistantPage(),
          ),
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: 'checkout',
            builder: (context, state) => const CheckoutPage(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'points',
                builder: (context, state) => const PointsPage(),
              ),
              GoRoute(
                path: 'coupons',
                builder: (context, state) => const CouponsPage(),
              ),
              GoRoute(
                path: 'wallet',
                builder: (context, state) => const WalletPage(),
              ),
              GoRoute(
                path: 'orders',
                builder: (context, state) => const OrdersPage(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => OrderDetailPage(
                      orderId: state.pathParameters['orderId'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'favorites',
                builder: (context, state) => const FavoritesPage(),
              ),
              GoRoute(
                path: 'addresses',
                builder: (context, state) => const AddressesPage(),
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (context, state) => AddressFormPage(
                      addressId: state.uri.queryParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'payment-methods',
                builder: (context, state) => const PaymentMethodsPage(),
              ),
              GoRoute(
                path: 'browsing-history',
                builder: (context, state) => const BrowsingHistoryPage(),
              ),
              GoRoute(
                path: 'size-profiles',
                builder: (context, state) => const SizeProfilesPage(),
              ),
              GoRoute(
                path: 'gift-cards',
                builder: (context, state) => const GiftCardsPage(),
              ),
              GoRoute(
                path: 'stock-alerts',
                builder: (context, state) => const StockAlertsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
