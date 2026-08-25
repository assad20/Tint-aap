import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/widgets/tint_map.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/location/delivery_location.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/addresses_cubit.dart';

/// محرّر العنوان — **واحدٌ للحساب وللدفع معاً**.
///
/// ‼️ **ولا يُنسَخ في شاشة الدفع**: محرّران للشيء نفسه يتباعدان مع أوّل تعديل،
/// فيحفظ أحدهما دبّوس الخريطة والآخر لا — والطلب يُشحن بما حفظه الأضعف.
class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    this.addressId,
    this.local = false,
    this.initial,
  });

  final String? addressId;

  /// **وضع الزائر**: يُعيد العنوان ولا يحفظه عند الخادم.
  ///
  /// ‼️ **لأنّ نقاط حفظ العناوين محميّةٌ بالتوكن** — فالحفظ لزائرٍ بلا حساب
  /// يفشل بـ401، ولا معنى لعرض «جارٍ الحفظ…» ثمّ رسالة فشلٍ لعملٍ لا يجوز
  /// أصلاً. والزائر يحتاج **الشاشة** لا التخزين: نفس الحقول ونفس الخريطة ونفس
  /// معاينة الدبّوس، والنتيجة تسكن الطلب وحده.
  final bool local;

  /// ما يُملأ به النموذج في وضع الزائر (تعديلُ ما أدخله قبل قليل).
  final AddressModel? initial;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController nameController;
  late final TextEditingController mobileController;
  late final TextEditingController cityController;
  late final TextEditingController neighborhoodController;
  late final TextEditingController detailsController;

  String title = 'المنزل';
  double? lat;
  double? lng;

  /// العنوان الوطنيّ المختصر — للعرض فوق المعاينة، ولا يُحفَظ (البند ٢٣).
  String? shortCode;
  bool isDefault = false;
  bool _saving = false;

  /// ‼️ **تغيّر الحيّ يجعل التفاصيل قديمةً لا خاطئة** — و«مالك بن خلف» شارعٌ
  /// في الحيّ السابق. فلا تُمحى (لا تعرفها خريطة، ومحوُها يُضيّع ما لا يُستعاد)
  /// **ولا تُترك بلا إشارة**: تُوسَم للمراجعة حتّى يلمسها العميل.
  bool _detailsStale = false;

  /// ‼️ **الافتراضيّ الوحيد لا يُنزَع من هنا**: نزعُه يترك الحساب بلا افتراضيّ،
  /// فيختار الدفعُ «أوّل ما في القائمة» صامتاً — وهو ترتيبٌ لا يملكه العميل.
  bool _lockedDefault = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AddressesCubit>();
    final address = widget.initial ?? cubit.findById(widget.addressId);

    title = address?.title ?? 'المنزل';
    lat = address?.lat;
    lng = address?.lng;
    isDefault = address?.isDefault ?? cubit.state.items.isEmpty;
    _lockedDefault = (address?.isDefault ?? false) &&
        cubit.state.items.where((item) => item.isDefault).length == 1;

    nameController = TextEditingController(text: address?.recipient);
    mobileController = TextEditingController(text: address?.mobile);
    cityController = TextEditingController(text: address?.city ?? 'الرياض');
    neighborhoodController = TextEditingController(text: address?.neighborhood);
    detailsController = TextEditingController(text: address?.details);
  }

  Future<void> _pickLocation() async {
    final picked = await pickDeliveryLocation(
      context,
      initialLat: lat,
      initialLng: lng,
    );
    if (picked == null || !mounted) return;

    /// ‼️ **الدبّوس يقود النصّ ولا يتبعه.**
    ///
    /// كان يملأ الحقلَ الفارغ فقط «لئلّا يُمحى ما كتبه العميل» — وأثرُه في
    /// التعديل أنّ **شيئاً لا يتغيّر أبداً**: الحقول مملوءةٌ سلفاً، فتُنقَل
    /// النقطة إلى حيٍّ آخر ويبقى الاسم القديم. والنتيجة عنوانٌ يناقض
    /// إحداثيّاته — وهو أسوأ من الاثنين.
    ///
    /// ونقلُ الدبّوس فعلٌ مقصود، فالمدينة والحيّ يتبعانه. أمّا **تفاصيل
    /// العنوان** (الشارع والمبنى والدور) فتبقى بيد العميل: لا تعرفها خريطة،
    /// ومحوُها يُضيّع ما لا يُستعاد.
    final previousCity = cityController.text.trim();
    final previousHood = neighborhoodController.text.trim();
    final newCity = picked.city?.trim() ?? '';
    final newHood = picked.neighborhood?.trim() ?? '';

    setState(() {
      lat = picked.lat;
      lng = picked.lng;
      shortCode = picked.shortCode;
      if (newCity.isNotEmpty) cityController.text = newCity;
      if (newHood.isNotEmpty) neighborhoodController.text = newHood;
    });

    if (!picked.hasAddress) {
      // ‼️ **يُقال ولا يُترك للصمت**: الترميز العكسيّ لا يعمل على كلّ جهاز،
      //    وسكوتُنا يجعل العميل يظنّ الخريطة معطّلة وقد نُقل الدبّوس فعلاً.
      _snack('نُقل الدبّوس ✅ — تعذّر استنباط الاسم، اكتبي المدينة والحيّ.');
      return;
    }

    final changed = (newCity.isNotEmpty && newCity != previousCity) ||
        (newHood.isNotEmpty && newHood != previousHood);
    if (changed && detailsController.text.trim().isNotEmpty) {
      setState(() => _detailsStale = true);
    }
    _snack(changed
        ? 'حُدّثت المدينة والحيّ — راجعي تفاصيل العنوان.'
        : 'تمّ تحديد الموقع ✅');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    final city = cityController.text.trim();
    final neighborhood = neighborhoodController.text.trim();
    final details = detailsController.text.trim();
    final recipient = nameController.text.trim();
    final mobile = mobileController.text.trim();

    if (recipient.isEmpty || mobile.isEmpty || city.isEmpty || details.isEmpty) {
      _snack('أكملي اسم المستلم وجوّاله والمدينة وتفاصيل العنوان.');
      return;
    }

    final navigator = Navigator.of(context);

    /// ‼️ **الزائر يعود فوراً بلا نداء شبكة.** لا حفظ عند الخادم (لا حساب له)،
    /// ولا انتظارَ ولا احتمالَ فشل — العنوان يسكن الطلب الحاليّ وحده.
    if (widget.local) {
      navigator.pop(
        AddressModel(
          id: widget.initial?.id ?? 'mobile-form',
          title: title,
          recipient: recipient,
          mobile: mobile,
          city: city,
          neighborhood: neighborhood,
          details: details,
          isDefault: false,
          lat: lat,
          lng: lng,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final cubit = context.read<AddressesCubit>();
    try {
      final saved = await cubit.upsert(
        AddressModel(
          // ‼️ فارغٌ للجديد: **المُعرّف من الخادم** لا من ساعة الجهاز. ومُعرّفٌ
          //    محلّيّ يُنتج عنواناً يفشل أوّل تعديلٍ عليه بـ404 بلا سببٍ ظاهر.
          id: widget.addressId ?? '',
          title: title,
          recipient: recipient,
          mobile: mobile,
          city: city,
          neighborhood: neighborhood,
          details: details,
          isDefault: isDefault,
          lat: lat,
          lng: lng,
        ),
      );
      if (!mounted) return;
      // يعود بالعنوان المحفوظ: شاشة الدفع تختاره فوراً بلا إعادة جلب.
      navigator.pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('تعذّر حفظ العنوان — تحقّقي من الاتّصال وحاولي مجدداً.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.addressId != null;
    final hasPin = lat != null && lng != null;

    return TintPageScaffold(
      title: (isEdit || widget.initial != null)
          ? 'تعديل العنوان'
          : (widget.local ? 'عنوان التوصيل' : 'إضافة عنوان جديد'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          /// ‼️ **الخريطة أوّل ما يُعرَض، ومكانها كان صورة مخزون أجنبيّة.**
          ///
          /// على الجوّال الموقع أدقّ من الوصف وأسرع: دبّوسٌ واحد يُغني عن ثلاثة
          /// حقول، والمندوب يصل به لا بـ«خلف المسجد».
          /// ‼️ **معاينةٌ لا سطرُ إحداثيّات — حين يوجد دبّوس.**
          ///
          /// كان السطر يقول «24.71225، 46.67795»، وهي أرقامٌ **لا يتحقّق منها
          /// أحد**: لا تُقرأ ولا تُقارَن بالذاكرة. والعميل يكتب تفاصيل عنوانه
          /// وهو لا يرى أين وضع دبّوسه، فيعود إلى الخريطة ليتأكّد.
          ///
          /// وصورةٌ صغيرة تُجيب في لمحة: هذا شارعي أو ليس شارعي.
          if (hasPin) _MapPreview(
            lat: lat!,
            lng: lng!,
            shortCode: shortCode,
            onEdit: _pickLocation,
          )
          else InkWell(
            onTap: _pickLocation,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TintColors.line, width: 1.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_location_alt_outlined,
                    color: TintColors.sand,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حدّدي الموقع على الخريطة',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const Text(
                          'يصل المندوب بالدبّوس أسرع من الوصف',
                          style: TextStyle(color: TintColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded, color: TintColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TintSurfaceCard(
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'تسمية العنوان',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['المنزل', 'العمل', 'أخرى']
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              selected: title == item,
                              label: Text(item),
                              onSelected: (_) => setState(() => title = item),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'اسم المستلم',
                  controller: nameController,
                  hint: 'الاسم الذي يسأل عنه المندوب',
                ),
                _LabeledField(
                  label: 'جوّال المستلم',
                  controller: mobileController,
                  hint: '05xxxxxxxx',
                  keyboardType: TextInputType.phone,
                ),
                /// ‼️ **حقلٌ لا قائمة**: كانت ثلاث مدن مكتوبة. والترميز العكسيّ
                /// يُعيد مدناً خارجها — وقيمةٌ خارج `DropdownButtonFormField`
                /// **تُسقط الشاشة** ولا تُتجاهَل.
                _LabeledField(
                  label: 'المدينة',
                  controller: cityController,
                  hint: 'الرياض',
                ),
                _LabeledField(
                  label: 'الحيّ',
                  controller: neighborhoodController,
                  hint: 'العليا',
                ),
                _LabeledField(
                  label: 'تفاصيل العنوان',
                  controller: detailsController,
                  hint: 'الشارع، المبنى، الدور…',
                  minLines: 2,
                  maxLines: 3,
                  warning: _detailsStale ? 'تغيّر الحيّ — راجعي التفاصيل' : null,
                  onChanged: _detailsStale
                      ? (_) => setState(() => _detailsStale = false)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          /// ‼️ **يُخفى عن الزائر**: «الافتراضيّ» وعدٌ بتذكّر لمن لا حساب له
          /// — ولا يُحفظ شيءٌ أصلاً، فالمفتاح يعد بما لا يقع.
          if (!widget.local)
          TintSurfaceCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اجعليه عنواني الافتراضيّ',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        'يُختار تلقائيّاً عند كلّ طلب',
                        style: TextStyle(color: TintColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                /// ‼️ **يبقى قابلاً للّمس وإن كان محكوماً — والصمت هو العطل.**
                ///
                /// كان `onChanged: null` حين يكون هذا هو الافتراضيّ الوحيد،
                /// فيلمسه العميل ولا يتحرّك شيء ولا تُقال كلمة — فيُقرأ زرّاً
                /// معطّلاً لا قاعدةً محترمة. (بلاغ المالك بالتشغيل.)
                Switch(
                  value: isDefault,
                  onChanged: (value) {
                    if (_lockedDefault && !value) {
                      _snack(
                        'هذا عنوانك الافتراضيّ الوحيد — اجعلي عنواناً آخر '
                        'افتراضيّاً وسيُنزَع عن هذا تلقائيّاً.',
                      );
                      return;
                    }
                    setState(() => isDefault = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TintPrimaryButton(
            // ‼️ «حفظ» تَعِد بما لا يقع في وضع الزائر — فالكلمة تتبع الفعل.
            label: widget.local
                ? 'اعتماد العنوان'
                : (_saving ? 'جارٍ الحفظ…' : 'حفظ العنوان'),
            expanded: true,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    cityController.dispose();
    neighborhoodController.dispose();
    detailsController.dispose();
    super.dispose();
  }
}

/// حقلٌ باسمٍ فوقه — لا بنصٍّ داخله يختفي عند أوّل حرف.
///
/// ‼️ **`hintText` وحده كان يمحو المعنى**: نصُّ التلميح يزول حين يمتلئ الحقل،
/// فيقرأ العميل خمسة أسطرٍ متشابهة («نواف · 966… · الرياض · العليا · مالك بن
/// خلف») ولا يعرف أيّها الحيّ وأيّها التفاصيل — وهي شكوى المالك بالتشغيل.
///
/// والحقل أقصر ليتّسع الاسم فوقه بلا أن تطول الشاشة.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.warning,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;

  /// تحذيرٌ تحت الحقل — للتفاصيل التي تقادمت بتغيّر الحيّ.
  final String? warning;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5, right: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: warning == null ? TintColors.textMuted : TintColors.warning,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: warning == null
                  ? null
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: TintColors.warning),
                    ),
            ),
          ),
          if (warning != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: TintColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    warning!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TintColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


/// معاينةٌ ساكنة لموقع التوصيل داخل شاشة التفاصيل.
///
/// ‼️ **غير تفاعليّة عمداً** (`InteractiveFlag.none`): خريطةٌ تبتلع السحب داخل
/// قائمةٍ تُمرَّر تجعل الشاشة تبدو عالقة — فالتحريك يقع في المنتقي وحده،
/// وهذه صورةٌ تُضغَط لا خريطةٌ تُدار.
class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.lat,
    required this.lng,
    required this.onEdit,
    this.shortCode,
  });

  final double lat;
  final double lng;
  final String? shortCode;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(lat, lng);
    final code = shortCode?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            Positioned.fill(
              // ‼️ **نفس محرّك المنتقي** — انظر `TintMapCanvas`. ومعاينةٌ
              //    بمحرّكٍ ولوحةُ اختيارٍ بآخر تُريان مكاناً واحداً بشكلين.
              child: IgnorePointer(
                child: TintMapCanvas(
                  useGoogle: context.read<AppConfig>().useGoogleMaps,
                  initialCenter: center,
                  initialZoom: 16.5,
                  interactive: false,
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 26),
                child: Icon(Icons.location_pin, size: 34, color: TintColors.sand),
              ),
            ),
            // ‼️ **الرمز فوق المعاينة**: هو ما يُقارنه العميل بعنوانه الحقيقيّ.
            if (code.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_location_alt_outlined,
                            size: 15, color: TintColors.charcoal),
                        SizedBox(width: 5),
                        Text(
                          'تعديل الموقع',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: TintColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
