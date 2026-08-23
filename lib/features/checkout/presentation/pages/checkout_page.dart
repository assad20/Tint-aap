import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'location_picker_page.dart';
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
import '../../../../core/models/payment_method_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../account/presentation/cubit/addresses_cubit.dart';
import '../../../account/presentation/pages/addresses_form_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/checkout_cubit.dart';
import '../widgets/payment_mark.dart';
import '../widgets/tabby_promo_snippet.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
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
  double? _lat;
  double? _lng;
  bool _locating = false;

  /// العنوان المحفوظ المختار — لعميلٍ مسجَّل. و`null` يعني «الافتراضيّ».
  ///
  /// ‼️ **مُعرّفٌ لا نسخة**: حفظُ نسخةٍ من العنوان هنا يجعل تعديلَه من الورقة
  /// لا يظهر في البطاقة حتّى يُعاد فتح الشاشة.
  String? _selectedAddressId;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // التقاط إحداثيّات موقع التوصيل عبر GPS (بلا خريطة/مفتاح خارجيّ).
  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    try {
      // نقطة بداية للخريطة: موقع الجهاز إن سُمح (فوريّ من المخزّن ثمّ الحيّ)،
      // وإلا الرياض افتراضاً — ويحرّك العميل الخريطة للموقع الدقيق على أيّ حال.
      LatLng start = const LatLng(24.7136, 46.6753); // الرياض
      try {
        if (await Geolocator.isLocationServiceEnabled()) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            final pos = await Geolocator.getLastKnownPosition() ??
                await Geolocator.getCurrentPosition()
                    .timeout(const Duration(seconds: 15));
            start = LatLng(pos.latitude, pos.longitude);
          }
        }
      } catch (_) {
        // بلا موقع جهاز — نبدأ من الرياض.
      }
      if (!mounted) return;
      // خريطة OpenStreetMap تفاعليّة (بلا مفتاح): العميل يضع الدبّوس بدقّة.
      final picked = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(builder: (_) => LocationPickerPage(initial: start)),
      );
      if (picked == null) return; // ألغى العميل
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
      });
      final filled = await _reverseGeocode(picked.latitude, picked.longitude);
      _snack(filled
          ? 'تمّ تحديد الموقع وتعبئة المدينة/الحيّ ✅'
          : 'تمّ تحديد موقع التوصيل ✅ (أكمل المدينة/الحيّ يدويّاً)');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // عكس الترميز الجغرافيّ: تعبئة المدينة والحيّ من الإحداثيّات
  // (مُحوّل عناوين أندرويد المدمج — بلا مفتاح خارجيّ). يعيد true إن مُلئ شيء.
  Future<bool> _reverseGeocode(double lat, double lng) async {
    try {
      final places = await Geocoding()
          .placemarkFromCoordinates(lat, lng, locale: const Locale('ar'));
      if (places.isEmpty) return false;
      final p = places.first;
      final city = (p.locality?.trim().isNotEmpty ?? false)
          ? p.locality!.trim()
          : (p.administrativeArea?.trim() ?? '');
      final hood = (p.subLocality?.trim().isNotEmpty ?? false)
          ? p.subLocality!.trim()
          : (p.subAdministrativeArea?.trim() ?? '');
      setState(() {
        if (city.isNotEmpty) _city.text = city;
        if (hood.isNotEmpty) _neighborhood.text = hood;
      });
      return city.isNotEmpty || hood.isNotEmpty;
    } catch (_) {
      // تعذّر الترميز العكسيّ (قد لا يتوفّر على بعض الأجهزة) — نبقي الإحداثيّات فقط.
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
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
          else
            _ShippingFormCard(
              nameC: _name,
              phoneC: _phone,
              emailC: _email,
              cityC: _city,
              neighborhoodC: _neighborhood,
              detailsC: _details,
              onChanged: () => setState(() {}),
              hasLocation: _lat != null && _lng != null,
              isLocating: _locating,
              onLocate: _captureLocation,
            ),
          const SizedBox(height: 12),
          const _ProductsMiniSummary(),
          const SizedBox(height: 12),
          const _ShippingMethodsCard(),
          const SizedBox(height: 12),
          _PaymentMethodsCard(
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
  });

  final AddressModel? address;
  final String? accountName;
  final String? accountPhone;
  final VoidCallback onChange;
  final Future<void> Function({String? id}) onEdit;

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
            const Text(
              'أوّل طلب — يُحفظ عنوانك لما بعده.',
              style: TextStyle(color: TintColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TintSecondaryButton(
                label: 'أضيفي عنوان التوصيل',
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
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
            Text(
              '${a.city}، ${a.neighborhood} — ${a.details}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'المستلم: ${a.recipient} · ${a.mobile}',
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

class _ShippingFormCard extends StatelessWidget {
  const _ShippingFormCard({
    required this.nameC,
    required this.phoneC,
    required this.emailC,
    required this.cityC,
    required this.neighborhoodC,
    required this.detailsC,
    required this.onChanged,
    required this.hasLocation,
    required this.isLocating,
    required this.onLocate,
  });

  final TextEditingController nameC;
  final TextEditingController phoneC;
  final TextEditingController emailC;
  final TextEditingController cityC;
  final TextEditingController neighborhoodC;
  final TextEditingController detailsC;
  final VoidCallback onChanged;
  final bool hasLocation;
  final bool isLocating;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return TintSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TintSectionHeader(title: 'بيانات العميل والشحن'),
          const SizedBox(height: 4),
          const Text(
            'تُستخدم هذه البيانات لمعالجة الطلب وتوصيله.',
            style: TextStyle(color: TintColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          _field(nameC, 'الاسم الكامل *', Icons.person_outline),
          _field(phoneC, 'رقم الجوال *', Icons.phone_outlined,
              ltr: true, type: TextInputType.phone),
          _field(emailC, 'البريد الإلكترونيّ (اختياري)', Icons.mail_outline,
              ltr: true, type: TextInputType.emailAddress),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _field(
                      cityC, 'المدينة *', Icons.location_city_outlined)),
              const SizedBox(width: 10),
              Expanded(
                  child: _field(neighborhoodC, 'الحيّ *', Icons.map_outlined)),
            ],
          ),
          _field(detailsC, 'تفاصيل العنوان *', Icons.home_outlined, maxLines: 2),
          const SizedBox(height: 2),
          InkWell(
            onTap: isLocating ? null : onLocate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: hasLocation ? const Color(0xFFF0FBF3) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasLocation ? Colors.green : TintColors.line,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLocation ? Icons.check_circle_rounded : Icons.my_location,
                    color: hasLocation ? Colors.green : TintColors.sand,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLocating
                          ? 'جارٍ تحديد موقعك…'
                          : hasLocation
                              ? 'تمّ تحديد موقع التوصيل ✅'
                              : 'تحديد موقع التوصيل على الخريطة (اختياريّ)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: hasLocation ? Colors.green.shade700 : TintColors.charcoal,
                      ),
                    ),
                  ),
                  if (isLocating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool ltr = false,
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        textDirection: ltr ? TextDirection.ltr : null,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: Icon(icon, color: TintColors.sand, size: 20),
        ),
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
              if (state.shippingMethods.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'تعذّر جلب طرق التوصيل. تحقّق من اتّصالك وأعد المحاولة.',
                    style: TextStyle(
                        color: TintColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                )
              else
                ...state.shippingMethods.map((m) {
                  final subtotal = context.read<CartCubit>().state.total;
                  final cost = m.costFor(subtotal);
                  final free = cost == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SelectableTile(
                      selected: state.shippingMethod == m.id,
                      title: m.label,
                      subtitle: m.etaLabel,
                      // «مجّاني» حين تتجاوز السلّة العتبة فعلاً — لا كوعدٍ ثابت.
                      trailing: free ? 'مجاني' : '${m.price.toStringAsFixed(0)} ﷼',
                      trailingColor: free ? TintColors.success : TintColors.sand,
                      onTap: () =>
                          context.read<CheckoutCubit>().setShippingMethod(m.id),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({
    required this.tabbyEmailController,
    required this.tabbyDobController,
    required this.selectedDob,
    required this.onSelectDob,
  });

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

  // العنوان الفرعيّ: الوصف + الرسوم إن وُجدت.
  String _subtitle(PaymentMethodModel m) {
    final desc = m.description ?? '';
    if (m.hasFee) {
      final fee = m.fee.toStringAsFixed(m.fee % 1 == 0 ? 0 : 2);
      return desc.isEmpty ? 'رسوم $fee ﷼' : '$desc · رسوم $fee ﷼';
    }
    return desc;
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
              else
                for (final m in state.methods) ...[
                  /**
                   * ‼️ **بطاقة الدفع بالبطاقة تُعرَض مرّتين: «مدى» و«فيزا».**
                   *
                   * المزوّد واحد (PayTabs) والمعرّف المُرسَل إلى الخادم واحد —
                   * والفرق **عرضٌ لا سلوك**. والسبب أنّ المشتري السعوديّ يبحث عن
                   * شعار «مدى» بعينه، و«بطاقة — مدى أو ائتمانيّة» بسطرٍ واحد
                   * تجعله يظنّ أنّ بطاقته غير مقبولة. وهو نفس ما يفعله المتجر.
                   */
                  if (m.id == 'paytabs') ...[
                    _SelectableTile(
                      // ‼️ المعرّف وحده لا يكفي: البطاقتان تُرسلانه نفسه.
                      selected: state.paymentMethod == m.id &&
                          state.cardBrand == 'mada',
                      title: 'مدى',
                      subtitle: 'دفع آمن ببطاقة مدى عبر PayTabs',
                      markKey: 'mada',
                      onTap: () => context
                          .read<CheckoutCubit>()
                          .setPaymentMethod(m.id, cardBrand: 'mada'),
                    ),
                    const SizedBox(height: 10),
                    _SelectableTile(
                      selected: state.paymentMethod == m.id &&
                          state.cardBrand == 'visa',
                      title: 'Visa / Mastercard',
                      subtitle: 'دفع آمن بالبطاقة الائتمانيّة عبر PayTabs',
                      // ‼️ شعاران في بطاقةٍ واحدة — كما يعرضهما الموقع.
                      markKeys: const ['visa', 'mastercard'],
                      onTap: () => context
                          .read<CheckoutCubit>()
                          .setPaymentMethod(m.id, cardBrand: 'visa'),
                    ),
                  ] else
                    _SelectableTile(
                      selected: state.paymentMethod == m.id,
                      title: m.label,
                      subtitle: _subtitle(m),
                      markKey: _markKey(m.id),
                      onTap: () =>
                          context.read<CheckoutCubit>().setPaymentMethod(m.id),
                    ),
                  // كتلة Tabby الخاصّة (العرض + بيانات المشتري) عند اختياره فقط.
                  if (m.id == 'tabby' && state.paymentMethod == 'tabby') ...[
                    const SizedBox(height: 12),
                    if (appConfig.hasTabbyConfig ||
                        (m.publicKey?.isNotEmpty ?? false))
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: buildTabbyPromoSnippet(
                          price: cartState.total.toStringAsFixed(2),
                          currencyCode: appConfig.currencyCode,
                          langCode: appConfig.tabbyLanguage,
                        ),
                      )
                    else
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'مفاتيح Tabby العامة غير مضبوطة بعد.',
                          style:
                              TextStyle(color: TintColors.danger, fontSize: 11),
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
                  const SizedBox(height: 10),
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

      // ‼️ يُسأل الخادم في كلّ الحالات — حتّى الإغلاق اليدويّ.
      final result = await cubit.confirmPayTabsPayment(cartId, tranRef: tranRef);
      if (!mounted) return;

      final createdId = result['orderId']?.toString() ?? '';
      if (createdId.isEmpty) {
        _showSnackBar(
          context,
          result['message']?.toString() ?? 'لم يكتمل الدفع بالبطاقة. يمكنك المحاولة مجدداً.',
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

      // ‼️ يُسأل الخادم في النجاح والإغلاق معاً: الخروج ليس حكماً على الدفع.
      final result = await cubit.confirmTamaraPayment(orderId);
      if (!mounted) return;

      var createdId = result['orderId']?.toString() ?? '';

      /// ‼️ لا نجاح بلا رقم طلبٍ من الخادم.
      ///
      /// كان يُعرَض نجاحٌ بـ`orderReference` — وهو رقمٌ **ولّدَه الجهاز** ولا
      /// وجود له في النظام. فيخرج المشتري مطمئنّاً إلى طلبٍ لا يعرفه أحد.
      ///
      /// وتمارا قد تتأخّر لحظاتٍ بين `approved` و`authorised`، فنُعيد السؤال
      /// مرّتين قبل أن نحكم — ثمّ نقول الحقيقة كما هي.
      for (var attempt = 0; attempt < 2 && createdId.isEmpty; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        final retry = await cubit.confirmTamaraPayment(orderId);
        if (!mounted) return;
        createdId = retry['orderId']?.toString() ?? '';
      }

      if (createdId.isEmpty) {
        _showSnackBar(
          context,
          outcome == PaymentWebviewOutcome.success
              ? 'دفعتك مسجَّلة لدى تمارا ونُتمّ تأكيد طلبك الآن — لا تُعِد الدفع، وستصلك رسالة التأكيد.'
              : 'لم يكتمل الدفع عبر تمارا. يمكنك المحاولة مجدداً.',
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
      final confirmation = await cubit.confirmTabbyPayment(
        paymentId: paymentId,
        sessionId: sessionId,
        orderReference: orderReference,
        items: cartState.items,
        address: widget.address,
        buyerEmail: buyerEmail,
        buyerDob: buyerDob,
      );
      if (!mounted) return;
      if (confirmation.orderId.isEmpty && outcome != PaymentWebviewOutcome.success) {
        _showSnackBar(context, 'لم يكتمل الدفع عبر Tabby. يمكنك المحاولة مجدداً.');
        return;
      }
      _showSuccessDialog(
        context,
        confirmation.orderId.isEmpty ? orderReference : confirmation.orderId,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, _readableError(error));
    }
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

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    /// ‼️ **لاحقةٌ واحدة من اثنتين — والبطاقة مشتركة.**
    ///
    /// تُستعمل لطرق **الشحن** (اللاحقة سعرٌ نصّيّ: «مجاني» · «25 ريال») ولطرق
    /// **الدفع** (اللاحقة شعارٌ رسميّ). وجعلُ الشعار إلزاميّاً كسر الشحن —
    /// وهو ما التقطه المحلّل فوراً. فكلاهما اختياريّ، ويُرسَم الموجود منهما.
    this.markKey,
    /// ‼️ **شعاران في بطاقةٍ واحدة** — «فيزا» و«ماستركارد» علامتان لمزوّدٍ
    /// واحد، وعرضُ إحداهما وحدها يجعل حامل الأخرى يظنّ بطاقته غير مقبولة.
    this.markKeys,
    this.trailing,
    this.trailingColor = TintColors.sand,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String? markKey;
  final List<String>? markKeys;
  final String? trailing;
  final Color trailingColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFAF8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? TintColors.sand : TintColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? TintColors.sand : TintColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TintColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (markKeys != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final key in markKeys!) ...[
                    PaymentMark(markKey: key),
                    const SizedBox(width: 6),
                  ],
                ],
              )
            else if (markKey != null)
              PaymentMark(markKey: markKey!, fallbackLabel: title)
            else if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: trailingColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
          ],
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
