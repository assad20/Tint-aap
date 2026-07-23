import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';

// منتقي موقع التوصيل على خريطة OpenStreetMap (بلا مفتاح/بطاقة).
// العميل يحرّك الخريطة فيبقى الدبّوس في المنتصف، ثمّ «تأكيد الموقع» يعيد الإحداثيّات.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, required this.initial});

  final LatLng initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _controller = MapController();
  late LatLng _center = widget.initial;

  @override
  void initState() {
    super.initState();
    // نُخفي أيّ إشعار عالق (مثل «أُضيف للسلة») كي لا يغطّي زرّ التأكيد.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_center);

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
        actions: [
          // تأكيد دائم في الرأس — لا يحجبه أيّ إشعار.
          TextButton(
            onPressed: _confirm,
            child: const Text(
              'تأكيد',
              style: TextStyle(
                color: TintColors.sand,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
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
              onPositionChanged: (camera, _) => _center = camera.center,
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
          const Positioned(
            bottom: null,
            child: IgnorePointer(
              child: Padding(
                // نرفع الدبّوس نصف ارتفاعه ليشير رأسه للمركز تماماً.
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(Icons.location_pin, size: 46, color: TintColors.sand),
              ),
            ),
          ),
          // زرّ التأكيد أسفل الشاشة.
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: TintColors.charcoal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _confirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'تأكيد الموقع',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
