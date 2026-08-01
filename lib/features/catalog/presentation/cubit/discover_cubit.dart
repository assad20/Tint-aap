import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/discover_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/repositories/catalog_repository.dart';

class DiscoverState {
  const DiscoverState({
    this.isLoading = true,
    this.isSwitchingTab = false,
    this.feed = const DiscoverFeed(),
    this.category = 'all',
    this.failed = false,
    this.recentlyViewed = const [],
  });

  final bool isLoading;

  /// تبديل تبويبٍ فوق محتوىً معروض. مفصولٌ عن `isLoading` كي لا تُستبدل
  /// الأرفف بهيكلٍ فارغ عند كلّ نقرة — القفزة البيضاء تُقرأ كعطل.
  final bool isSwitchingTab;

  final DiscoverFeed feed;
  final String category;

  /// تعذّر الجلب ولا محتوى سابق — الحالة الوحيدة التي تستحقّ رسالة خطأ.
  final bool failed;

  /// منتجاتٌ شاهدها صاحب الجهاز — محلّيّة بالكامل، لا تعبر الشبكة.
  final List<ProductModel> recentlyViewed;

  bool get hasContent => feed.sections.isNotEmpty;

  DiscoverState copyWith({
    bool? isLoading,
    bool? isSwitchingTab,
    DiscoverFeed? feed,
    String? category,
    bool? failed,
    List<ProductModel>? recentlyViewed,
  }) {
    return DiscoverState(
      isLoading: isLoading ?? this.isLoading,
      isSwitchingTab: isSwitchingTab ?? this.isSwitchingTab,
      feed: feed ?? this.feed,
      category: category ?? this.category,
      failed: failed ?? this.failed,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
    );
  }
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({
    required CatalogRepository repository,
    required AppPreferences appPreferences,
  })  : _repository = repository,
        _prefs = appPreferences,
        super(const DiscoverState());

  final CatalogRepository _repository;
  final AppPreferences _prefs;

  /// يُبطل نتيجة نداءٍ سبقه المستخدم بنقرةٍ أُخرى: من ينقر ثلاثة تبويبات
  /// بسرعة قد تصل استجابة الأوّل أخيراً فتعرض قسماً لم يعد مُختاراً.
  int _requestId = 0;

  Future<void> load({bool force = false}) async {
    if (state.hasContent && !force) return;
    await _fetch(state.category, isTabSwitch: false);
  }

  Future<void> selectCategory(String category) async {
    if (category == state.category) return;
    emit(state.copyWith(category: category));
    await _fetch(category, isTabSwitch: true);
  }

  Future<void> refresh() => _fetch(state.category, isTabSwitch: false);

  Future<void> _fetch(String category, {required bool isTabSwitch}) async {
    final id = ++_requestId;
    emit(state.copyWith(
      isLoading: !isTabSwitch && !state.hasContent,
      isSwitchingTab: isTabSwitch,
      failed: false,
    ));

    final feed = await _repository.fetchDiscover(category);
    if (id != _requestId || isClosed) return;

    emit(state.copyWith(
      isLoading: false,
      isSwitchingTab: false,
      feed: feed ?? state.feed,
      // يُقرأ عند كلّ جلب: المستخدم قد يكون تصفّح منتجاتٍ منذ آخر فتحة.
      recentlyViewed: _prefs.recentlyViewed,
      // الفشل يُعلَن فقط حين لا يوجد ما يُعرض؛ وإلّا أبقِ المعروض صامتاً.
      failed: feed == null && !state.hasContent,
    ));
  }
}
