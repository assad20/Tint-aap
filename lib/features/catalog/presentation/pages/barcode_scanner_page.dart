import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/barcode_lookup.dart';

/// ماسح الباركود — يُفتح من شريط البحث ويُعيد المنتج الممسوح.
///
/// ‼️ **يُعيد المنتج عبر `Navigator.pop` ولا ينتقل بنفسه.** الانتقال من داخله
/// يعني أنّ العميل حين يضغط «رجوع» من صفحة المنتج يعود إلى **كاميرا مفتوحة** —
/// شاشةٌ ثقيلة تُستأنف بلا سبب وتُشعل الكشّاف أحياناً. فالمسح ينتهي بإغلاق
/// الماسح، وشريط البحث هو من يفتح المنتج.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key, required this.onLookup});

  /// السؤال عن الرمز — يُمرَّر بدل حقن المستودع هنا، فتبقى الشاشة قابلةً
  /// للتشغيل وحدها ولا تعرف شيئاً عن الشبكة.
  final Future<BarcodeLookup> Function(String code) onLookup;

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  /// ‼️ **الصيغ محصورةٌ بما يُطبَع على المنتجات.**
  ///
  /// الافتراضيّ يقرأ QR ورموز المصفوفات أيضاً، فيلتقط الماسح ملصق شحنٍ على
  /// الطاولة أو رمز واي فاي على الجدار **قبل** أن يستقرّ على العلبة — فيقول
  /// «لا نبيع هذا» عن شيءٍ لم يقصده أحد. وحصرُها يجعل الكاميرا تتجاهل ما ليس
  /// رمز منتج بدل أن تخطئ فيه.
  late final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf14,
    ],
    detectionSpeed: DetectionSpeed.normal,
  );

  /// ‼️ **قفلٌ ضروريّ لا احتياط.** `onDetect` يُنادى عشرات المرّات في الثانية
  /// ما دام الرمز في الإطار — فبلا قفلٍ ينطلق عشرات النداءات للخادم عن الرمز
  /// نفسه، ويُدفَع العميل إلى صفحة المنتج مرّاتٍ متتالية فوق بعضها.
  bool _busy = false;
  String? _lastCode;
  String? _notice;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;

    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;

    // ‼️ ولا يُعاد سؤال الخادم عن رمزٍ رُفض للتوّ ما دامت العلبة أمام العدسة.
    if (code == _lastCode) return;

    setState(() {
      _busy = true;
      _lastCode = code;
      _notice = null;
    });
    unawaited(HapticFeedback.mediumImpact());

    final result = await widget.onLookup(code);
    if (!mounted) return;

    switch (result) {
      case BarcodeFound(:final product):
        Navigator.of(context).pop(product);
      case BarcodeUnknown():
        setState(() {
          _busy = false;
          _notice = 'لا نبيع هذا المنتج في تِنت — جرّب منتجاً آخر.';
        });
      case BarcodeFailed(:final message):
        setState(() {
          _busy = false;
          // ‼️ يُنسى الرمز هنا وحده — كي يُعاد مسحُه فور عودة الشبكة بلا أن
          //    تضطرّ إلى إبعاد العلبة وإعادتها.
          _lastCode = null;
          _notice = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // ‼️ **رسالةٌ تشرح بدل شاشةٍ سوداء.** رفضُ إذن الكاميرا يجعل
            //    المعاينة فارغة، ومن لا يعرف السبب يظنّ التطبيق معطوباً.
            errorBuilder: (context, error) => _PermissionNotice(error: error),
          ),
          const _ScannerFrame(),
          _TopBar(controller: _controller),
          _BottomHint(busy: _busy, notice: _notice),
        ],
      ),
    );
  }
}

/// إطار المسح — يقود العين إلى موضع الرمز.
class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 280,
          height: 170,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2.5),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              tooltip: 'رجوع',
            ),
            const Expanded(
              child: Text(
                'مسح الباركود',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            // ‼️ **الكشّاف ليس زينة**: أرفف المتاجر ورفوف البيوت مظلمة تحت
            //    الظلّ، والعدسة تعجز عن الرمز فيبدو الماسح معطوباً.
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, _) {
                final on = state.torchState == TorchState.on;
                return IconButton(
                  onPressed: () => unawaited(controller.toggleTorch()),
                  tooltip: 'الإضاءة',
                  icon: Icon(
                    on
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    color: on ? TintColors.tintYellow : Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomHint extends StatelessWidget {
  const _BottomHint({required this.busy, required this.notice});

  final bool busy;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: busy
                ? const _Pill(
                    key: ValueKey('busy'),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : _Pill(
                    key: ValueKey(notice ?? 'hint'),
                    child: Text(
                      notice ?? 'وجّه الكاميرا إلى الباركود على العلبة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            notice == null ? Colors.white : TintColors.tintYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white54,
                size: 44,
              ),
              const SizedBox(height: 16),
              Text(
                denied
                    ? 'صلاحيّة الكاميرا مرفوضة — فعّلها من إعدادات التطبيق ثمّ أعِد المحاولة.'
                    : 'تعذّر تشغيل الكاميرا على هذا الجهاز.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
