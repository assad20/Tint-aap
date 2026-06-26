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

  final AccountRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final bundle = await _repository.fetchRewardsBundle();
    emit(state.copyWith(isLoading: false, bundle: bundle));
  }
}
