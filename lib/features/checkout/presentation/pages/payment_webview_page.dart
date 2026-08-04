import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_theme.dart';

/// نتيجة شاشة الدفع كما تراها الواجهة.
///
/// ‼️ ليست حكماً على الدفع: الحكم للخادم وحده (يسأل المزوّد مباشرةً). هذه
/// تقول «كيف خرج المشتري من الشاشة» فقط.
enum PaymentWebviewOutcome { success, cancelled, failed, closed }

/// شاشة دفعٍ مشتركة لكلّ مزوّدٍ مستضاف (تابي · تمارا).
///
/// ‼️ لا تعتمد على جسر جافاسكربت **بل على مراقبة الرابط**.
///
/// شاشة حزمة تابي كانت تنتظر رسالةً نصّها بالضبط `authorized`/`rejected`/
/// `expired`/`close`، وتُهمل ما سواها بصمت، ولا تراقب الروابط إطلاقاً. ولأنّ
/// حمولة الحزمة لا تحمل `merchant_urls` أصلاً، كانت تابي تُنهي الدفع وتقول
/// «سنعيدك الآن» ثمّ لا تجد عنواناً تعود إليه — فتقف الشاشة إلى الأبد بينما
/// المال مُصرَّحٌ به.
///
/// هنا الجلسة يُنشئها خادمنا بعناوين عودةٍ حقيقيّة، وهذه الشاشة تعرف متى
/// تُغلق. و[jsBridgeName] طريقٌ ثانٍ اختياريّ لا وحيد — تمارا لا تحتاجه.
class PaymentWebviewPage extends StatefulWidget {
  const PaymentWebviewPage({
    super.key,
    required this.title,
    required this.checkoutUrl,
    required this.successUrl,
    required this.cancelUrl,
    required this.failureUrl,
    this.jsBridgeName,
  });

  final String title;
  final String checkoutUrl;
  final String successUrl;
  final String cancelUrl;
  final String failureUrl;

  /// اسم قناة الجسر إن كان للمزوّد واحدة (تابي: `tabbyMobileSDK`).
  final String? jsBridgeName;

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _done = false;

  /// نطابق بالمضيف والمسار لا بالعنوان كاملاً: المزوّدون يُلحقون مُعاملات
  /// (`payment_id`، `orderId`…) بعنوان العودة، فالمطابقة الحرفيّة تفشل دائماً.
  bool _matches(String url, String configured) {
    if (configured.trim().isEmpty) return false;
    final target = Uri.tryParse(configured);
    final actual = Uri.tryParse(url);
    if (target == null || actual == null) return false;
    return actual.host == target.host && actual.path.startsWith(target.path);
  }

  PaymentWebviewOutcome? _outcomeFor(String url) {
    if (_matches(url, widget.successUrl)) return PaymentWebviewOutcome.success;
    if (_matches(url, widget.cancelUrl)) return PaymentWebviewOutcome.cancelled;
    if (_matches(url, widget.failureUrl)) return PaymentWebviewOutcome.failed;
    return null;
  }

  void _finish(PaymentWebviewOutcome outcome) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);

    // الجسر — طريقٌ ثانٍ إن أرسل المزوّد رسالةً بدل التحويل. تمارا لا جسر لها،
    // فيُسجَّل عند تابي وحدها. ونُسجّل ما لا نعرفه بدل إسقاطه بصمت.
    final bridge = widget.jsBridgeName;
    if (bridge != null && bridge.isNotEmpty) {
      _controller.addJavaScriptChannel(
        bridge,
        onMessageReceived: (message) {
          switch (message.message.toLowerCase().trim()) {
            case 'authorized':
              _finish(PaymentWebviewOutcome.success);
              break;
            case 'rejected':
            case 'expired':
              _finish(PaymentWebviewOutcome.failed);
              break;
            case 'close':
              _finish(PaymentWebviewOutcome.cancelled);
              break;
            default:
              debugPrint('$bridge message ignored: ${message.message}');
          }
        },
      );
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            final outcome = _outcomeFor(url);
            if (outcome != null) _finish(outcome);
          },
          onNavigationRequest: (req) {
            final outcome = _outcomeFor(req.url);
            if (outcome != null) {
              // لا نُحمّل صفحة المتجر داخل الشاشة: العنوان بلغ غايته.
              _finish(outcome);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(PaymentWebviewOutcome.closed);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: TintColors.charcoal,
          elevation: 0.5,
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            // ‼️ الإغلاق اليدويّ ليس إلغاءً مؤكّداً: قد يكون المشتري أتمّ
            // الدفع ثمّ أغلق. المُستدعي يسأل الخادم في الحالتين.
            onPressed: () => _finish(PaymentWebviewOutcome.closed),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
