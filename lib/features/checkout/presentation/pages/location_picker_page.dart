import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  final _controller = MapController();
  late LatLng _center = widget.initial;
  double _zoom = 15;

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
    _controller.dispose();
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
      ),
    );
  }

  // تكبير/تصغير بالأزرار — أدقّ من القرص بإصبعين لتحديد مبنى بعينه.
  void _zoomBy(double delta) {
    final cam = _controller.camera;
    final zoom = (cam.zoom + delta).clamp(3.0, 19.0);
    _controller.move(cam.center, zoom);
    setState(() => _zoom = zoom);
  }

  // العودة لموقع الجهاز الأوّل.
  void _recenter() {
    // ‼️ يُقرّب إلى ما فوق العتبة: العودة إلى موقعك بتقريبٍ بعيد تُعيد المشكلة
    //    التي جاء الزرّ ليحلّها.
    _controller.move(widget.initial, 17);
    setState(() {
      _center = widget.initial;
      _zoom = 17;
    });
    _scheduleResolve(immediate: true);
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
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
              // تعطيل الدوران: التكبير بإصبعين كان يدوّر الخريطة عن طريق الخطأ
              // فيتغيّر الاتجاه. نُبقي السحب/التكبير/النقر المزدوج فقط.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) {
                _center = camera.center;
                if ((camera.zoom - _zoom).abs() > 0.01) {
                  setState(() => _zoom = camera.zoom);
                }
                _scheduleResolve();
              },
            ),
            children: [
              TileLayer(
                // خريطة CartoDB Voyager — نظيفة وأنيقة (نمط التطبيقات الحديثة)،
                // مجّانيّة بلا مفتاح، بديلاً عن تُيوب OSM الخام المزدحمة.
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'com.tintstore.app',
              ),
            ],
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
          // أزرار التكبير/التصغير + العودة لموقعي — تحديد دقيق لمبنى بعينه.
          Positioned(
            // 20 لا 12: يُبعد الأزرار عن منطقة إيماءة الرجوع على حافّة أندرويد.
            left: 20,
            bottom: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                const SizedBox(height: 14),
                _MapButton(icon: Icons.my_location, onTap: _recenter),
              ],
            ),
          ),
          // بطاقة العنوان + التأكيد أسفل الشاشة.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AddressSheet(
              line: _place?.line ?? '',
              shortCode: _place?.shortCode ?? '',
              resolving: _resolving,
              precise: _precise,
              onConfirm: _confirm,
            ),
          ),
        ],
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
