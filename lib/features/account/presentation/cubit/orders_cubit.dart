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


  /// يمحو كلّ ما يخصّ الحساب السابق — **يُنادى عند تبدّل الهويّة.**
  ///
  /// ‼️ **الكيوبتات الحسابيّة عامّةٌ وتُجلَب مرّةً واحدة في عمر التشغيل**
  /// (`_loaded` في القشرة)، وتسجيلُ الخروج كان يمسح التوكن وحده. فمن سجّل
  /// خروجه ودخل بحسابٍ آخر على الجهاز نفسه **يرى بيانات من قبله**: عنوانه
  /// واسمه وجوّاله، وطلباته، ونقاطه. وأخطر من العرض أنّ شاشة الدفع تقرأ
  /// العنوان من هنا — فيُشحن طلبُ الثاني إلى عنوان الأوّل باسمه ورقمه.
  /// (رصده المالك 2026-08-27 بعد حذف حسابه ودخوله بآخر.)
  void clearForAccountSwitch() => emit(const OrdersState());

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
