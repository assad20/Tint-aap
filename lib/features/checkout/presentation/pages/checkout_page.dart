import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../account/presentation/cubit/addresses_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/checkout_cubit.dart';
import '../services/tabby_checkout_service.dart';
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('خدمة الموقع غير مفعّلة على الجهاز.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('لتحديد الموقع فعّل إذن الموقع للتطبيق.');
        return;
      }
      // الموقع المخزّن أوّلاً (فوريّ)، وإلا موقع حيّ بمهلة تمنع التعليق.
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 15));
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _snack('تمّ تحديد موقع التوصيل ✅');
    } catch (_) {
      _snack('تعذّر تحديد الموقع، حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void initState() {
    super.initState();
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
      _addressId = a.id;
      if (_name.text.isEmpty) _name.text = a.recipient;
      if (_phone.text.isEmpty) _phone.text = a.mobile;
      _city.text = a.city;
      _neighborhood.text = a.neighborhood;
      _details.text = a.details;
    }
    if (_tabbyEmailController.text.isEmpty) {
      _tabbyEmailController.text = _email.text;
    }
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

  // عنوان الطلب مبنيّ من نموذج الشحن الحقيقيّ (لا بيانات افتراضيّة وهميّة).
  AddressModel _currentAddress() {
    return AddressModel(
      id: _addressId,
      title: 'التوصيل',
      recipient: _name.text.trim(),
      mobile: _phone.text.trim(),
      city: _city.text.trim(),
      neighborhood: _neighborhood.text.trim(),
      details: _details.text.trim(),
      isDefault: true,
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
              _SelectableTile(
                selected: state.shippingMethod == 'aramex',
                title: 'توصيل سريع (Aramex)',
                subtitle: 'التوصيل خلال 2-3 أيام عمل',
                trailing: '25 ﷼',
                onTap: () => context.read<CheckoutCubit>().setShippingMethod('aramex'),
              ),
              const SizedBox(height: 10),
              _SelectableTile(
                selected: state.shippingMethod == 'smsa',
                title: 'توصيل عادي (SMSA)',
                subtitle: 'التوصيل خلال 4-5 أيام عمل',
                trailing: 'مجاني',
                trailingColor: TintColors.success,
                onTap: () => context.read<CheckoutCubit>().setShippingMethod('smsa'),
              ),
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
              _SelectableTile(
                selected: state.paymentMethod == 'applepay',
                title: 'Apple Pay',
                subtitle: 'دفع سريع وآمن',
                trailing: 'Pay',
                onTap: () => context.read<CheckoutCubit>().setPaymentMethod('applepay'),
              ),
              const SizedBox(height: 10),
              _SelectableTile(
                selected: state.paymentMethod == 'tabby',
                title: 'Tabby - 4 دفعات بدون فوائد',
                subtitle: 'ادفعي على 4 دفعات سريعة وبدون رسوم إضافية.',
                trailing: 'tabby',
                trailingColor: const Color(0xFF3EEDBF),
                onTap: () => context.read<CheckoutCubit>().setPaymentMethod('tabby'),
              ),
              if (state.paymentMethod == 'tabby') ...[
                const SizedBox(height: 12),
                if (appConfig.hasTabbyConfig)
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
                      'مفاتيح Tabby العامة غير مضبوطة بعد في التطبيق.',
                      style: TextStyle(color: TintColors.danger, fontSize: 11),
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
              _SelectableTile(
                selected: state.paymentMethod == 'tamara',
                title: 'Tamara - 3 دفعات',
                subtitle: 'بدون رسوم تأخير',
                trailing: 'tamara',
                trailingColor: const Color(0xFFF2A7A4),
                onTap: () => context.read<CheckoutCubit>().setPaymentMethod('tamara'),
              ),
              const SizedBox(height: 10),
              _SelectableTile(
                selected: state.paymentMethod == 'card',
                title: 'البطاقة الائتمانية / مدى',
                subtitle: 'VISA / MC / mada',
                trailing: 'بطاقة',
                onTap: () => context.read<CheckoutCubit>().setPaymentMethod('card'),
              ),
              if (state.paymentMethod == 'card') ...[
                const SizedBox(height: 12),
                const _CardForm(),
              ],
              const SizedBox(height: 10),
              _SelectableTile(
                selected: state.paymentMethod == 'paypal',
                title: 'PayPal',
                subtitle: 'الدفع عبر PayPal',
                trailing: 'PayPal',
                trailingColor: const Color(0xFF003087),
                onTap: () => context.read<CheckoutCubit>().setPaymentMethod('paypal'),
              ),
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
    final cartState = context.read<CartCubit>().state;
    if (cartState.items.isEmpty) return;

    // تحقّق من اكتمال بيانات الشحن المطلوبة قبل الإرسال.
    final a = widget.address;
    if (a.recipient.isEmpty ||
        a.mobile.isEmpty ||
        a.city.isEmpty ||
        a.details.isEmpty) {
      _showSnackBar(context, 'أكمل بيانات الشحن المطلوبة (المميّزة بـ*).');
      return;
    }

    if (state.paymentMethod == 'tabby') {
      await _handleTabbyPayment(context, state);
      return;
    }

    await context.read<CheckoutCubit>().submitOrder(
          items: cartState.items,
          address: widget.address,
        );
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

    final appConfig = context.read<AppConfig>();
    if (!appConfig.hasTabbyConfig) {
      _showSnackBar(context, 'إعدادات Tabby غير مكتملة في التطبيق.');
      return;
    }

    final cartState = context.read<CartCubit>().state;
    final service = TabbyCheckoutService(appConfig);
    final orderReference = 'TN-TABBY-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final session = await service.createSession(
        items: cartState.items,
        address: widget.address,
        totalAmount: cartState.total,
        buyerName: widget.address.recipient,
        buyerEmail: buyerEmail,
        buyerDob: buyerDob,
        orderReference: orderReference,
      );

      await context.read<CheckoutCubit>().registerPendingTabbyOrder(
            paymentId: session.paymentId,
            paymentToken: session.paymentToken,
            sessionId: session.sessionId,
            orderReference: orderReference,
            items: cartState.items,
            address: widget.address,
            buyerEmail: buyerEmail,
            buyerDob: buyerDob,
          );

      final result = await service.openCheckout(
        context: context,
        checkoutUrl: session.checkoutUrl,
      );

      if (!mounted) return;

      switch (result) {
        case WebViewResult.authorized:
          final confirmation = await context.read<CheckoutCubit>().confirmTabbyPayment(
                paymentId: session.paymentId,
                paymentToken: session.paymentToken,
                sessionId: session.sessionId,
                orderReference: orderReference,
                items: cartState.items,
                address: widget.address,
                buyerEmail: buyerEmail,
                buyerDob: buyerDob,
              );
          if (!mounted) return;
          _showSuccessDialog(context, confirmation.orderId.isEmpty ? orderReference : confirmation.orderId);
          break;
        case WebViewResult.rejected:
          _showSnackBar(context, 'تم رفض طلب Tabby من جهة المزود.');
          break;
        case WebViewResult.expired:
          _showSnackBar(context, 'انتهت جلسة Tabby. أعيدي المحاولة من جديد.');
          break;
        case WebViewResult.close:
          _showSnackBar(context, 'تم إغلاق شاشة Tabby. إذا اكتمل التفويض سيصل التأكيد من الخادم خلال لحظات.');
          break;
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSuccessDialog(BuildContext context, String orderId) async {
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
      },
      builder: (context, state) {
        return TintSurfaceCard(
          child: Column(
            children: [
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
                    '${cartState.total.toStringAsFixed(2)} ﷼',
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
    required this.trailing,
    this.trailingColor = TintColors.sand,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String trailing;
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
            Text(
              trailing,
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

class _CardForm extends StatelessWidget {
  const _CardForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        TextField(decoration: InputDecoration(hintText: 'رقم البطاقة')),
        SizedBox(height: 10),
        TextField(decoration: InputDecoration(hintText: 'الاسم على البطاقة')),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: 'تاريخ الانتهاء (MM/YY)'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: 'CVV'),
              ),
            ),
          ],
        ),
      ],
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
