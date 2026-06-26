import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../domain/repositories/account_repository.dart';

class OrdersState {
  const OrdersState({
    this.isLoading = true,
    this.orders = const [],
  });

  final bool isLoading;
  final List<OrderModel> orders;

  OrdersState copyWith({
    bool? isLoading,
    List<OrderModel>? orders,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
    );
  }
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({required AccountRepository repository})
      : _repository = repository,
        super(const OrdersState());

  final AccountRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final orders = await _repository.fetchOrders();
    emit(state.copyWith(isLoading: false, orders: orders));
  }

  OrderModel? findById(String orderId) {
    try {
      return state.orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }
}
