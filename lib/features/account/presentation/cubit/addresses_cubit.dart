import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../domain/repositories/account_repository.dart';

class AddressesState {
  const AddressesState({
    this.isLoading = true,
    this.items = const [],
  });

  final bool isLoading;
  final List<AddressModel> items;

  AddressesState copyWith({
    bool? isLoading,
    List<AddressModel>? items,
  }) {
    return AddressesState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class AddressesCubit extends Cubit<AddressesState> {
  AddressesCubit({required AccountRepository repository})
      : _repository = repository,
        super(const AddressesState());

  final AccountRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final items = await _repository.fetchAddresses();
    emit(state.copyWith(isLoading: false, items: items));
  }

  AddressModel? findById(String? id) {
    if (id == null) return null;
    try {
      return state.items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  void remove(String id) {
    emit(
      state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      ),
    );
  }

  void makeDefault(String id) {
    emit(
      state.copyWith(
        items: state.items
            .map((item) => item.copyWith(isDefault: item.id == id))
            .toList(),
      ),
    );
  }

  void upsert(AddressModel address) {
    final normalized = address.isDefault
        ? state.items
            .map((item) => item.copyWith(isDefault: false))
            .toList()
        : [...state.items];

    final index = normalized.indexWhere((item) => item.id == address.id);
    if (index == -1) {
      emit(state.copyWith(items: [...normalized, address]));
      return;
    }

    normalized[index] = address;
    emit(state.copyWith(items: normalized));
  }
}
