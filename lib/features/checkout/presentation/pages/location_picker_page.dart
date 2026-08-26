import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/widgets/tint_map.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/location/geocode.dart';
import '../../../../core/network/api_client.dart';

// منتقي موقع التوصيل على خريطة OpenStreetMap (بلا مفتاح/بطاقة).
// العميل يحرّك الخريطة فيبقى الدبّوس في المنتصف، ثمّ «تأكيد الموقع» يعيد الإحداثيّات.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, required this.initial});

  final LatLng initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

// زرّ دائريّ صغير فوق الخريطة (تكبير/تصغير/موقعي).
class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: TintColors.charcoal),
        ),
      ),
    );
  }
}

/// ‼️ **عتبة الدقّة** — دونها لا يُقبل الموقع.
///
/// عند 15 ترى حيّاً كاملاً، وعند 17 ترى المباني. ودبّوسٌ على مستوى الحيّ
/// **ليس عنواناً** — يقف عنده المندوب ويتّصل، أو يعيد الطرد. والعميل لا يعرف
/// أنّ ما اختاره غير كافٍ ما لم يُقَل له.
const double _kPreciseZoom = 16.5;

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _controller = TintMapController();
  late LatLng _center = widget.initial;
  double _zoom = 15;

  /// جلب موقع الجهاز جارٍ — يمنع ضغطتين متتاليتين ويُري العميل أنّ شيئاً يحدث.
  bool _locating = false;

  PickedDeliveryLocation? _place;
  bool _resolving = false;

  /// ‼️ **مؤقّتٌ لا نداءٌ مع كلّ إطار**: تحريك الخريطة يُطلق `onPositionChanged`
  /// عشرات المرّات في الثانية، وترميزُ كلٍّ منها يُغرق المُحوّل ويستنزف
  /// البطّاريّة — ولا يُعرَض منه إلّا الأخير.
  Timer? _debounce;

  bool get _precise => _zoom >= _kPreciseZoom;

  @override
  void initState() {
    super.initState();
    _scheduleResolve(immediate: true);
    // نُخفي أيّ إشعار عالق (مثل «أُضيف للسلة») كي لا يغطّي زرّ التأكيد.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    super.dispose();
  }

  void _scheduleResolve({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: immediate ? 0 : 550),
      _resolve,
    );
  }

  Future<void> _resolve() async {
    final target = _center;
    setState(() => _resolving = true);
    final place = await reverseGeocodeArabic(
      target.latitude,
      target.longitude,
      api: context.read<ApiClient>(),
    );
    if (!mounted) return;
    // ‼️ تُهمَل النتيجة إن تحرّكت الخريطة أثناء الجلب — وإلّا عُرض عنوانُ نقطةٍ
    //    غادرها العميل.
    if (target != _center) return;
    setState(() {
      _place = place;
      _resolving = false;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedDeliveryLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        city: _place?.city,
        neighborhood: _place?.neighborhood,
        street: _place?.street,
        shortCode: _place?.shortCode,
        // ‼️ يُمرَّران وإلّا ضاعا بين الاختيار والنموذج — و`line` تبنيهما.
        buildingNumber: _place?.buildingNumber,
        postalCode: _place?.postalCode,
      ),
    );
  }

  // تكبير/تصغير بالأزرار — أدقّ من القرص بإصبعين لتحديد مبنى بعينه.
  void _zoomBy(double delta) {
    _controller.zoomBy(delta);
    setState(() => _zoom = _controller.zoom);
  }

  /// **يحدّد موقع الجهاز الآن** — لا يعود إلى النقطة التي فُتحت بها الشاشة.
  ///
  /// ‼️ **وهذا هو الفرق كلّه.** كان الزرّ يُعيد إلى `widget.initial`، وهي
  /// النقطة التي حُسبت **قبل فتح الخريطة** — أو الرياض إن لم يُسمح بالموقع
  /// حينها. فمن رفض الإذن ثمّ أراد موقعه كان الزرّ يُلقيه في وسط الرياض بلا
  /// كلمة، ومن تحرّك بعد فتح الشاشة يُعاد إلى مكانه القديم.
  ///
  /// ‼️ **ويُسأل الإذن هنا لا في مكانٍ آخر**: الطلب في لحظة الضغط على زرٍّ
  /// اسمه «تحديد موقعي» **مفهومٌ سببُه**، بخلاف نافذةٍ تقفز عند فتح الشاشة.
  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('خدمة الموقع مُغلقة — فعّليها من إعدادات الجهاز.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('إذن الموقع مرفوضٌ نهائيّاً — فعّليه من إعدادات التطبيق.');
        return;
      }
      if (permission == LocationPermission.denied) {
        _snack('نحتاج إذن الموقع لتحديد مكانك — أو حرّكي الخريطة يدويّاً.');
        return;
      }

      /// ‼️ **آخر موقعٍ معروف أوّلاً، ثمّ يُصقَل بتثبيتٍ طازج.**
      ///
      /// التثبيت الطازج قد يتأخّر عشرين ثانية داخل مبنى — أو لا يأتي أصلاً.
      /// وانتظارٌ صامت بهذا الطول في شاشة عنوانٍ يُقرأ تعليقاً، فيضغط العميل
      /// الزرّ مرّاتٍ أو يخرج. (رُصد على المحاكي 2026-08-25: طلبُ تثبيتٍ جديد
      /// بقي معلّقاً لأنّ الجهاز لا يُنتج تثبيتاً ما لم يُغذَّ.)
      ///
      /// فيقفز الدبّوس فوراً إلى آخر موقعٍ معروف — وهو في الغالب على بُعد
      /// أمتار — ثمّ **يُصحَّح صامتاً** إن وصل الطازج. ولا رسالةَ خطأٍ إن تأخّر
      /// الطازج ما دام العميل قد نُقل فعلاً: خطأٌ يعقب نجاحاً يُربك لا يُفيد.
      final last = await Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (last != null) _moveTo(LatLng(last.latitude, last.longitude));

      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        // ‼️ لا رمي: التأخّر ليس فشلاً حين يكون بين أيدينا موقعٌ مقبول.
        if (last != null) return last;
        throw TimeoutException('تعذّر الحصول على تثبيتٍ جديد');
      });
      if (!mounted) return;
      _moveTo(LatLng(fresh.latitude, fresh.longitude));
    } catch (_) {
      _snack('تعذّر تحديد موقعك الآن — حاولي مجدداً أو حرّكي الخريطة.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// ‼️ يُقرّب فوق العتبة: موقعٌ بتقريبٍ بعيد يُعيد المشكلة التي جاء الزرّ لحلّها.
  void _moveTo(LatLng point) {
    _controller.moveTo(point, 17);
    setState(() {
      _center = point;
      _zoom = 17;
    });
    _scheduleResolve(immediate: true);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: TintColors.charcoal,
        elevation: 0.5,
        title: const Text(
          'حدّد موقع التوصيل',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        // !! **لا «تأكيد» في الترويسة بعد اليوم.**
        //
        // كان مخرجاً دائماً «لا يحجبه إشعار» — ومذ صار القبول مشروطاً بدقّة
        // التقريب صار **ثقباً في الحارس**: الزرّ السفليّ معطّل والعلويّ يقبل،
        // فيخرج العميل بدبّوسٍ على مستوى الحيّ ظانّاً أنّه أكمل.
        //
        // ومخرجٌ واحدٌ للقبول أصدق من اثنين يختلفان في الشروط.
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// ‼️ **محرّك الخريطة خلف لوحةٍ واحدة** — انظر `TintMapCanvas`.
          ///
          /// كانت `FlutterMap` مكتوبةً هنا مباشرةً، فتبديل المحرّك كان يعني
          /// إعادة كتابة الشاشة كلّها: حارس الدقّة، والترميز العكسيّ المؤجَّل،
          /// وحالة الدبّوس. وهي أثمن ما فيها وأكثره اختباراً.
          TintMapCanvas(
            useGoogle: context.read<AppConfig>().useGoogleMaps,
            controller: _controller,
            initialCenter: widget.initial,
            initialZoom: 15,
            onCameraMove: (center, zoom) {
              _center = center;
              if ((zoom - _zoom).abs() > 0.01) {
                setState(() => _zoom = zoom);
              }
              _scheduleResolve();
            },
          ),
          // دبّوس ثابت في منتصف الشاشة (الخريطة تتحرّك تحته).
          Positioned(
            bottom: null,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// ‼️ **الفقاعة تقول الحالة لا الترحيب**: «هنا» حين يكفي
                  /// التقريب، و«قرّبي» حين لا يكفي. ورسالةٌ ثابتة تُطمئن العميل
                  /// إلى دبّوسٍ لن يجده المندوب.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _precise ? 'سيصل طلبك هنا' : 'قرّبي الخريطة وحدّدي المكان',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _precise ? TintColors.charcoal : TintColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    // نرفع الدبّوس نصف ارتفاعه ليشير رأسه للمركز تماماً.
                    padding: EdgeInsets.only(bottom: 44),
                    child: Icon(Icons.location_pin, size: 46, color: TintColors.sand),
                  ),
                ],
              ),
            ),
          ),
          /// ‼️ **الأزرار فوق البطاقة في عمودٍ واحد لا بإزاحةٍ مُخمَّنة.**
          ///
          /// كانت `bottom: 96` رقماً ثابتاً بينما ارتفاع البطاقة يتغيّر بما
          /// فيها (سطرُ عنوانٍ أو سطران · عنوانٌ وطنيّ أو لا) — فكانت الأزرار
          /// تختفي خلفها. ووضعُها في `Column` فوقها يجعلها تتبعها مهما تغيّرت.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  // 20 لا 12: يُبعد الأزرار عن منطقة إيماءة الرجوع على الحافّة.
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      /// ‼️ **في صدر الصفّ لا ذيله** — أي على اليمين في واجهةٍ
                      /// عربيّة (طلب المالك، والمرجع نايس ون): هو الفعل الذي
                      /// يُنهي المهمّة بضغطةٍ واحدة، والتكبير أداةُ ضبطٍ بعده.
                      _LocateMeButton(busy: _locating, onTap: _locateMe),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MapButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                          const SizedBox(height: 8),
                          _MapButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                        ],
                      ),

                      /// ‼️ **زرٌّ باسمه لا أيقونةً وحدها** (طلب المالك
                      /// 2026-08-25، والمرجع نايس ون). أيقونة `my_location`
                      /// يعرفها من رآها في خرائط قبلُ، ومن لم يرَها لا يجرّبها
                      /// في شاشة عنوانٍ يخشى أن يُخطئ فيها.
                    ],
                  ),
                ),
                // بطاقة العنوان + التأكيد أسفل الشاشة.
                _AddressSheet(
                  line: _place?.line ?? '',
                  shortCode: _place?.shortCode ?? '',
                  resolving: _resolving,
                  precise: _precise,
                  onConfirm: _confirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// زرّ «تحديد موقعي» — كبسولةٌ بيضاء باسمٍ ظاهر.
///
/// ‼️ **يبقى قابلاً للّمس أثناء الجلب ويُظهر دوّاراً**: تعطيلُه يجعل الضغطة
/// الثانية بلا أثرٍ ولا تفسير، فيُقرأ زرّاً معطّلاً لا عملاً جارياً.
class _LocateMeButton extends StatelessWidget {
  const _LocateMeButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: busy
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TintColors.sand,
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: TintColors.charcoal,
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                busy ? 'جارٍ التحديد…' : 'تحديد موقعي',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: TintColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة أسفل الخريطة: العنوان المُستنبط، وحالة الدقّة، وزرّ التأكيد.
class _AddressSheet extends StatelessWidget {
  const _AddressSheet({
    required this.line,
    required this.shortCode,
    required this.resolving,
    required this.precise,
    required this.onConfirm,
  });

  final String line;

  /// العنوان الوطنيّ المختصر — يُعرَض حين يعرفه الخادم فقط.
  final String shortCode;
  final bool resolving;
  final bool precise;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  precise ? Icons.where_to_vote_rounded : Icons.zoom_in_map_rounded,
                  color: precise ? TintColors.success : TintColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        precise ? 'موقع التوصيل' : 'العنوان غير دقيق',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: precise ? TintColors.textMuted : TintColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      /// ‼️ **العنوان بالعربيّة** — انظر `reverseGeocodeArabic`.
                      ///
                      /// و«جارٍ» نصٌّ لا دوّارة: دوّارةٌ مع كلّ تحريكةٍ تجعل
                      /// البطاقة ترتجف طوال السحب.
                      /// ‼️ **الرمز أوّلاً حين يوجد — وهو أدقّ ما في السطر.**
                      ///
                      /// «RHWA2868» عنوانٌ وطنيٌّ يدلّ على المبنى بعينه،
                      /// و«حي الورود» يدلّ على حيٍّ فيه آلاف المباني. فمن
                      /// يتحقّق من دبّوسه يقرأ الأوّل، ومن يقود إليه يقرأ
                      /// الثاني — فيُعرضان معاً بترتيب الدقّة.
                      if (shortCode.isNotEmpty)
                        Text(
                          shortCode,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            height: 1.3,
                          ),
                        ),
                      Text(
                        resolving && line.isEmpty
                            ? 'جارٍ تحديد العنوان…'
                            : (line.isEmpty
                                ? 'حرّكي الخريطة إلى مكان التوصيل'
                                : line),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: shortCode.isEmpty ? 14.5 : 13,
                          fontWeight:
                              shortCode.isEmpty ? FontWeight.w800 : FontWeight.w600,
                          color: shortCode.isEmpty
                              ? TintColors.charcoal
                              : TintColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      precise ? TintColors.charcoal : const Color(0xFFD9D9DE),
                  foregroundColor: precise ? Colors.white : const Color(0xFF8A8F98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // !! **يُعطَّل دون العتبة ولا يُخفى**: زرٌّ يختفي يجعل العميل
                //    يبحث عنه، وزرٌّ باهتٌ يقول «افعلي شيئاً أوّلاً».
                onPressed: precise ? onConfirm : null,
                icon: Icon(precise ? Icons.check_rounded : Icons.add_rounded),
                label: Text(
                  precise ? 'تأكيد الموقع' : 'قرّبي الخريطة أكثر',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
