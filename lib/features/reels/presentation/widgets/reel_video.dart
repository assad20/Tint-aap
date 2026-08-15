import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_theme.dart';

/// مشغّل مقطعٍ واحد داخل الشريط.
///
/// ‼️ **يملك المشغّل ولا يشاركه.** `PageView` يُبقي الصفحات المجاورة حيّة، فلو
/// كان المشغّل مشتركاً لسمع المشاهد صوت المقطع التالي قبل أن يصل إليه. ولذلك
/// لكلّ صفحةٍ مشغّلها، ويُتخلّص منه بخروجها.
///
/// ‼️ **و`isActive` تُمرَّر ولا تُستنتج من الرؤية**: `VisibilityDetector` يُطلق
/// أثناء الانزلاق فيبدأ مقطعان معاً للحظة. والصفحة النشطة يعرفها `PageView`
/// وحده يقيناً.
/// مقبضٌ يمنح الصفحةَ الأمَ التحكّمَ بالتشغيل دون أن تملك المشغّل.
///
/// ‼️ **بديلٌ عن `GlobalKey` ونداءٍ بـ`dynamic`.** حالة المشغّل خاصّة بملفّها،
/// والوصول إليها من الخارج كان يمرّ بـ`as dynamic` — فإعادة تسمية الدالّة لا
/// تُنتج خطأ ترجمة، بل زرَّ إيقافٍ لا يفعل شيئاً يُكتشَف بالتجربة وحدها.
class ReelVideoHandle {
  VoidCallback? _togglePlay;

  void togglePlay() => _togglePlay?.call();
}

class ReelVideo extends StatefulWidget {
  const ReelVideo({
    super.key,
    required this.url,
    required this.isActive,
    required this.muted,
    required this.poster,
    this.handle,
  });

  final ReelVideoHandle? handle;

  final String url;
  final bool isActive;
  final bool muted;

  /// صورة المنتج — تُعرض حتّى يجهز الإطار الأوّل. وبدونها ومضةٌ سوداء بين كلّ
  /// مقطعين تُقرأ عطلاً.
  final String poster;

  @override
  State<ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<ReelVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.handle?._togglePlay = _togglePlay;
    _open();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(widget.muted ? 0 : 1);
      if (widget.isActive) await controller.play();
      setState(() => _ready = true);
    } catch (error) {
      // ‼️ رابطٌ مكسور أو صيغةٌ لا يدعمها الجهاز: تُعرض الصورة ورسالةٌ صريحة.
      //    والصمت هنا يترك مستطيلاً أسود يظنّه المشاهد بطئاً فينتظر بلا نهاية.
      debugPrint('[reels] تعذّر تشغيل ${widget.url}: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant ReelVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null || !_ready) return;

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        // ‼️ يُعاد للبداية عند العودة إليه: مقطعٌ يُستأنف من ثانيته الأخيرة
        //    يبدو مقطوعاً، ومقاطع المنتجات قصيرة فلا معنى للاستئناف فيها.
        controller.seekTo(Duration.zero);
        controller.play();
      } else {
        controller.pause();
      }
    }
    if (widget.muted != oldWidget.muted) {
      controller.setVolume(widget.muted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    if (widget.handle?._togglePlay == _togglePlay) widget.handle?._togglePlay = null;
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    setState(() {});
  }

  bool get _isPaused => _ready && !(_controller?.value.isPlaying ?? false);

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        // الصورة تحت الفيديو دائماً: تملأ الحواف في المقاطع الرأسيّة الضيّقة
        // وتغطّي لحظة التهيئة.
        Image.network(
          widget.poster,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
        ),
        if (_ready && controller != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        if (!_ready && !_failed)
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
          ),
        if (_failed)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'تعذّر تشغيل هذا المقطع',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
        /*
          ‼️ أثرٌ مرئيّ للإيقاف. الضغطة التي توقف المقطع بلا علامةٍ تُقرأ
          «تعلّق الفيديو» لا «أوقفتُه أنا» — فيخرج المشاهد ظنّاً منه أنّه عطل.
        */
        if (_isPaused)
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),
          ),
        // شريط تقدّمٍ رفيع بلا تفاعل: يُخبر بطول المقطع وموضعه دون أن يسرق
        // سحبةَ التمرير الرأسيّ التي يملكها الشريط.
        if (_ready && controller != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final total = value.duration.inMilliseconds;
                final at = value.position.inMilliseconds;
                final progress = total > 0 ? (at / total).clamp(0.0, 1.0) : 0.0;
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(TintColors.tintYellow),
                );
              },
            ),
          ),
      ],
    );
  }
}
