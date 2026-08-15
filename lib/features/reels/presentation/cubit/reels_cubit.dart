import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reels_repository.dart';
import '../../domain/reel_model.dart';

class ReelsState {
  const ReelsState({
    this.items = const <ReelModel>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.muted = false,
  });

  final List<ReelModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final bool muted;

  /// حُمّل ولم يجد شيئاً — تُفرَّق عن «لم يُحمَّل بعد» كي لا تُعرض رسالة الفراغ
  /// على شاشةٍ ما زالت تُحمّل.
  bool get isEmpty => !isLoading && page > 0 && items.isEmpty;

  ReelsState copyWith({
    List<ReelModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    bool? muted,
  }) =>
      ReelsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        muted: muted ?? this.muted,
      );
}

class ReelsCubit extends Cubit<ReelsState> {
  ReelsCubit(this._repository) : super(const ReelsState());

  final ReelsRepository _repository;

  /// ‼️ **عتبةٌ لا نهاية القائمة.** الجلب عند آخر مقطعٍ يعني انتظاراً مرئيّاً
  /// بين المقطع الأخير والتالي؛ وثلاثةٌ قبله تكفي لأن تصل الصفحة قبل الوصول
  /// إليها على شبكةٍ متوسّطة.
  static const _prefetchThreshold = 3;

  Future<void> load() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true));
    final page = await _repository.fetch(page: 1);
    emit(state.copyWith(
      items: page.items,
      hasMore: page.hasMore,
      page: 1,
      isLoading: false,
    ));
  }

  /// يُستدعى عند كلّ تبديل صفحة — ويقرّر بنفسه متى يجلب.
  Future<void> onPageChanged(int index) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    if (index < state.items.length - _prefetchThreshold) return;

    emit(state.copyWith(isLoadingMore: true));
    final next = state.page + 1;
    final page = await _repository.fetch(page: next);
    if (isClosed) return;

    /// ‼️ **تُستبعَد المكرّرات بالمعرّف.** الترتيب بـ`updatedAt` يتحرّك تحت
    /// الترقيم: منتجٌ يُحدَّث بين صفحتين ينتقل للصفحة الأولى فيصل ثانيةً هنا.
    /// وعنصرٌ مكرّر في `PageView` بمفتاحٍ مكرّر يُربك المشغّلات لا العرض وحده.
    final seen = state.items.map((reel) => reel.id).toSet();
    final fresh = page.items.where((reel) => seen.add(reel.id)).toList();

    emit(state.copyWith(
      items: [...state.items, ...fresh],
      // ‼️ صفحةٌ لم تُضِف جديداً تُنهي التصفّح ولو قال الخادم «هناك مزيد» —
      //    وإلّا دار الجلب بلا نهاية على مكرّراتٍ تُستبعَد كلّها.
      hasMore: page.hasMore && fresh.isNotEmpty,
      page: next,
      isLoadingMore: false,
    ));
  }

  void toggleMute() => emit(state.copyWith(muted: !state.muted));
}
