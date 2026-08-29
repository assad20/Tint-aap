import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/account_repository.dart';

class StockAlertsState {
  const StockAlertsState({
    this.isLoading = false,
    this.items = const [],
  });

  final bool isLoading;
  final List<StockAlertModel> items;

  /// ‼️ **يُقرأ من صفحة المنتج لتعرف حال الزرّ** — «نبّهني» أم «إلغاء التنبيه».
  /// وبلا هذا يظلّ الزرّ يقول «نبّهني» بعد الاشتراك، فيضغطه العميل ثانيةً
  /// ويظنّ الأولى ضاعت.
  bool has(String productId) =>
      items.any((item) => item.productId == productId);

  StockAlertsState copyWith({bool? isLoading, List<StockAlertModel>? items}) {
    return StockAlertsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

/// تنبيهات التوفّر — «نبّهني حين يعود هذا المنتج».
///
/// ‼️ **الثلاثة تُعيد القائمة كاملةً من الخادم** ولا تُعدَّل الذاكرة محلّيّاً:
/// الاشتراك `upsert` عند الخادم، وحالةٌ محلّيّة تُخمّن النتيجة تفترق عنه عند
/// أوّل تزامنٍ من جهازٍ آخر.
class StockAlertsCubit extends Cubit<StockAlertsState> {
  StockAlertsCubit({required AccountRepository repository})
      : _repository = repository,
        super(const StockAlertsState());

  final AccountRepository _repository;

  /// ‼️ **يُفرَّغ عند تبديل الحساب** — كبقيّة الشاشات الحسابيّة.
  void clearForAccountSwitch() => emit(const StockAlertsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      emit(state.copyWith(isLoading: false, items: await _repository.fetchStockAlerts()));
    } catch (_) {
      // ‼️ قائمةٌ فارغة أهون من شاشة خطأ: التنبيه رفاهيّة لا مسار شراء.
      emit(state.copyWith(isLoading: false));
    }
  }

  /// يشترك ويُعيد `true` إن نجح — فتقول الشاشة ما وقع.
  Future<bool> subscribe(ProductModel product) async {
    try {
      emit(state.copyWith(items: await _repository.addStockAlert(product)));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unsubscribe(String productId) async {
    try {
      emit(state.copyWith(items: await _repository.removeStockAlert(productId)));
      return true;
    } catch (_) {
      return false;
    }
  }
}
