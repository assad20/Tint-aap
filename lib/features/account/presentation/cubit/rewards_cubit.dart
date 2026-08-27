import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../domain/repositories/account_repository.dart';

class RewardsState {
  const RewardsState({
    this.isLoading = true,
    this.bundle,
  });

  final bool isLoading;
  final RewardsBundle? bundle;

  RewardsState copyWith({
    bool? isLoading,
    RewardsBundle? bundle,
  }) {
    return RewardsState(
      isLoading: isLoading ?? this.isLoading,
      bundle: bundle ?? this.bundle,
    );
  }
}

class RewardsCubit extends Cubit<RewardsState> {
  RewardsCubit({required AccountRepository repository})
      : _repository = repository,
        super(const RewardsState());


  /// يمحو كلّ ما يخصّ الحساب السابق — **يُنادى عند تبدّل الهويّة.**
  ///
  /// ‼️ **الكيوبتات الحسابيّة عامّةٌ وتُجلَب مرّةً واحدة في عمر التشغيل**
  /// (`_loaded` في القشرة)، وتسجيلُ الخروج كان يمسح التوكن وحده. فمن سجّل
  /// خروجه ودخل بحسابٍ آخر على الجهاز نفسه **يرى بيانات من قبله**: عنوانه
  /// واسمه وجوّاله، وطلباته، ونقاطه. وأخطر من العرض أنّ شاشة الدفع تقرأ
  /// العنوان من هنا — فيُشحن طلبُ الثاني إلى عنوان الأوّل باسمه ورقمه.
  /// (رصده المالك 2026-08-27 بعد حذف حسابه ودخوله بآخر.)
  void clearForAccountSwitch() => emit(const RewardsState());

  final AccountRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final bundle = await _repository.fetchRewardsBundle();
    emit(state.copyWith(isLoading: false, bundle: bundle));
  }
}
