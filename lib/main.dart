import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';

import 'app/config/app_config.dart';
import 'app/tint_app.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/token_storage.dart';
import 'features/account/data/datasources/account_remote_data_source.dart';
import 'features/account/data/repositories/account_repository_impl.dart';
import 'features/account/domain/repositories/account_repository.dart';
import 'features/account/presentation/cubit/addresses_cubit.dart';
import 'features/account/presentation/cubit/favorites_cubit.dart';
import 'features/account/presentation/cubit/orders_cubit.dart';
import 'features/account/presentation/cubit/profile_cubit.dart';
import 'features/account/presentation/cubit/rewards_cubit.dart';
import 'features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'features/assistant/data/repositories/assistant_repository_impl.dart';
import 'features/assistant/domain/repositories/assistant_repository.dart';
import 'features/assistant/presentation/cubit/assistant_cubit.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'features/catalog/data/repositories/catalog_repository_impl.dart';
import 'features/catalog/domain/repositories/catalog_repository.dart';
import 'features/catalog/presentation/cubit/categories_cubit.dart';
import 'features/catalog/presentation/cubit/home_store_cubit.dart';
import 'features/catalog/presentation/cubit/search_cubit.dart';
import 'features/catalog/presentation/cubit/trends_cubit.dart';
import 'features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'features/checkout/data/repositories/checkout_repository_impl.dart';
import 'features/checkout/domain/repositories/checkout_repository.dart';
import 'features/checkout/presentation/cubit/checkout_cubit.dart';
import 'features/shell/presentation/cubit/shell_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = AppConfig.fromEnvironment();
  if (appConfig.hasTabbyConfig) {
    TabbySDK().setup(withApiKey: appConfig.tabbyPublicKey);
  }

  final appPreferences = AppPreferences();
  await appPreferences.initialize();
  final tokenStorage = TokenStorage();

  final apiClient = ApiClient(
    baseUrl: appConfig.baseUrl,
    tokenStorage: tokenStorage,
  );

  final catalogRepository = CatalogRepositoryImpl(
    remoteDataSource: CatalogRemoteDataSource(apiClient),
  );
  final accountRepository = AccountRepositoryImpl(
    remoteDataSource: AccountRemoteDataSource(apiClient),
  );
  final checkoutRepository = CheckoutRepositoryImpl(
    remoteDataSource: CheckoutRemoteDataSource(apiClient),
  );
  final assistantRepository = AssistantRepositoryImpl(
    remoteDataSource: AssistantRemoteDataSource(apiClient),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: appConfig),
        RepositoryProvider.value(value: appPreferences),
        RepositoryProvider.value(value: tokenStorage),
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider<CatalogRepository>.value(value: catalogRepository),
        RepositoryProvider<AccountRepository>.value(value: accountRepository),
        RepositoryProvider<CheckoutRepository>.value(value: checkoutRepository),
        RepositoryProvider<AssistantRepository>.value(value: assistantRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ShellCubit()),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(
            create: (context) => HomeStoreCubit(
              catalogRepository: context.read<CatalogRepository>(),
              appPreferences: context.read<AppPreferences>(),
            )..bootstrap(),
          ),
          BlocProvider(
            create: (context) => TrendsCubit(
              repository: context.read<CatalogRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => CategoriesCubit(
              repository: context.read<CatalogRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => SearchCubit(
              repository: context.read<CatalogRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ProfileCubit(
              repository: context.read<AccountRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => RewardsCubit(
              repository: context.read<AccountRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => OrdersCubit(
              repository: context.read<AccountRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => FavoritesCubit(
              repository: context.read<AccountRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => AddressesCubit(
              repository: context.read<AccountRepository>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) => CheckoutCubit(
              repository: context.read<CheckoutRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AssistantCubit(
              repository: context.read<AssistantRepository>(),
            ),
          ),
        ],
        child: const TintApp(),
      ),
    ),
  );
}
