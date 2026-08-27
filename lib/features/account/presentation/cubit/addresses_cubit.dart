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


  /// يمحو كلّ ما يخصّ الحساب السابق — **يُنادى عند تبدّل الهويّة.**
  ///
  /// ‼️ **الكيوبتات الحسابيّة عامّةٌ وتُجلَب مرّةً واحدة في عمر التشغيل**
  /// (`_loaded` في القشرة)، وتسجيلُ الخروج كان يمسح التوكن وحده. فمن سجّل
  /// خروجه ودخل بحسابٍ آخر على الجهاز نفسه **يرى بيانات من قبله**: عنوانه
  /// واسمه وجوّاله، وطلباته، ونقاطه. وأخطر من العرض أنّ شاشة الدفع تقرأ
  /// العنوان من هنا — فيُشحن طلبُ الثاني إلى عنوان الأوّل باسمه ورقمه.
  /// (رصده المالك 2026-08-27 بعد حذف حسابه ودخوله بآخر.)
  void clearForAccountSwitch() => emit(const AddressesState());

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

  /// ‼️ **الثلاث كانت تُعدّل الذاكرة ولا تُنادي الخادم إطلاقاً.**
  ///
  /// فالعنوان يُضاف ويظهر ويُشحَن إليه الطلب، ثمّ **يختفي عند أوّل إقلاع** —
  /// لأنّ `load()` يقرأ من الخادم ما لم يصله شيء. والخادم يملك `POST` و`PATCH`
  /// و`DELETE` منذ البداية.
  ///
  /// والنمط هنا **تفاؤليّ بتراجع**: تُعرَض النتيجة فوراً كي لا تنتظر الواجهة
  /// الشبكة، فإن رفض الخادم رجعت الحالة كما كانت **ورُمي الخطأ** — لا يُبتلَع.
  Future<void> remove(String id) async {
    final before = state.items;
    emit(state.copyWith(items: before.where((item) => item.id != id).toList()));
    try {
      emit(state.copyWith(items: await _repository.deleteAddress(id)));
    } catch (_) {
      emit(state.copyWith(items: before));
      rethrow;
    }
  }

  Future<void> makeDefault(String id) async {
    final before = state.items;
    final target = findById(id);
    if (target == null) return;
    emit(
      state.copyWith(
        items: before
            .map((item) => item.copyWith(isDefault: item.id == id))
            .toList(),
      ),
    );
    try {
      emit(state.copyWith(
        items: await _repository.saveAddress(
          target.copyWith(isDefault: true),
          isNew: false,
        ),
      ));
    } catch (_) {
      emit(state.copyWith(items: before));
      rethrow;
    }
  }

  /// يحفظ عنواناً ويُعيد ما أثبته الخادم — أو يرمي.
  ///
  /// ‼️ **المُعرّف من الخادم لا من `DateTime.now()`**: مُعرّفٌ محلّيّ يُنتج
  /// عنواناً لا يعرفه الخادم، فيفشل أوّل تعديلٍ عليه بـ404 بلا سببٍ ظاهر.
  Future<AddressModel> upsert(AddressModel address) async {
    final before = state.items;
    final isNew = address.id.trim().isEmpty ||
        !before.any((item) => item.id == address.id);

    // ‼️ **الافتراضيّ الأوّل يُفرَض ولا يُترك للعميل**: أوّل عنوانٍ في حسابٍ
    //    فارغ هو الافتراضيّ حكماً، وإلّا بقي الحساب بلا افتراضيّ فيُختار
    //    «الأوّل في القائمة» صامتاً عند كلّ دفع.
    final target = before.isEmpty ? address.copyWith(isDefault: true) : address;

    final normalized = target.isDefault
        ? before.map((item) => item.copyWith(isDefault: false)).toList()
        : [...before];
    final index = normalized.indexWhere((item) => item.id == target.id);
    if (index == -1) {
      emit(state.copyWith(items: [...normalized, target]));
    } else {
      normalized[index] = target;
      emit(state.copyWith(items: normalized));
    }

    try {
      // ‼️ **القائمة من الخادم تحلّ محلّ المعروض كاملةً** — لا تُدمَج: الحفظ
      //    قد يُنزل راية الافتراضيّ عن عنوانٍ آخر، ودمجٌ من عندنا يترك
      //    افتراضيَّين في الشاشة وواحداً عند الخادم.
      final serverItems = await _repository.saveAddress(target, isNew: isNew);
      emit(state.copyWith(items: serverItems));

      if (!isNew) {
        return serverItems.firstWhere(
          (item) => item.id == target.id,
          orElse: () => target,
        );
      }
      // الجديد هو المُعرّف الذي لم يكن في القائمة قبل الحفظ — والمُعرّف يصدره
      // الخادم، فلا سبيل إلى معرفته إلّا بهذه المقارنة.
      final beforeIds = before.map((item) => item.id).toSet();
      final fresh =
          serverItems.where((item) => !beforeIds.contains(item.id)).toList();
      if (fresh.isNotEmpty) return fresh.last;
      return serverItems.isNotEmpty ? serverItems.last : target;
    } catch (_) {
      emit(state.copyWith(items: before));
      rethrow;
    }
  }
}
