import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../domain/repositories/account_repository.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = true,
    this.bundle,
    this.errorMessage,
  });

  final bool isLoading;
  final ProfileBundle? bundle;
  final String? errorMessage;

  ProfileState copyWith({
    bool? isLoading,
    ProfileBundle? bundle,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      bundle: bundle ?? this.bundle,
      errorMessage: errorMessage,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required AccountRepository repository})
      : _repository = repository,
        super(const ProfileState());

  final AccountRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final bundle = await _repository.fetchProfileBundle();
    emit(state.copyWith(isLoading: false, bundle: bundle));
  }
}
