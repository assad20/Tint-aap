import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

/// لوحة خريطةٍ واحدة فوق محرّكن: خرائط جوجل، أو بلاطات CartoDB المجّانيّة.
///
/// ‼️ **الشاشات لا تعرف أيّهما يعمل.** المنتقي وبطاقة المعاينة يتعاملان مع
/// هذه الواجهة وحدها، فتبديل المحرّك لا يمسّ منطق اختيار الموقع ولا الترميز
/// العكسيّ ولا حارس الدقّة — وهي أثمن ما في تلك الشاشة وأكثره اختباراً.
///
/// ‼️ **ولماذا محرّكان أصلاً؟** خرائط جوجل تحتاج مفتاحاً محقوناً في الحزمة
/// نفسها؛ ونسخةٌ تُبنى بلا مفتاح تعرض **شبكةً رماديّة صامتة**. فيبقى المسار
/// المجّانيّ افتراضيّاً حتّى تُبنى نسخةٌ بمفتاح، ولا يتعطّل تطويرٌ ولا اختبار.
///
/// ‼️ **والإحداثيّات بنوع `latlong2` في الاتّجاهين** — وهو نوع الشيفرة القائمة.
/// وتسريبُ نوع جوجل إلى المُستدعي كان سيجعل المحرّك ظاهراً في كلّ ملفّ لمسه.
class TintMapController {
  _TintMapCanvasState? _state;

  void moveTo(LatLng center, double zoom) => _state?.moveTo(center, zoom);
  void zoomBy(double delta) => _state?.zoomBy(delta);

  double get zoom => _state?._zoom ?? 15;
  LatLng get center => _state?._center ?? const LatLng(24.7136, 46.6753);

  void _attach(_TintMapCanvasState state) => _state = state;
  void _detach(_TintMapCanvasState state) {
    if (identical(_state, state)) _state = null;
  }
}

class TintMapCanvas extends StatefulWidget {
  const TintMapCanvas({
    super.key,
    required this.useGoogle,
    required this.initialCenter,
    this.initialZoom = 15,
    this.controller,
    this.onCameraMove,
    this.interactive = true,
    this.minZoom = 3,
    this.maxZoom = 19,
  });

  /// من `AppConfig.useGoogleMaps` — يُمرَّر ولا يُقرأ هنا، فتبقى الودجة نقيّة
  /// وقابلةً للاختبار بلا إعدادات.
  final bool useGoogle;

  final LatLng initialCenter;
  final double initialZoom;
  final TintMapController? controller;

  /// يُنادى بمركز الكاميرا وتقريبها كلّما تحرّكت — **مصدر الحقيقة للمُستدعي**.
  final void Function(LatLng center, double zoom)? onCameraMove;

  final bool interactive;
  final double minZoom;
  final double maxZoom;

  @override
  State<TintMapCanvas> createState() => _TintMapCanvasState();
}

class _TintMapCanvasState extends State<TintMapCanvas> {
  final MapController _osm = MapController();
  gm.GoogleMapController? _google;

  late LatLng _center = widget.initialCenter;
  late double _zoom = widget.initialZoom;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _google?.dispose();
    super.dispose();
  }

  void moveTo(LatLng center, double zoom) {
    _center = center;
    _zoom = zoom;
    if (widget.useGoogle) {
      _google?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(gm.LatLng(center.latitude, center.longitude), zoom),
      );
    } else {
      _osm.move(center, zoom);
    }
    widget.onCameraMove?.call(center, zoom);
  }

  void zoomBy(double delta) {
    final next = (_zoom + delta).clamp(widget.minZoom, widget.maxZoom);
    moveTo(_center, next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useGoogle) return _buildGoogle();
    return _buildOsm();
  }

  Widget _buildGoogle() {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
        zoom: widget.initialZoom,
      ),
      onMapCreated: (controller) => _google = controller,

      /// ‼️ **أزرار جوجل مُطفأة كلّها** — للتطبيق أزراره العربيّة في مكانها
      /// المدروس فوق البطاقة، وزرّان لنفس الفعل في زاويتين يُربكان.
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,

      /// ‼️ **نقطة الموقع الزرقاء تُعرَض ولا تُتبَع**: يراها العميل فيعرف
      /// أين هو بالنسبة لدبّوسه — وهو ما يفعله نون. والتتبّع التلقائيّ كان
      /// سيسحب الخريطة من تحت إصبعه وهو يضبط الدبّوس.
      myLocationEnabled: widget.interactive,

      zoomGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      liteModeEnabled: !widget.interactive,
      onCameraMove: (position) {
        _center = LatLng(position.target.latitude, position.target.longitude);
        _zoom = position.zoom;
        widget.onCameraMove?.call(_center, _zoom);
      },
    );
  }

  Widget _buildOsm() {
    return FlutterMap(
      mapController: _osm,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom
              : InteractiveFlag.none,
        ),
        onPositionChanged: (camera, _) {
          _center = camera.center;
          _zoom = camera.zoom;
          widget.onCameraMove?.call(_center, _zoom);
        },
      ),
      children: [
        TileLayer(
          /// خريطة CartoDB Voyager — **بديلٌ مؤقّت حتّى يصل مفتاح جوجل**.
          ///
          /// ‼️ **«بوزيترون» أقرب لوناً وأفقرُ محتوى.** جُرّبت (بطلب المالك،
          /// مرجعه نون) فظهرت رماديّةً أنيقة — **وبلا أسماء أحياء ولا معالم
          /// ولا تلوين مبانٍ**: هي «لوحةٌ خلفيّة» مصمَّمة لعرض بياناتٍ فوقها،
          /// تحذف ذلك عمداً. وفي شاشة عنوانٍ يتعرّف العميل على مكانه بالمعالم
          /// لا بلون الخريطة، فالتفصيل أنفع من اللون.
          ///
          /// ولا بلاطةَ مجّانيّةً بلا مفتاح تجمع الاثنين في السعوديّة — وهذا
          /// بالضبط ما يحلّه محرّك جوجل حين يصل مفتاحه.
          ///
          /// ‼️ ومسار «بوزيترون» `light_all` لا `rastertiles/positron`: تخمينه
          /// بالقياس على «فويجر» يُعيد 404 لكلّ بلاطة، فتظهر خريطةٌ رماديّة
          /// صامتة بلا رسالة خطأ. (رُصد على المحاكي 2026-08-25.)
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.tintstore.app',
        ),
      ],
    );
  }
}
