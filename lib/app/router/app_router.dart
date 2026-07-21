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
import '../../features/catalog/presentation/pages/search_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShellPage(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchPage(),
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
