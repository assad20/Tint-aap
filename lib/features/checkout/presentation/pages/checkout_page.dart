import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';
import 'noon_webview_page.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../reels/data/reel_stats_reporter.dart';
import 'payment_webview_page.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/models/shipping_method_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../account/presentation/cubit/addresses_cubit.dart';
import '../../../account/presentation/pages/addresses_form_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/models/payment_method_model.dart';
import '../../domain/models/tabby_payment_result.dart';
import '../cubit/checkout_cubit.dart';
import '../widgets/apple_pay_section.dart';
import '../widgets/payment_mark.dart';
import '../widgets/tabby_promo_snippet.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with WidgetsBindingObserver {
  final _tabbyEmailController = TextEditingController();
  final _tabbyDobController = TextEditingController();
  DateTime? _selectedDob;

  // نموذج بيانات العميل والشحن — يُملأ مسبقاً من حساب العميل + عنوانه المحفوظ.
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _neighborhood = TextEditingController();
  final _details = TextEditingController();
  String _addressId = 'mobile-form';

  /// عنوان الزائر — يسكن الطلب الحاليّ ولا يُحفَظ عند الخادم (لا حساب له).
  AddressModel? _guestAddress;
  double? _lat;
  double? _lng;

  /// العنوان المحفوظ المختار — لعميلٍ مسجَّل. و`null` يعني «الافتراضيّ».
  ///
  /// ‼️ **مُعرّفٌ لا نسخة**: حفظُ نسخةٍ من العنوان هنا يجعل تعديلَه من الورقة
  /// لا يظهر في البطاقة حتّى يُعاد فتح الشاشة.
  String? _selectedAddressId;

  /// ‼️ **أكثر ما يحدث فعلاً**: ينتبه المشتري لانقطاع الشبكة فيخرج إلى
  /// الإعدادات ويُصلحها ويعود — فلا يجوز أن يجد الشاشة كما تركها. وهذا هو
  /// البديل عن زرّ «إعادة المحاولة» الذي رفضه المالك بحقّ: العميل فعل ما
  /// يخصّه (أصلح شبكته)، والتطبيق يفعل ما يخصّه بلا أن يُطالبه بشيء.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    context.read<CheckoutCubit>().refreshIfStale();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // منفذٌ ثانٍ للسلّة: من يصل هنا مباشرةً لا يمرّ ببانرها. المراجعة تُظهر
    // النفاد قبل إدخال العنوان لا بعد الدفع.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().revalidateStock();

      /// ‼️ **`begin_checkout` عند فتح الشاشة لا عند الضغط على «تأكيد».**
      ///
      /// معناه في مخطّط GA4: «بدأ المشتري إتمام الطلب» — والبدء هو الوصول إلى
      /// هنا. وربطُه بزرّ التأكيد يجعله مساوياً للشراء تقريباً، فيختفي أهمّ
      /// تسرّبٍ في القمع: من بدأ ولم يُكمل.
      final items = context.read<CartCubit>().state.items;
      if (items.isEmpty) return;
      final trackingItems = [
        for (final row in items)
          TrackingEvents.item(row.product, quantity: row.quantity),
      ];
      // ‼️ تُغذّى مرّةً هنا: الكيوبت يحتاجها لحدثَي الشحن والدفع، ولا يقرأ
      //    كيوبت السلّة بنفسه — اعتماديّةٌ لا يحتاجها الدفع.
      context.read<CheckoutCubit>().trackingItems = trackingItems;
      unawaited(context.read<TrackingService>().logBeginCheckout(trackingItems));
    });
    final customer = context.read<AuthCubit>().state.customer;
    if (customer != null) {
      _name.text = customer.name ?? '';
      _phone.text = customer.phone;
      _email.text = customer.email ?? '';
    }
    final addresses = context.read<AddressesCubit>().state.items;
    if (addresses.isNotEmpty) {
      final a = addresses.firstWhere(
        (x) => x.isDefault,
        orElse: () => addresses.first,
      );
      _selectedAddressId = a.id;
      // ‼️ **يُملأ النموذج أيضاً** وإن كان مخفيّاً: هو مسار الزائر، وإن سجّل
      //    العميل خروجه وهو واقفٌ هنا وجد بياناته حاضرةً بدل شاشةٍ فارغة.
      _addressId = a.id;
      if (_name.text.isEmpty) _name.text = a.recipient;
      if (_phone.text.isEmpty) _phone.text = a.mobile;
      _city.text = a.city;
      _neighborhood.text = a.neighborhood;
      _details.text = a.details;
      _lat = a.lat;
      _lng = a.lng;
    }
    if (_tabbyEmailController.text.isEmpty) {
      _tabbyEmailController.text = _email.text;
    }
    // وسائل الدفع المفعّلة من الخادم (المصدر الوحيد للوسائل والرسوم).
    context.read<CheckoutCubit>().loadPaymentMethods();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabbyEmailController.dispose();
    _tabbyDobController.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _neighborhood.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final address = _currentAddress();

    return TintPageScaffold(
      title: 'إتمام الطلب',
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.verified_user_outlined, color: TintColors.success),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          /// ‼️ **مساران لا واحد.**
          ///
          /// العميل المسجَّل عنوانه محفوظٌ عند الخادم، فيُعرَض **ملخّصاً يُقرأ
          /// في ثانية** لا نموذجاً بستّة حقولٍ مملوءةٍ سلفاً — وكان يُطالَب
          /// بمراجعة ما لا يحتاج تغييره في كلّ طلب.
          ///
          /// والزائر بلا حساب لا يملك عنواناً محفوظاً ولا نقاط حفظٍ عند الخادم
          /// (النقاط محميّةٌ بالتوكن)، فيبقى له النموذج كما هو — وإسقاطُه كان
          /// سيمنع الشراء بلا تسجيل.
          if (_savedFlow(context))
            _DeliveryCard(
              address: _selectedSaved(context),
              accountName: context.watch<AuthCubit>().state.customer?.name,
              accountPhone: context.watch<AuthCubit>().state.customer?.phone,
              onChange: _openAddressPicker,
              onEdit: _openAddressEditor,
            )
          /// ‼️ **والزائر يرى البطاقة نفسها لا نموذجاً مفروشاً** (طلب المالك
          /// 2026-08-25). ستّة حقولٍ فارغة هي أوّل ما يواجهه في أوّل طلبٍ له،
          /// وهي **أطول ما في الشاشة** وأثقل ما فيها: تُقرأ استمارةً قبل أن
          /// يشتري. والبطاقة تسأله سؤالاً واحداً — «أين نوصّل؟» — والباقي في
          /// شاشةٍ مخصَّصة **فيها الخريطة**، وهي أدقّ من الوصف وأسرع منه.
          ///
          /// ‼️ **ونفس المحرّر لا نسخةً ثانية**: `AddressFormPage` في وضع
          /// `local` — يُعيد العنوان ولا يحفظه (نقاط الحفظ محميّةٌ بالتوكن).
          /// ومحرّران للشيء نفسه يتباعدان مع أوّل تعديل، فيحفظ أحدهما دبّوس
          /// الخريطة والآخر لا.
          else
            _DeliveryCard(
              address: _guestAddress,
              accountName: null,
              accountPhone: null,
              // لا محفوظات للزائر — فلا شيء «يُغيَّر» إليه، و«تعديل» تكفي.
              onChange: null,
              savesForLater: false,
              onEdit: ({String? id}) => _editGuestAddress(),
            ),
          const SizedBox(height: 12),
          const _ProductsMiniSummary(),
          const SizedBox(height: 12),
          const _ShippingMethodsCard(),
          const SizedBox(height: 12),
          _PaymentMethodsCard(
            address: address,
            tabbyEmailController: _tabbyEmailController,
            tabbyDobController: _tabbyDobController,
            selectedDob: _selectedDob,
            onSelectDob: _pickDateOfBirth,
          ),
          const SizedBox(height: 12),
          _CheckoutTotalCard(
            address: address,
            tabbyEmailController: _tabbyEmailController,
            tabbyDobController: _tabbyDobController,
          ),
        ],
      ),
    );
  }

  /// يفتح محرّر العنوان للزائر، ثمّ **يملأ الحقول التي يقرأها الطلب**.
  ///
  /// ‼️ **الحقول تبقى مصدر الحقيقة ولو اختفت من الشاشة.** `_currentAddress()`
  /// يبنيها منها، و`_submit` يقرأها — فتغذيتُها هنا تُبقي مسار الطلب كما هو
  /// حرفيّاً. ونسخُ المنطق إلى مصدرٍ ثانٍ كان سيُنتج عنواناً يُعرَض وآخر يُشحَن.
  Future<void> _editGuestAddress() async {
    final result = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(local: true, initial: _guestAddress),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _guestAddress = result;
      _name.text = result.recipient;
      _phone.text = result.mobile;
      _city.text = result.city;
      _neighborhood.text = result.neighborhood;
      _details.text = result.details;
      _lat = result.lat;
      _lng = result.lng;
    });
  }

  /// هل نحن على مسار العناوين المحفوظة؟ — مسجَّلٌ **وله عنوانٌ واحد فأكثر**.
  bool _savedFlow(BuildContext context) =>
      context.watch<AuthCubit>().state.customer != null;

  /// العنوان المختار من المحفوظات — أو الافتراضيّ، أو `null` إن لم يكن ثمّة.
  AddressModel? _selectedSaved(BuildContext context) =>
      _resolveSaved(context.watch<AddressesCubit>().state.items);

  AddressModel? _resolveSaved(List<AddressModel> items) {
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.id == _selectedAddressId) return item;
    }
    return items.firstWhere((item) => item.isDefault, orElse: () => items.first);
  }

  /// ورقة اختيار العنوان — والإضافة والتعديل يفتحان **المحرّر نفسه** الذي في
  /// الحساب، فلا محرّران يتباعدان.
  Future<void> _openAddressPicker() async {
    final cubit = context.read<AddressesCubit>();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressPickerSheet(
        addresses: cubit.state.items,
        selectedId: _resolveSaved(cubit.state.items)?.id,
      ),
    );
    if (!mounted || chosen == null) return;

    if (chosen == _kAddNewAddress) {
      await _openAddressEditor();
      return;
    }
    if (chosen.startsWith(_kEditAddressPrefix)) {
      await _openAddressEditor(id: chosen.substring(_kEditAddressPrefix.length));
      return;
    }
    setState(() => _selectedAddressId = chosen);
  }

  Future<void> _openAddressEditor({String? id}) async {
    final saved = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(builder: (_) => AddressFormPage(addressId: id)),
    );
    if (!mounted || saved == null) return;
    // ما حُفظ يُختار فوراً: من أضاف عنواناً وهو يدفع يريد الشحن إليه.
    setState(() => _selectedAddressId = saved.id);
  }

  /// عنوان الطلب: المحفوظ المختار لمن سجّل، ونموذجُ الزائر لمن لم يسجّل.
  AddressModel _currentAddress() {
    final saved = _savedFlow(context) ? _selectedSaved(context) : null;
    if (saved != null) return saved;

    return AddressModel(
      id: _addressId,
      title: 'التوصيل',
      recipient: _name.text.trim(),
      mobile: _phone.text.trim(),
      city: _city.text.trim(),
      neighborhood: _neighborhood.text.trim(),
      details: _details.text.trim(),
      // ‼️ **كانت `true` مثبَّتة.**
      //
      // فكلّ طلبٍ يُعلن عنوانه افتراضيّاً: يشتري العميل إلى عنوان العمل مرّةً
      // فيصير العمل افتراضيّه بلا أن يطلب، ويُشحن التالي إليه. والافتراضيّ
      // يُختار بمفتاحٍ صريح في محرّر العناوين لا بأثرٍ جانبيٍّ للشراء.
      isDefault: false,
      lat: _lat,
      lng: _lng,
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TintColors.sand,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() {
      _selectedDob = picked;
      _tabbyDobController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }
}

// نموذج بيانات العميل والشحن (مطابق للمتجر) — يُملأ من الحساب ويُحرّر يدويّاً.
/// قِيَمٌ تعود من ورقة الاختيار بدل نوعٍ خاصّ — الورقة تُعيد نصّاً واحداً.
const String _kAddNewAddress = '__add__';
const String _kEditAddressPrefix = 'edit:';

/// بطاقة التوصيل لعميلٍ مسجَّل — **ملخّصٌ لا نموذج**.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.address,
    required this.accountName,
    required this.accountPhone,
    required this.onChange,
    required this.onEdit,
    this.savesForLater = true,
  });

  final AddressModel? address;
  final String? accountName;
  final String? accountPhone;

  /// `null` = لا محفوظات يُنتقل بينها (الزائر) ⇒ لا يُعرَض زرّ «تغيير».
  ///
  /// ‼️ **زرٌّ يفتح ورقةً فارغة أسوأ من غيابه**: يُقرأ عطلاً لا خياراً مفقوداً.
  final VoidCallback? onChange;

  final Future<void> Function({String? id}) onEdit;

  /// ‼️ **«يُحفظ عنوانك لما بعده» وعدٌ لا يُوفى للزائر** — لا حساب يحفظ فيه.
  /// ووعدٌ صغير يُخلَف في شاشة دفعٍ يُكلّف أكثر ممّا يُوفّر.
  final bool savesForLater;

  @override
  Widget build(BuildContext context) {
    final a = address;

    return TintSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ‼️ **هويّة الحساب سطرٌ لا بطاقة، ولا تُحرَّر من هنا.**
          ///
          /// جوّال الجلسة المُثبَت هو **وحده** ما يُصرَف به رصيد المحفظة
          /// والنقاط عند الخادم؛ وجوّال المستلم حقلُ توصيلٍ يسكن العنوان.
          /// وعرضُهما في بطاقةٍ واحدة قابلةٍ للتحرير يُغري بتبديل الهويّة من
          /// شاشة الدفع — وهو ما يحرسه الخادم أصلاً، فلا تُقدَّم له واجهةٌ
          /// توحي بأنّه ممكن.
          if ((accountPhone ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 16, color: TintColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'الحساب: ${(accountName ?? '').trim().isEmpty ? 'أنت' : accountName!.trim()} · ${accountPhone!.trim()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TintColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          if (a == null) ...[
            const Text(
              'عنوان التوصيل',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              savesForLater
                  ? 'أوّل طلب — يُحفظ عنوانك لما بعده.'
                  : 'أضيفي عنوانك وحدّدي موقعه على الخريطة.',
              style: const TextStyle(color: TintColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TintSecondaryButton(
                label: 'أضيفي عنوان التوصيل',
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                // ‼️ نصٌّ أسود بطلب المالك — والإطار والأيقونة بلون الهويّة.
                labelColor: TintColors.charcoal,
                onPressed: () => onEdit(),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'التوصيل إلى',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: TintColors.textMuted,
                    ),
                  ),
                ),
                if (onChange != null)
                TextButton(
                  onPressed: onChange,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'تغيير',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: TintColors.sand,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  a.title.trim().isEmpty ? 'التوصيل' : a.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                if (a.isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: TintColors.blush,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'افتراضيّ',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA2705F),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),

            /// ‼️ **اسم المستلم أوّلاً وبارزاً — وكان مدفوناً في سطرٍ رماديّ.**
            ///
            /// من له عناوين أهله وزوجته ومكتبه **يميّزها بالاسم** لا بالحيّ.
            /// وبطاقةٌ تقول «الرياض — الورود» ولا تقول لمن تُرسَل تُجبره على
            /// فتح كلّ واحدةٍ ليعرف. (مقارنةٌ بمنافسٍ يعرضه بارزاً.)
            if (a.recipient.trim().isNotEmpty)
              Text(
                a.recipient,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
              ),

            /// ‼️ **سطرٌ واحدٌ متّصل كما يُكتب العنوان**: «2868 طريق العروبة،
            /// العليا، الرياض». وتقسيمُه أسطراً يجعل العين تجمعه بنفسها.
            /// ورقمُ المبنى يُصدَّر الشارع — أوّل ما يبحث عنه المندوب.
            Text(
              a.line,
              style: const TextStyle(fontSize: 13),
            ),

            /// ‼️ **الرمز الوطنيّ بخطٍّ لاتينيّ في سطرٍ مستقلّ**: هو أدقّ ما في
            /// العنوان — يدلّ على المبنى بعينه بينما يدلّ الحيّ على آلافٍ —
            /// ودمجُه في سطرٍ عربيّ يقلب ترتيب حروفه بصريّاً.
            if (a.codesLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  a.codesLine!,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

            Text(
              a.mobile,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 12, color: TintColors.textMuted),
            ),
            const SizedBox(height: 9),
            const Divider(height: 1),
            const SizedBox(height: 8),

            /// ‼️ **غياب الدبّوس يُقال ولا يُترك للصمت**: المندوب يصل بالدبّوس
            /// أسرع من الوصف، وعنوانٌ بلا موقعٍ يتأخّر — والعميل لا يعلم لماذا.
            Row(
              children: [
                Icon(
                  a.lat != null && a.lng != null
                      ? Icons.where_to_vote_rounded
                      : Icons.wrong_location_outlined,
                  size: 16,
                  color: a.lat != null && a.lng != null
                      ? TintColors.success
                      : TintColors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    a.lat != null && a.lng != null
                        ? 'الموقع محدَّد على الخريطة'
                        : 'لم يُحدَّد الموقع — قد يتأخّر المندوب',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: a.lat != null && a.lng != null
                          ? TintColors.success
                          : TintColors.warning,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onEdit(id: a.id),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    a.lat != null && a.lng != null ? 'تعديل' : 'تحديد',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: TintColors.sand,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ورقة اختيار العنوان — تُعيد المُعرّف، أو `_kAddNewAddress`، أو
/// `edit:<id>`.
class _AddressPickerSheet extends StatelessWidget {
  const _AddressPickerSheet({
    required this.addresses,
    required this.selectedId,
  });

  final List<AddressModel> addresses;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'عناوين التوصيل',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Text(
                  'اختاري أو أضيفي',
                  style: TextStyle(fontSize: 11.5, color: TintColors.textMuted),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final a = addresses[index];
                final selected = a.id == selectedId;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(a.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? TintColors.blush : Colors.white,
                      border: Border.all(
                        color: selected ? TintColors.sand : TintColors.line,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 19,
                          color: selected ? TintColors.sand : const Color(0xFFCFD3D8),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    a.title.trim().isEmpty ? 'عنوان' : a.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (a.isDefault) ...[
                                    const SizedBox(width: 6),
                                    const Text(
                                      'افتراضيّ',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFA2705F),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${a.city}، ${a.neighborhood} — ${a.details}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              Text(
                                '${a.recipient} · ${a.mobile}'
                                '${a.lat != null && a.lng != null ? ' · 📍' : ''}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: TintColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pop('$_kEditAddressPrefix${a.id}'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'تعديل',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: TintColors.sand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 16 + media.padding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: TintSecondaryButton(
                label: 'إضافة عنوان جديد',
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop(_kAddNewAddress),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsMiniSummary extends StatelessWidget {
  const _ProductsMiniSummary();

  @override
  Widget build(BuildContext context) {
    final items = context.watch<CartCubit>().state.items;
    return TintSurfaceCard(
      child: Column(
        children: [
          TintSectionHeader(title: 'ملخص المنتجات (${items.length})'),
          const SizedBox(height: 12),
          /// ‼️ **يتكيّف مع العدد — والشريط وحده كان ينهار عند منتجٍ واحد.**
          ///
          /// شريطُ صورٍ مصغّرة يعمل مع عشرة، أمّا مع واحدٍ فيترك بطاقةً شبه
          /// فارغة: صورةٌ يتيمة بلا اسمٍ ولا سعر، وفراغٌ يُقرأ عطلاً. وفي
          /// اللحظة التي يراجع فيها المشتري طلبه قبل الدفع، **الاسم والسعر
          /// أنفع من صورةٍ يعرفها**.
          ///
          /// والحدّ ثلاثة: فوقها تطول البطاقة وتزيح زرّ الدفع خارج الشاشة،
          /// فيعود الشريط — وهو الشكل الذي بُني له.
          if (items.length <= 3)
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TintNetworkImage(
                        url: item.product.image,
                        fit: BoxFit.cover,
                        width: 52,
                        height: 52,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الكميّة: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: TintColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.lineTotal.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: TintNetworkImage(
                        url: item.product.image,
                        fit: BoxFit.cover,
                        width: 58,
                        height: 74,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: const BoxDecoration(
                          color: TintColors.sand,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingMethodsCard extends StatelessWidget {
  const _ShippingMethodsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        return TintSurfaceCard(
          child: Column(
            children: [
              const TintSectionHeader(title: 'طريقة التوصيل'),
              const SizedBox(height: 12),
              // الطرق من الخادم لا من الشيفرة: كانت مثبَّتةً بأسعارٍ تخالف
              // إعدادات المتجر، فيرفض الخادم كلّ طلبٍ اختير فيه الخيار الأرخص.
              // ‼️ «تحقّق من اتّصالك وأعد المحاولة» أُزيلت: تُحمّل العميل عملاً
              //    نقوم به نحن — والمحاولة تجري تلقائيّاً.
              if (state.shippingMethods.isEmpty)
                const _QuietRetryNote()
              else
                /// ‼️ **صفٌّ لا قائمة** — بطلب المالك 2026-08-24.
                ///
                /// الطرق **قليلةٌ ومتقابلة** (أسرع/أرخص)، والقرار بينها مقارنة.
                /// وقائمةٌ رأسيّة تجعل المشتري يمرّر عينه بين سطرين متباعدين
                /// ليقارن رقمين، بينما الصفّ يضعهما جنباً إلى جنب فيُقرأ الفرق
                /// في نظرة.
                ///
                /// ‼️ **و`IntrinsicHeight` ليست زينة**: البطاقتان تتساويان
                /// ارتفاعاً مهما اختلف طول الاسم أو المدّة — وبطاقتان بارتفاعين
                /// تُقرآن «واحدةٌ أهمّ من الأخرى».
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < state.shippingMethods.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _ShippingOptionCard(
                            method: state.shippingMethods[i],
                            selected: state.shippingMethod ==
                                state.shippingMethods[i].id,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// بطاقة طريقة توصيلٍ واحدة داخل الصفّ.
class _ShippingOptionCard extends StatelessWidget {
  const _ShippingOptionCard({required this.method, required this.selected});

  final ShippingMethodModel method;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // «مجّاني» حين تتجاوز السلّة العتبة فعلاً — لا كوعدٍ ثابت.
    final subtotal = context.read<CartCubit>().state.total;
    final free = method.costFor(subtotal) == 0;

    return InkWell(
      onTap: () => context.read<CheckoutCubit>().setShippingMethod(method.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: selected ? TintColors.blush : Colors.white,
          border: Border.all(
            color: selected ? TintColors.sand : TintColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ‼️ **دائرةٌ ممتلئةٌ بصحٍّ عند الاختيار، وفارغةٌ عند غيره.**
            ///
            /// والفرق ليس تجميلاً: بطاقتان بلونين متقاربين تُقرآن «كلتاهما
            /// مختارة» على شاشةٍ في الشمس. والصحُّ يقول أيّهما بلا لبس.
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? TintColors.sand : const Color(0xFFCFD3D8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    free ? 'مجاني' : '${method.price.toStringAsFixed(0)} ر.س',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: free ? TintColors.success : TintColors.sand,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.etaLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TintColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// آبل باي — **الشريحة هي التأكيد**.
///
/// ‼️ **يُنادى بعد بصمة العميل لا قبلها**: الحزمة تفتح الشريحة، ولا يصل هذا
/// إلّا ومعه توكنٌ موقَّع. فلا زرَّ تأكيدٍ ثانياً بعده.
///
/// ‼️ **و`orderId` هو دليل النجاح** — لا رمز HTTP ولا ردٌّ بلا خطأ. فالخادم
/// لا يُصدر معرّف طلبٍ إلّا بعد أن يستعلم عن العمليّة من PayTabs ويجدها
/// مقبولة، وردٌّ ٢٠٠ بحالة «قيد المعالجة» ليس دفعاً.
Future<void> _payWithApplePay(
  BuildContext context,
  AddressModel address,
  String? buyerEmail,
  Map<String, dynamic> token,
  String sheetTotal,
) async {
  final cart = context.read<CartCubit>();
  final cubit = context.read<CheckoutCubit>();

  // ‼️ **نفس حرّاس الزرّ الرئيسيّ**: الشريحة لا تُعفي من مراجعة المخزون ولا
  //    من اكتمال العنوان — والدفع وقع فعلاً، فالطلب يجب أن يُنشأ.
  if (cart.state.items.isEmpty) {
    _showSnackBar(context, 'سلّتك فارغة — أضف منتجاً قبل إتمام الطلب.');
    return;
  }
  final a = address;
  if (a.recipient.isEmpty || a.mobile.isEmpty || a.city.isEmpty || a.details.isEmpty) {
    _showSnackBar(context, 'أكملي عنوان التوصيل قبل المتابعة.');
    return;
  }

  final orderReference = 'TN-AP-${DateTime.now().millisecondsSinceEpoch}';
  try {
    final result = await cubit.payWithApplePay(
      items: cart.state.items,
      address: address,
      orderReference: orderReference,
      applePayToken: token,
      sheetTotal: sheetTotal,
      buyerEmail: buyerEmail,
    );
    if (!context.mounted) return;

    final orderId = result['orderId']?.toString() ?? '';
    if (orderId.isEmpty) {
      _showSnackBar(
        context,
        result['message']?.toString() ?? 'لم تُقبل العمليّة عبر آبل باي.',
      );
      return;
    }
    _showSuccessDialog(context, orderId);
  } catch (error) {
    if (!context.mounted) return;

    /// ‼️ **لا يُعاد النداء هنا — تكرارُه خصمٌ ثانٍ.**
    ///
    /// `payWithApplePay` **يدفع** ولا يستعلم: التوكن أُنتج ببصمة المشتري قبل
    /// الوصول إلى هنا، فالشريحة أُكملت. والخطأ في هذا الموضع يعني أنّ الردّ
    /// ضاع لا أنّ الدفع رُفض — والحالة **مجهولة**.
    ///
    /// فلا رسالة خطأٍ عامّة تدعوه لمحاولةٍ أخرى: تُقال الحقيقة ويُعطى مرجعه.
    _showSnackBar(
      context,
      _unconfirmedPaymentMessage(
        paid: true,
        provider: 'آبل باي',
        reference: orderReference,
      ),
    );
  }
}

/// يسأل الخادم «هل تمّ الدفع؟» **بإصرارٍ لا مرّةً واحدة**.
///
/// ‼️ **هذه أخطر لحظةٍ في التطبيق كلّه: المال خرج، والجواب لم يصل بعد.** وكان
/// السؤال يُنادى مرّةً واحدة؛ فإن رمى (انقطاع شبكة — وهو **أكثر** ما يقع هنا،
/// إذ يخرج المشتري من التطبيق ويعود لحظة الدفع) سقط إلى `catch` الخارجيّ وظهر
/// له خطأٌ عامّ. فيقرأ «فشل الدفع» وقد **دُفع**، فيدفع مرّةً ثانية.
///
/// ‼️ **ويُعاد السؤال لا الدفع.** هذه نداءاتُ استعلامٍ عن عمليّةٍ قائمة (يسأل
/// خادمنا المزوّدَ عن مرجعٍ موجود)، فتكرارها لا يُنشئ شيئاً. أمّا نداء الدفع
/// نفسه فلا يُعاد أبداً — تكرارُه خصمٌ ثانٍ.
///
/// والانتظار متدرّج (0 · 2 · 4 · 6 ثوانٍ): المزوّد قد يتأخّر لحظاتٍ بين
/// «قُبِلت» و«رُحّلت»، والشبكة العائدة تحتاج نفَساً.
Future<T?> _askServerUntilAnswered<T>(
  BuildContext context,
  Future<T> Function() ask, {
  required bool Function(T) answered,
}) async {
  const gaps = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 6),
  ];

  /// ‼️ **ونافذةٌ تحجب الشاشة طوال السؤال.** بلا شيءٍ ظاهر يقف المشتري أمام
  /// شاشةٍ ساكنة اثنتَي عشرة ثانية بعد أن دفع — فيلمس «تأكيد الطلب والدفع»
  /// مرّةً أخرى. والحجب هنا **يمنع دفعةً ثانية** لا يُزيّن انتظاراً.
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'نتحقّق من دفعتك… لا تُغلق التطبيق',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    ),
  ));

  T? last;
  for (final gap in gaps) {
    if (gap > Duration.zero) await Future<void>.delayed(gap);
    try {
      final result = await ask();
      last = result;
      if (answered(result)) break;
    } catch (_) {
      // انقطاعٌ ليس حكماً على الدفع — تُعاد المحاولة.
    }
  }

  if (navigator.canPop()) navigator.pop();
  return last;
}

/// ما يُقال حين يُدفَع المال ولا يصل الجواب.
///
/// ‼️ **«لا تُعِد الدفع» في كلّ المسارات لا في واحد.** كانت هذه الجملة مكتوبةً
/// بعناية في مسار تمارا وحده، **وفي الفرع الخطأ منه**: تظهر إن ردّ الخادم بلا
/// رقم طلب، وتُتجاوَز إن لم يردّ أصلاً — وهي الحالة التي كُتبت لأجلها.
///
/// ‼️ **والمرجع يُذكر** ليُتابَع به: مشترٍ يقول «دفعتُ ولم يصلني طلب» بلا رقمٍ
/// يُتعب الدعم ويُطيل انتظاره.
String _unconfirmedPaymentMessage({
  required bool paid,
  required String provider,
  required String reference,
}) {
  if (!paid) return 'لم يكتمل الدفع عبر $provider. يمكنك المحاولة مجدداً.';
  return 'دفعتك مسجَّلة لدى $provider ونُتمّ تأكيد طلبك الآن — '
      'لا تُعِد الدفع، وستصلك رسالة التأكيد. مرجعك: $reference';
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// يُطلق `purchase` ثمّ يُعلم الخادم أنّ العميل رآه.
///
/// ‼️ **العلامة تُرسَل فقط إن خرج الحدث.** معناها حرفيّاً «رأى العميل هذا
/// الشراء فلا تستدركه»، فإرسالها بلا إطلاقٍ — لأنّ المستخدم رفض القياس
/// مثلاً — يمنع استدراك الخادم فيضيع الشراء من الطرفين معاً.
/// ينسب هذا الطلب إلى آخر مقطعٍ ترويجيّ نُقر زرّه — إن كان قريباً.
///
/// ‼️ **نافذة النسبة سبعة أيّام، وآخر نقرةٍ تأخذها.** أطولُ منها ينسب إلى
/// المقطع شراءً قرّره المشتري لسببٍ آخر، وأقصرُ منها يُسقط مشترياً عاد بعد
/// يومين وهو المعتاد في متجرٍ يُتصفَّح ليلاً ويُشترى منه نهاراً.
///
/// ‼️ **ولا يمرّ بمسار الطلب ولا بموافقة الإعلانات.** حقنُه في إنشاء الطلب
/// يعني لمس أخطر شيفرةٍ في النظام لأجل رقمٍ في تقرير؛ وربطُه بموافقة التتبّع
/// يُصفّر رقم متجرٍ لم يقبل زوّاره الإعلانات — وهذا عدّادٌ مجمّع بلا هويّة
/// أحد، لا تتبّعٌ عبر المواقع.
///
/// والثمن المُعلَن: الرقم يأتي من الجهاز، فيُقرأ **اتّجاهاً لا محاسبةً**.
Future<void> _attributeReelOrder(BuildContext context) async {
  final preferences = context.read<AppPreferences>();
  final reelId = preferences.lastReelClickId;
  if (reelId == null || reelId.isEmpty) return;

  const window = Duration(days: 7);
  final clickedAt = preferences.lastReelClickAt;
  final age = DateTime.now().millisecondsSinceEpoch - clickedAt;
  if (clickedAt <= 0 || age > window.inMilliseconds) {
    await preferences.clearReelClick();
    return;
  }

  final cubit = context.read<CheckoutCubit>();
  final subtotal = TrackingEvents.total(cubit.trackingItems);
  final value = subtotal +
      cubit.state.shippingCostFor(subtotal) +
      cubit.state.selectedFee;

  await context.read<ReelStatsReporter>().order(reelId, value);
  await preferences.clearReelClick();
}

Future<void> _logPurchase(BuildContext context, String orderId) async {
  final cubit = context.read<CheckoutCubit>();
  final items = cubit.trackingItems;
  if (items.isEmpty) return;

  final subtotal = TrackingEvents.total(items);
  final shipping = cubit.state.shippingCostFor(subtotal);
  final fired = await context.read<TrackingService>().logPurchase(
        transactionId: orderId,
        items: items,
        // ‼️ الإيراد كما دفعه المشتري: البضاعة + الشحن + رسوم الوسيلة.
        //    قيمةٌ بلا شحنٍ تُظهر ربحيّةً وهميّة في تقارير الإعلانات.
        value: subtotal + shipping + cubit.state.selectedFee,
        shipping: shipping,
      );
  if (!fired) return;

  try {
    await context.read<ApiClient>().postMap(
          ApiRoutes.conversionsBrowserPurchase,
          data: {'orderId': orderId},
        );
  } catch (error) {
    // فشل العلامة لا يُخبر المشتري بشيء: طلبه نجح، وأسوأ أثرٍ هنا استدراكٌ
    // مزدوج يعالجه الخادم بنفسه.
    debugPrint('[tracking] تعذّر تعليم الشراء: $error');
  }
}

Future<void> _showSuccessDialog(BuildContext context, String orderId) async {
  // ‼️ **هنا لا في كلّ مسار دفع.** خمسة مسارات تنتهي إلى هذه الدالّة (نقداً
  //    وتابي وتمارا وPayTabs ونون)، ووصلُ الحدث في كلٍّ منها يعني مساراً
  //    يُنسى — والمنسيّ لا يُصدر خطأً، يُصدر تقريراً ناقصاً يبدو صحيحاً.
  unawaited(_logPurchase(context, orderId));
  unawaited(_attributeReelOrder(context));

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تم استلام طلبك'),
      content: Text('رقم الطلب الجديد: $orderId'),
      actions: [
        TextButton(
          onPressed: () {
            context.read<CartCubit>().clear();
            Navigator.of(dialogContext).pop();
            context.go('/');
          },
          child: const Text('تم'),
        ),
      ],
    ),
  );
}

/// رسالة الخادم كما هي، لا غلافها.
///
/// `ApiException.toString()` يُخرج «ApiException(statusCode: 400, message: …)»
/// — فكان المشتري يقرأ اسم صنفٍ برمجيّ قبل سبب الرفض. والخادم يرسل رسالةً
/// عربيّةً مكتوبةً له، فتُعرَض وحدها.
String _readableError(Object error) {
  if (error is ApiException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({
    required this.address,
    required this.tabbyEmailController,
    required this.tabbyDobController,
    required this.selectedDob,
    required this.onSelectDob,
  });

  /// عنوان الطلب — يلزم آبل باي: الشريحة **هي** التأكيد، فلا مرحلة بعدها
  /// تقرأ العنوان.
  final AddressModel address;

  final TextEditingController tabbyEmailController;
  final TextEditingController tabbyDobController;
  final DateTime? selectedDob;
  final VoidCallback onSelectDob;

  /// ‼️ **شعارٌ رسميّ بدل نصٍّ ملوّن** (بلاغ المالك 2026-08-12): كان
  /// التطبيق يكتب «tabby» و«tamara» نصّاً، بينما يعرض المتجر شعاراتها. والعميل
  /// يعرف العلامة بشكلها لا باسمها المكتوب — وهو ما يصنع الثقة لحظة الدفع.
  static String _markKey(String id) => switch (id) {
        'cod' => 'cod',
        'tabby' => 'tabby',
        'tamara' => 'tamara',
        'bank' => 'bank',
        _ => id,
      };

  /// وسيلة تابي كما وصفها الخادم — مصدر اعتماداتها العامّة.
  PaymentMethodModel? _tabbyMethod(CheckoutState state) {
    for (final m in state.methods) {
      if (m.id == 'tabby') return m;
    }
    return null;
  }

  /// خانة «الدفع عند الاستلام» — **تملأ ما بقي من الصفّ الأخير.**
  ///
  /// موضعها وعرضها بطلب المالك (2026-08-24) بعد أن رأى الشبكة على جهازه، وهو
  /// الصواب لسببين:
  ///
  /// · **ليست علامةً تجاريّة** تُعرَف بشكلها كتابي ومدى — بل طريقةُ تسليمٍ
  ///   **تُقرأ بالكلمة**، وخانةٌ بعرض الشعار تقُصّ اسمها.
  /// · **وهي الوحيدة التي تحمل رسماً** (15 ﷼)، ورقمٌ يغيّر الإجماليّ يُقرأ
  ///   قبل الاختيار لا بعده.
  ///
  /// ‼️ **وإن غابت من ردّ الخادم فلا خانة ولا فراغ**: الشبكة تتوزّع على ما
  /// بقي، لأنّ تعطيل الدفع عند الاستلام قرارٌ إداريّ وارد.
  Widget? _codTile(BuildContext context, CheckoutState state) {
    for (final m in state.methods) {
      if (m.id != 'cod') continue;
      return _PayWideTile(
        selected: state.paymentMethod == m.id,
        title: m.label,
        // ‼️ **«رسوم 15» لا «+15»**: علامة الزائد في سياقٍ عربيّ تُرسم
        // يمين الرقم («15+») فتُقرأ خطأً مطبعيّاً — رُصد في لقطة المحاكي
        // 2026-08-24. والخانة العريضة تتّسع للكلمة الصريحة (بخلاف الخانات الضيّقة).
        note: m.hasFee
            ? 'رسوم ${m.fee.toStringAsFixed(m.fee % 1 == 0 ? 0 : 2)} ﷼'
            : null,
        onTap: () => context.read<CheckoutCubit>().setPaymentMethod(m.id),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.read<AppConfig>();
    final cartState = context.watch<CartCubit>().state;

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        return TintSurfaceCard(
          child: Column(
            children: [
              const TintSectionHeader(title: 'طريقة الدفع'),
              const SizedBox(height: 12),
              if (state.methodsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              /// ‼️ **الفراغ لا يُقال إلّا إذا قاله الخادم.**
              ///
              /// كانت الرسالة الحمراء تظهر عند انقطاع الشبكة أيضاً، فتتّهم
              /// المتجرَ بعطلٍ سببُه اتّصال العميل — في آخر خطوةٍ قبل الدفع.
              /// والآن: انقطاعٌ ⇒ سطرٌ محايد والمحاولة تجري وحدها؛ وردٌّ ناجح
              /// بقائمةٍ فارغة ⇒ الرسالة الحمراء، وهي حينئذٍ صادقة.
              else if (state.methods.isEmpty && state.catalogOffline)
                const _QuietRetryNote()
              else if (state.methods.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'لا توجد وسيلة دفع متاحة حالياً. يُرجى التواصل مع الدعم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: TintColors.danger, fontWeight: FontWeight.w700),
                  ),
                )
              else ...[
                /// ‼️ **شبكةٌ لا قائمة — بطلب المالك بعد نموذجٍ قارنه.**
                ///
                /// القسم كان أطول ما في الشاشة (~٣٤٠ بكسل)، **ويطول ستّين
                /// بكسلاً مع كلّ وسيلةٍ تُضاف** — والقائمة تنمو (مدفوع · إمكان
                /// · STC · تحويل بنكيّ). والشبكة تستوعب الجديد **بلا زيادة
                /// ارتفاع**، لأنّ الخانة تملأ فراغاً قائماً.
                ///
                /// ‼️ **وشعاراتٌ بلا جُمَل**: المشتري السعوديّ يعرف «تابي»
                /// و«تمارا» و«مدى» **بشكلها**، والوصف تحتها يُطيل ولا يُضيف.
                /// والوصف يبقى للدفع عند الاستلام وحده — فهو الوحيد الذي يحمل
                /// رسماً يجب أن يُقرأ قبل الاختيار.
                ///
                /// ‼️ **وثلاثةٌ في الصفّ لا أربعة**: أربعةٌ تُصغّر الشعار حتّى
                /// يُقرأ بالتخمين على شاشةٍ في الشمس.
                _PayGrid(
                  chips: [
                    for (final m in state.methods)
                      if (m.id == 'paytabs') ...[
                        /**
                         * ‼️ **البطاقة تُعرَض خانتين: «مدى» و«فيزا».**
                         *
                         * المزوّد واحد (PayTabs) والمعرّف المُرسَل إلى الخادم
                         * واحد — والفرق **عرضٌ لا سلوك**. والسبب أنّ المشتري
                         * السعوديّ يبحث عن شعار «مدى» بعينه، وخانةٌ واحدة
                         * تجعله يظنّ أنّ بطاقته غير مقبولة.
                         */
                        _PayChip(
                          selected: state.paymentMethod == m.id &&
                              state.cardBrand == 'mada',
                          markKeys: const ['mada'],
                          onTap: () => context
                              .read<CheckoutCubit>()
                              .setPaymentMethod(m.id, cardBrand: 'mada'),
                        ),
                        _PayChip(
                          selected: state.paymentMethod == m.id &&
                              state.cardBrand == 'visa',
                          markKeys: const ['visa', 'mastercard'],
                          onTap: () => context
                              .read<CheckoutCubit>()
                              .setPaymentMethod(m.id, cardBrand: 'visa'),
                        ),
                      ] else if (m.id != 'cod')
                        _PayChip(
                          selected: state.paymentMethod == m.id,
                          markKeys: [_markKey(m.id)],
                          label: m.label,
                          note: m.hasFee
                              ? '+${m.fee.toStringAsFixed(m.fee % 1 == 0 ? 0 : 2)} ﷼'
                              : null,
                          onTap: () => context
                              .read<CheckoutCubit>()
                              .setPaymentMethod(m.id),
                        ),

                    /// ‼️ **تُدرَج بعد سؤالٍ لا قبله** — وإلّا حجزت خانةً فارغة
                    /// على أندرويد. وتبقى **زرّاً لا خياراً يُؤشَّر**: الشريحة
                    /// نفسها هي التأكيد، فلا حدَّ ملوّناً حولها.
                    if (ApplePaySection.isAvailable(
                        state.applePay, cartState.total + state.selectedFee))
                      ApplePaySection(
                        config: state.applePay,
                        amount: cartState.total + state.selectedFee,
                        label: state.applePay.displayName,
                        enabled: !state.isSubmitting,
                        compact: true,
                        onToken: (token, sheetTotal) => _payWithApplePay(
                          context,
                          address,
                          tabbyEmailController.text.trim().isEmpty
                              ? null
                              : tabbyEmailController.text.trim(),
                          token,
                          sheetTotal,
                        ),
                      ),
                  ],
                  wide: _codTile(context, state),
                ),

                // كتلة Tabby الخاصّة (العرض + بيانات المشتري) عند اختياره فقط.
                if (state.paymentMethod == 'tabby') ...[
                  const SizedBox(height: 12),
                  /// ‼️ **الحارس القديم `hasTabbyConfig` أُزيل** — كان يقرأ
                  /// متغيّرات بناءٍ غائبة في Codemagic، فيُخفي العرض كلّه: يختار
                  /// العميل تابي فلا يرى كم يدفع كلّ شهر، وهو سببُ اختياره.
                  ///
                  /// والودجة تتدرّج بنفسها: باعتماداتٍ صحيحة تعرض جدول تابي
                  /// الرسميّ، وبدونها سطراً نصّيّاً — وكلاهما أنفع من الفراغ.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: buildTabbyPromoSnippet(
                      price: cartState.total.toStringAsFixed(2),
                      currencyCode: appConfig.currencyCode,
                      langCode: appConfig.tabbyLanguage,
                      merchantCode: _tabbyMethod(state)?.merchantCode,
                      apiKey: _tabbyMethod(state)?.publicKey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TabbyBuyerCard(
                    emailController: tabbyEmailController,
                    dobController: tabbyDobController,
                    selectedDob: selectedDob,
                    onSelectDob: onSelectDob,
                  ),
                ],

              ],

            ],
          ),
        );
      },
    );
  }
}

class _CheckoutTotalCard extends StatefulWidget {
  const _CheckoutTotalCard({
    required this.address,
    required this.tabbyEmailController,
    required this.tabbyDobController,
  });

  final AddressModel address;
  final TextEditingController tabbyEmailController;
  final TextEditingController tabbyDobController;

  @override
  State<_CheckoutTotalCard> createState() => _CheckoutTotalCardState();
}

class _CheckoutTotalCardState extends State<_CheckoutTotalCard> {
  Future<void> _submit(BuildContext context, CheckoutState state) async {
    final cart = context.read<CartCubit>();
    final cartState = cart.state;
    if (cartState.items.isEmpty) {
      _showSnackBar(context, 'سلّتك فارغة — أضف منتجاً قبل إتمام الطلب.');
      return;
    }

    // ‼️ مراجعةٌ لحظةَ الضغط لا عند فتح الشاشة: المخزون يتغيّر بينهما، وكلّ
    // ثانيةٍ هنا أرخص من تصريحٍ ماليّ يُلغى بعده.
    await cart.revalidateStock();
    if (!context.mounted) return;
    final blocked = cart.state.unavailable;
    if (blocked.isNotEmpty) {
      // تُذكر كلّ الأصناف دفعةً واحدة: يصحّح المشتري سلّته مرّةً لا مرّةً لكلّ صنف.
      final names = blocked.map((item) => '«${item.product.title}»').join('، ');
      _showSnackBar(context, 'تعذّر إتمام الطلب: $names لم تعد متاحة. أزِلها من السلّة.');
      return;
    }

    // تحقّق من اكتمال بيانات الشحن المطلوبة قبل الإرسال.
    final a = widget.address;
    if (a.recipient.isEmpty ||
        a.mobile.isEmpty ||
        a.city.isEmpty ||
        a.details.isEmpty) {
      // ‼️ **صياغةٌ تصلح للمسارين**: «المميّزة بـ*» كانت تشير إلى نجومٍ في
      //    نموذج الزائر، ولا وجود لها في بطاقة العميل المسجَّل — فيقرأ رسالةً
      //    تُحيله إلى ما لا يراه.
      _showSnackBar(context, 'أكملي عنوان التوصيل قبل المتابعة.');
      return;
    }

    if (state.paymentMethod == 'tabby') {
      await _handleTabbyPayment(context, state);
      return;
    }

    if (state.paymentMethod == 'tamara') {
      await _handleTamaraPayment(context);
      return;
    }

    if (state.paymentMethod == 'paytabs') {
      await _handlePayTabsPayment(context);
      return;
    }

    if (state.paymentMethod == 'noon') {
      await _handleNoonPayment(context);
      return;
    }

    try {
      await context.read<CheckoutCubit>().submitOrder(
            items: cartState.items,
            address: widget.address,
          );
    } catch (_) {
      // الرسالة يعرضها المستمع من `errorMessage`. المُلتقِط هنا يمنع الاستثناء
      // من الهروب إلى `onPressed` حيث يبتلعه الإطار بصمت.
    }
  }

  /// يستخرج رسالة الخادم العربيّة من نصّ الاستثناء الخام.
  ///
  /// `ApiException.toString()` قد يسبقها بنوع الاستثناء ورمز الحالة، وعرض ذلك
  /// على المتسوّق يُخفي السبب الحقيقيّ خلف ضجيجٍ تقنيّ.
  String _friendlyError(String raw) {
    final cleaned = raw
        .replaceFirst(RegExp(r'^[A-Za-z_]*Exception:?\s*'), '')
        .replaceFirst(RegExp(r'^\[\d{3}\]\s*'), '')
        .trim();
    if (cleaned.isEmpty) {
      return 'تعذّر إنشاء الطلب. حاول مجدداً أو تواصل معنا.';
    }
    return cleaned;
  }

  // حالة «لم تُحسم بعد» من الخادم: العمليّة أُنشئت ولم تُؤكَّد ولم تفشل.
  bool _isPending(Map<String, dynamic> res) {
    if (res['ok'] == true) return false;
    final status = res['status']?.toString().toUpperCase();
    return status == 'INITIATED' || status == 'PENDING';
  }

  // تدفّق نون: إنشاء الطلب → فتح الدفع المستضاف في webview → التحقّق من الخادم.
  Future<void> _handleNoonPayment(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    final cart = context.read<CartCubit>();
    try {
      final init = await cubit.initiateNoon(
        items: cart.state.items,
        address: widget.address,
        buyerEmail: widget.tabbyEmailController.text.trim().isNotEmpty
            ? widget.tabbyEmailController.text.trim()
            : null,
      );
      final url = init['checkoutUrl']?.toString();
      final noonId = init['noonOrderId']?.toString();
      if (url == null || url.isEmpty || noonId == null) {
        if (context.mounted) {
          _showSnackBar(context, 'تعذّر بدء الدفع عبر نون. حاول مجدداً.');
        }
        return;
      }
      if (!context.mounted) return;
      // فتح نافذة نون؛ ترجع true عند بلوغ رابط العودة، false عند الإلغاء.
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => NoonWebviewPage(checkoutUrl: url)),
      );
      if (done != true) {
        if (context.mounted) _showSnackBar(context, 'أُلغي الدفع.');
        return;
      }
      // التحقّق النهائيّ من الخادم (يسأل نون مباشرةً).
      // ‼️ INITIATED ليست فشلاً — العمليّة لم تُحسم بعد وقد يُسوّيها webhook نون
      // خلال ثوانٍ. نُعيد المحاولة بتباعد متزايد قبل إعلان أيّ نتيجة سلبيّة.
      Map<String, dynamic> res = await cubit.verifyNoon(noonId);
      for (var attempt = 0; attempt < 3 && _isPending(res); attempt++) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        res = await cubit.verifyNoon(noonId);
      }
      final status = res['status']?.toString().toUpperCase();
      final ok = res['ok'] == true ||
          status == 'PAID' ||
          status == 'CAPTURED' ||
          status == 'AUTHORIZED';
      if (!context.mounted) return;
      if (ok) {
        cart.clear();
        await _showSuccessDialog(context, res['orderId']?.toString() ?? noonId);
      } else if (_isPending(res)) {
        // ما زالت معلّقة بعد المحاولات: لا نُعلن فشلاً ولا نُفرغ السلّة.
        _showSnackBar(
          context,
          'لم تُحسم عمليّة الدفع بعد. سنؤكّد طلبك تلقائيّاً عند اكتمالها — تابع طلباتك.',
        );
      } else {
        _showSnackBar(context, 'لم يكتمل الدفع. لم يُخصم أيّ مبلغ.');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(
            context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  /// المبلغ كما يراه المشتري في ملخّص الطلب — بنيةٌ واحدة لا نسخةٌ لكلّ مزوّد.
  ///
  /// ‼️ **هو الإجماليّ النهائيّ نفسه** (سلّة + رسم الوسيلة) لا مجموع السلّة
  /// وحده: رقمٌ في الورقة يخالف الرقم في الشاشة تحتها يهدم الثقة التي فُتحت
  /// الورقة لأجلها.
  String _amountLabel(double total) => '${total.toStringAsFixed(2)} ﷼';


  /// PayTabs — بطاقة.
  ///
  /// ‼️ تختلف عن تابي وتمارا في العودة: PayTabs تُرسل **POST بنموذج** إلى
  /// خادمنا، وهو يتحقّق من التوقيع ثمّ **يُحوّل بـ303** إلى صفحة النتيجة.
  /// فالشاشة تراقب **صفحة النتيجة** (`/checkout/paytabs/result`) لا عنوان
  /// عودةٍ مباشر — ولو راقبت عنوان العودة لالتقطت نقطة POST التي لا يصلها
  /// المتصفّح بـGET أصلاً.
  Future<void> _handlePayTabsPayment(BuildContext context) async {
    final cart = context.read<CartCubit>();
    final cartState = cart.state;
    final cubit = context.read<CheckoutCubit>();
    final orderReference = 'TN-PT-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final session = await cubit.createPayTabsSession(
        items: cartState.items,
        address: widget.address,
        orderReference: orderReference,
        buyerEmail: widget.tabbyEmailController.text.trim().isEmpty
            ? null
            : widget.tabbyEmailController.text.trim(),
      );

      final cartId = session['cartId']?.toString() ?? '';
      final tranRef = session['tranRef']?.toString();
      final redirectUrl = session['redirectUrl']?.toString() ?? '';
      if (cartId.isEmpty || redirectUrl.isEmpty) {
        if (!mounted) return;
        _showSnackBar(context, 'تعذّر فتح صفحة الدفع بالبطاقة. حاولي مجدداً.');
        return;
      }

      /// ‼️ صفحة النتيجة تأتي **من الخادم** (`resultPageUrl`)، ولا تُشتقّ هنا.
      ///
      /// كانت تُبنى من `AppConfig.origin` — وهو نطاق **الـAPI**، بينما صفحة
      /// النتيجة على نطاق **المتجر**. فكانت الشاشة تراقب عنواناً لا يُزار
      /// أبداً: يدفع المشتري، ويُحوّله الخادم إلى المتجر، وتبقى الشاشة واقفة
      /// إلى الأبد. وهو عين عطل تابي في «سنعيدك الآن».
      ///
      /// والاحتياط أدناه للتوافق مع خادمٍ أقدم لم يُرسل الحقل بعد.
      final resultUrl = (session['resultPageUrl']?.toString().trim().isNotEmpty ?? false)
          ? session['resultPageUrl'].toString().trim()
          : '${context.read<AppConfig>().origin}/checkout/paytabs/result';

      if (!mounted) return;
      final outcome = await PaymentWebviewPage.present(
        context,
        title: 'الدفع بالبطاقة',
        secureLabel: 'دفعٌ آمن عبر PayTabs',
        amountLabel: _amountLabel(cartState.total + cubit.state.selectedFee),
        checkoutUrl: redirectUrl,
        // النجاح والفشل يمرّان بنفس الصفحة، والخادم هو من يفصل — فنُغلق
        // عندها ثمّ نسأل.
        successUrl: resultUrl,
        cancelUrl: '',
        failureUrl: '',
      );

      if (!mounted) return;
      if (outcome == PaymentWebviewOutcome.cancelled) {
        _showSnackBar(context, 'أُلغي الدفع.');
        return;
      }

      // ‼️ يُسأل الخادم في كلّ الحالات — حتّى الإغلاق اليدويّ — وبإصرار.
      final result = await _askServerUntilAnswered<Map<String, dynamic>>(
        context,
        () => cubit.confirmPayTabsPayment(cartId, tranRef: tranRef),
        answered: (r) => (r['orderId']?.toString() ?? '').isNotEmpty,
      );
      if (!mounted) return;

      final createdId = result?['orderId']?.toString() ?? '';
      if (createdId.isEmpty) {
        _showSnackBar(
          context,
          // رسالةُ الخادم أدقّ حين يردّ (رفضُ بنكٍ مثلاً)؛ وحين لا يردّ أصلاً
          // تُقال جملة «لا تُعِد الدفع».
          result?['message']?.toString() ??
              _unconfirmedPaymentMessage(
                paid: outcome == PaymentWebviewOutcome.success,
                provider: 'مزوّد البطاقة',
                reference: orderReference,
              ),
        );
        return;
      }
      _showSuccessDialog(context, createdId);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, _readableError(error));
    }
  }

  /// تمارا — نفس هيكل تابي بعد إصلاحه: جلسةٌ من الخادم، وشاشةٌ تراقب الرابط،
  /// وسؤال الخادم عن النتيجة **حتّى عند الإغلاق اليدويّ**.
  ///
  /// ولا تحتاج بريداً ولا تاريخ ميلاد كتابي: تمارا تجمعهما في صفحتها.
  Future<void> _handleTamaraPayment(BuildContext context) async {
    final cart = context.read<CartCubit>();
    final cartState = cart.state;
    final cubit = context.read<CheckoutCubit>();
    final orderReference = 'TN-TAMARA-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final session = await cubit.createTamaraSession(
        items: cartState.items,
        address: widget.address,
        orderReference: orderReference,
        buyerEmail: widget.tabbyEmailController.text.trim().isEmpty
            ? null
            : widget.tabbyEmailController.text.trim(),
      );

      final orderId = session['orderId']?.toString() ?? '';
      final checkoutUrl = session['checkoutUrl']?.toString() ?? '';
      final returnUrls = (session['returnUrls'] as Map?) ?? const {};

      if (orderId.isEmpty || checkoutUrl.isEmpty) {
        if (!mounted) return;
        _showSnackBar(context, 'تعذّر فتح صفحة تمارا. حاولي مجدداً.');
        return;
      }

      if (!mounted) return;
      final outcome = await PaymentWebviewPage.present(
        context,
        title: 'الدفع عبر تمارا',
        secureLabel: 'دفعٌ آمن عبر تمارا',
        amountLabel: _amountLabel(cartState.total + cubit.state.selectedFee),
        checkoutUrl: checkoutUrl,
        successUrl: returnUrls['success']?.toString() ?? '',
        cancelUrl: returnUrls['cancel']?.toString() ?? '',
        failureUrl: returnUrls['failure']?.toString() ?? '',
      );

      if (!mounted) return;
      if (outcome == PaymentWebviewOutcome.cancelled) {
        _showSnackBar(context, 'أُلغي الدفع عبر تمارا.');
        return;
      }

      /// ‼️ لا نجاح بلا رقم طلبٍ من الخادم.
      ///
      /// كان يُعرَض نجاحٌ بـ`orderReference` — وهو رقمٌ **ولّدَه الجهاز** ولا
      /// وجود له في النظام. فيخرج المشتري مطمئنّاً إلى طلبٍ لا يعرفه أحد.
      ///
      /// وتمارا قد تتأخّر لحظاتٍ بين `approved` و`authorised` — والسؤال المُصرّ
      /// يستوعب التأخّر والانقطاع معاً (كان يستوعب الأوّل وحده).
      final result = await _askServerUntilAnswered<Map<String, dynamic>>(
        context,
        () => cubit.confirmTamaraPayment(orderId),
        answered: (r) => (r['orderId']?.toString() ?? '').isNotEmpty,
      );
      if (!mounted) return;

      final createdId = result?['orderId']?.toString() ?? '';
      if (createdId.isEmpty) {
        _showSnackBar(
          context,
          _unconfirmedPaymentMessage(
            paid: outcome == PaymentWebviewOutcome.success,
            provider: 'تمارا',
            reference: orderReference,
          ),
        );
        return;
      }
      _showSuccessDialog(context, createdId);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, _readableError(error));
    }
  }

  Future<void> _handleTabbyPayment(
    BuildContext context,
    CheckoutState state,
  ) async {
    final buyerEmail = widget.tabbyEmailController.text.trim();
    final buyerDob = widget.tabbyDobController.text.trim();

    if (buyerEmail.isEmpty || !buyerEmail.contains('@')) {
      _showSnackBar(context, 'يرجى إدخال بريد إلكتروني صحيح لإتمام الدفع مع Tabby.');
      return;
    }
    if (buyerDob.isEmpty) {
      _showSnackBar(context, 'يرجى تحديد تاريخ الميلاد المطلوب من Tabby.');
      return;
    }

    final cartState = context.read<CartCubit>().state;
    final orderReference = 'TN-TABBY-${DateTime.now().millisecondsSinceEpoch}';
    final cubit = context.read<CheckoutCubit>();

    try {
      /**
       * ‼️ الجلسة يُنشئها **الخادم** لا حزمة تابي على الجهاز.
       *
       * حمولة الحزمة لا تحمل `merchant_urls` إطلاقاً، فكانت تابي تُنهي الدفع
       * وتقول «سنعيدك الآن» ثمّ لا تجد عنواناً تعود إليه — فتقف الشاشة إلى
       * الأبد بينما المال مُصرَّحٌ به عندها ولا طلب عندنا. وخادمنا يرسلها كما
       * يفعل في الموقع الذي أثبت نجاحه.
       *
       * ويكسب المسار بذلك التسعير الموثوق وفحص المخزون **قبل** أن يرى المشتري
       * تابي، ويبقى مفتاح تابي على الخادم لا على الجهاز.
       */
      final session = await cubit.createTabbySession(
        items: cartState.items,
        address: widget.address,
        orderReference: orderReference,
        buyerEmail: buyerEmail,
        buyerDob: buyerDob,
      );

      final paymentId = session['paymentId']?.toString() ?? '';
      final sessionId = session['sessionId']?.toString();
      final checkoutUrl = session['webUrl']?.toString() ?? '';
      final returnUrls = (session['returnUrls'] as Map?) ?? const {};

      if (session['status']?.toString() == 'rejected') {
        if (!mounted) return;
        _showSnackBar(
          context,
          session['rejectionReason']?.toString() ??
              'نأسف، تابي غير قادرة على الموافقة على هذه العملية. جرّبي وسيلة دفعٍ أخرى.',
        );
        return;
      }
      if (paymentId.isEmpty || checkoutUrl.isEmpty) {
        if (!mounted) return;
        _showSnackBar(context, 'تعذّر فتح صفحة تابي. حاولي مجدداً.');
        return;
      }

      if (!mounted) return;
      final outcome = await PaymentWebviewPage.present(
        context,
        title: 'الدفع عبر Tabby',
        secureLabel: 'دفعٌ آمن عبر Tabby',
        amountLabel: _amountLabel(cartState.total + state.selectedFee),
        jsBridgeName: 'tabbyMobileSDK',
        checkoutUrl: checkoutUrl,
        successUrl: returnUrls['success']?.toString() ?? '',
        cancelUrl: returnUrls['cancel']?.toString() ?? '',
        failureUrl: returnUrls['failure']?.toString() ?? '',
      );

      if (!mounted) return;

      if (outcome == PaymentWebviewOutcome.cancelled) {
        _showSnackBar(context, 'أُلغي الدفع عبر Tabby.');
        return;
      }

      /**
       * ‼️ يُسأل الخادم في حالتَي النجاح **والإغلاق اليدويّ**.
       *
       * الخروج من الشاشة ليس حكماً على الدفع: قد يُتمّه المشتري ثمّ يُغلق قبل
       * أن يقع التحويل. والخادم يسأل تابي مباشرةً فيعرف الحقيقة. وكانت الشيفرة
       * السابقة تكتفي برسالة «سيصل التأكيد من الخادم» — ولا يصل، لأنّ الـwebhook
       * غير مضبوط.
       */
      final confirmation = await _askServerUntilAnswered<TabbyConfirmationResult>(
        context,
        () => cubit.confirmTabbyPayment(
          paymentId: paymentId,
          sessionId: sessionId,
          orderReference: orderReference,
          items: cartState.items,
          address: widget.address,
          buyerEmail: buyerEmail,
          buyerDob: buyerDob,
        ),
        answered: (r) => r.orderId.isNotEmpty,
      );
      if (!mounted) return;

      final createdId = confirmation?.orderId ?? '';
      if (createdId.isEmpty) {
        /// ‼️ **ولا يُعرَض نجاحٌ بمرجعٍ ولّده الجهاز.**
        ///
        /// كان يُعرَض `orderReference` رقمَ طلبٍ عند النجاح بلا تأكيد — وهو
        /// رقمٌ لا يعرفه النظام، فيخرج المشتري مطمئنّاً إلى طلبٍ لا وجود له.
        /// وهو نفس الخطأ الذي أُصلح في تمارا وبقي هنا.
        _showSnackBar(
          context,
          _unconfirmedPaymentMessage(
            paid: outcome == PaymentWebviewOutcome.success,
            provider: 'تابي',
            reference: orderReference,
          ),
        );
        return;
      }
      _showSuccessDialog(context, createdId);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, _readableError(error));
    }
  }






  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.paymentMethod != 'tabby' && state.lastOrderId != null) {
          _showSuccessDialog(context, state.lastOrderId!);
        }
        // سبب الرفض كان يُحفظ في الحالة ولا يُعرض قطّ، فيبدو الزرّ كأنّه لا
        // يعمل بينما الخادم يشرح سببه بالعربيّة (مخزون، سعر، وسيلة دفع…).
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          _showSnackBar(context, _friendlyError(state.errorMessage!));
        }
      },
      builder: (context, state) {
        final fee = state.selectedFee;
        final grandTotal = cartState.total + fee;
        return TintSurfaceCard(
          child: Column(
            children: [
              // سطر رسوم الدفع عند الاستلام (يظهر فقط عند وجود رسوم).
              if (fee > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رسوم الدفع عند الاستلام',
                      style: TextStyle(
                          color: TintColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${fee.toStringAsFixed(fee % 1 == 0 ? 0 : 2)} ﷼',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const Divider(height: 20),
              ],
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإجمالي النهائي',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'شامل ضريبة القيمة المضافة والشحن',
                          style: TextStyle(
                            color: TintColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${grandTotal.toStringAsFixed(2)} ﷼',
                    style: const TextStyle(
                      color: TintColors.sand,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TintPrimaryButton(
                label: state.isSubmitting
                    ? (state.paymentMethod == 'tabby'
                        ? 'جاري تأكيد دفعة Tabby...'
                        : 'جاري تأكيد الطلب...')
                    : (state.paymentMethod == 'tabby'
                        ? 'أكملي الدفع مع Tabby'
                        : 'تأكيد الطلب والدفع'),
                expanded: true,
                backgroundColor: TintColors.sand,
                onPressed: state.isSubmitting ? null : () => _submit(context, state),
                icon: Icon(
                  state.paymentMethod == 'tabby'
                      ? Icons.account_balance_wallet_outlined
                      : Icons.verified_user_outlined,
                ),
              ),
              if (state.paymentMethod == 'tabby') ...[
                const SizedBox(height: 10),
                const Text(
                  'لن تتم معالجة الدفع داخل Odoo. يتم التفويض والالتقاط عبر Tabby ثم يُرسل الطلب المؤكد فقط إلى الخادم الوسيط وبعدها إلى Odoo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TintColors.textMuted,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'بالضغط على "تأكيد الطلب والدفع" فأنت توافق على الشروط والأحكام.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TintColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// سطرٌ محايد حين يتعذّر الوصول إلى الخادم — **بلا زرّ وبلا لوم**.
///
/// ‼️ **لا زرّ «إعادة المحاولة»** (قرار المالك 2026-08-25: «لم أرَ وسائل دفع
/// عليها زرّ إعادة المحاولة»): الزرّ اعترافٌ بالعجز يُحوّل عملنا إلى مهمّةٍ
/// على العميل، ولا يفعل شيئاً لا يفعله التطبيق وحده. والمحاولة تجري صامتةً
/// كلّ عشر ثوانٍ، وعند عودة التطبيق للمقدّمة.
///
/// ‼️ **ونبرةٌ محايدة لا حمراء**: الأحمر يعني «عطلٌ عندنا»، وهذا ليس عطلاً —
/// بل انتظارٌ سيمرّ. ولون التحذير في شاشة دفعٍ يُخيف المشتري فيغادر.
class _QuietRetryNote extends StatelessWidget {
  const _QuietRetryNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TintColors.textMuted,
            ),
          ),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'جارٍ التحديث… الاتّصال ضعيف حالياً',
              style: TextStyle(
                color: TintColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شبكة وسائل الدفع: خاناتٌ متساوية، **وخانةٌ أخيرة تبتلع ما بقي من الصفّ**.
///
/// ‼️ **`GridView` لا تصلح هنا** وإن بدت الأقرب: خاناتها متساوية بالتعريف،
/// فمتى لم يكن عدد الوسائل من مضاعفات الثلاثة **بقي فراغٌ في آخر صفّ** — وهو
/// ما رآه المالك على جهازه (2026-08-24) وطلب سدّه. ولا تدعم امتداد خانةٍ على
/// عمودين إلّا بحزمةٍ خارجيّة، وحزمةٌ من أجل صفٍّ واحد ثمنٌ لا يُدفَع.
///
/// فتُحسَب الخانة من العرض المتاح — **بنفس نسبة `GridView` السابقة (1.9)**
/// حتّى لا يتغيّر شكل ما لم يُطلب تغييره — ثمّ تُبنى الصفوف يدويّاً.
///
/// ‼️ **والفراغ الباقي يذهب إلى `wide` لا إلى الشعارات**: توسيع خانة «تابي»
/// يمطّ شعاراً لصاحبه شروطُ عرضٍ مكتوبة، بينما «الدفع عند الاستلام» **يستفيد**
/// من العرض لأنّه يُقرأ بالكلمة.
class _PayGrid extends StatelessWidget {
  const _PayGrid({required this.chips, this.wide});

  /// الوسائل التي تُعرَف بشعاراتها — خانةٌ لكلٍّ منها بعرضٍ واحد.
  final List<Widget> chips;

  /// خانةُ الذيل: تُلحَق بالصفّ الأخير وتأخذ أعمدته الفارغة كلّها. وإن امتلأ
  /// الصفّ الأخير نزلت صفّاً كاملاً بعرض الشبكة. و`null` = لا خانة أصلاً.
  final Widget? wide;

  static const int _columns = 3;
  static const double _gap = 8;

  /// نسبة الخانة (عرض ÷ ارتفاع) — منقولةٌ حرفيّاً من `GridView` التي سبقتها.
  static const double _ratio = 1.9;

  @override
  Widget build(BuildContext context) {
    final tail = wide;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        final height = cell / _ratio;

        // قسّم الخانات صفوفاً من ثلاث.
        final chunks = <List<Widget>>[];
        for (var i = 0; i < chips.length; i += _columns) {
          final end = i + _columns > chips.length ? chips.length : i + _columns;
          chunks.add(chips.sublist(i, end));
        }

        final free = chunks.isEmpty ? _columns : _columns - chunks.last.length;

        final rows = <Widget>[];
        for (var r = 0; r < chunks.length; r++) {
          final isLast = r == chunks.length - 1;
          rows.add(_buildRow(
            chunks[r],
            cell,
            height,
            tail: isLast && tail != null && free > 0 ? tail : null,
            span: free,
          ));
        }

        // صفّ الأخير ممتلئ (أو لا خانات) ⇒ الذيل يأخذ صفّاً بعرض الشبكة.
        if (tail != null && free == 0) {
          rows.add(_buildRow(const [], cell, height, tail: tail, span: _columns));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }

  /// ‼️ **`Row` بعروضٍ محسوبة لا `Expanded`**: الأعمدة يجب أن تتطابق بين
  /// الصفوف مهما اختلف عدد خانات الصفّ — و`Expanded` يوزّع عرض صفّه وحده،
  /// فيخرج صفٌّ من خانتين بخانتين عريضتين لا تحاذيان ما فوقهما.
  Widget _buildRow(
    List<Widget> items,
    double cell,
    double height, {
    Widget? tail,
    int span = 0,
  }) {
    final children = <Widget>[];
    for (final item in items) {
      if (children.isNotEmpty) children.add(const SizedBox(width: _gap));
      children.add(SizedBox(width: cell, child: item));
    }
    if (tail != null) {
      if (children.isNotEmpty) children.add(const SizedBox(width: _gap));
      children.add(SizedBox(
        width: cell * span + _gap * (span - 1),
        child: tail,
      ));
    }
    return SizedBox(height: height, child: Row(children: children));
  }
}

/// خانةٌ عريضة تُقرأ بالكلمة: شعارٌ صغير ثمّ الاسم ثمّ الرسم.
///
/// ‼️ **المحتوى مُوسَّط لا مُصفّ للحافّة**: عرضها يتغيّر بتغيّر عدد الوسائل
/// (عمودٌ على أندرويد حين تحضر آبل باي، عمودان حين تغيب) — ونصٌّ مصفوفٌ لحافّةٍ
/// يبدو معلّقاً في خانةٍ تكاد تكون فارغة.
class _PayWideTile extends StatelessWidget {
  const _PayWideTile({
    required this.selected,
    required this.title,
    required this.onTap,
    this.note,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;

  /// الرسم — يُعرَض **قبل الاختيار لا بعده**؛ رقمٌ يظهر بعد الضغط يُقرأ خديعة.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? TintColors.blush : Colors.white,
          border: Border.all(
            color: selected ? TintColors.sand : TintColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PaymentMark(markKey: 'cod'),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if ((note ?? '').isNotEmpty)
                    Text(
                      note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: TintColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خانةٌ في شبكة وسائل الدفع — شعارٌ وحده، والاسم ملاذُ رجوع.
class _PayChip extends StatelessWidget {
  const _PayChip({
    required this.selected,
    required this.markKeys,
    required this.onTap,
    this.label,
    this.note,
  });

  final bool selected;
  final List<String> markKeys;
  final VoidCallback onTap;

  /// يُعرَض **حين لا شعار**: وسيلةٌ جديدة قد تصل من الخادم قبل أن يُضاف شعارها
  /// إلى نسخة الجهاز — وخانةٌ فارغة تُقرأ عطلاً.
  final String? label;

  /// سطرٌ صغير تحت الشعار — للرسم وحده.
  ///
  /// ‼️ **يُعرَض قبل الاختيار لا بعده.** رسمٌ يظهر بعد الضغط يُقرأ خديعة، وهو
  /// أثمنُ ما يُفقَد في شاشة دفع. ولذلك دخل «الدفع عند الاستلام» الشبكة
  /// **بشرط أن يدخل رسمه معه**.
  final String? note;

  bool get _hasMark => markKeys.any(kPaymentMarks.containsKey);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? TintColors.blush : Colors.white,
          border: Border.all(
            color: selected ? TintColors.sand : TintColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _hasMark
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < markKeys.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Flexible(child: PaymentMark(markKey: markKeys[i])),
                      ],
                    ],
                  ),
                  if ((note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: TintColors.textMuted,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                label ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
      ),
    );
  }
}

class _TabbyBuyerCard extends StatelessWidget {
  const _TabbyBuyerCard({
    required this.emailController,
    required this.dobController,
    required this.selectedDob,
    required this.onSelectDob,
  });

  final TextEditingController emailController;
  final TextEditingController dobController;
  final DateTime? selectedDob;
  final VoidCallback onSelectDob;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FEFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB8F7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بيانات مطلوبة من Tabby',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'يدخل العميل بياناته داخل واجهة Tabby، لكننا نحتاج البريد وتاريخ الميلاد لتجهيز الجلسة بشكل صحيح.',
            style: TextStyle(
              color: TintColors.textMuted,
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'name@example.com',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dobController,
            readOnly: true,
            onTap: onSelectDob,
            decoration: InputDecoration(
              labelText: 'تاريخ الميلاد',
              hintText: 'YYYY-MM-DD',
              suffixIcon: const Icon(Icons.date_range_outlined),
              helperText: selectedDob == null ? 'مطلوب لإتمام التحقق داخل Tabby' : null,
            ),
          ),
        ],
      ),
    );
  }
}
