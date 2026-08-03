import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_theme.dart';

/// نتيجة شاشة تابي كما تراها الواجهة.
///
/// ‼️ ليست حكماً على الدفع: الحكم للخادم وحده (يسأل تابي مباشرةً). هذه تقول
/// «كيف خرج المشتري من الشاشة» فقط.
enum TabbyWebviewOutcome { success, cancelled, failed, closed }

/// شاشة دفع تابي — بديلاً عن شاشة الحزمة.
///
/// ‼️ شاشة الحزمة تنتظر رسالةً من جسر جافاسكربت نصّها بالضبط
/// `authorized`/`rejected`/`expired`/`close`، وتُهمل أيّ رسالةٍ سواها بصمت،
/// ولا تراقب الروابط إطلاقاً. ولأنّ حمولة الحزمة لا تحمل `merchant_urls`
/// أصلاً، كانت تابي تُنهي الدفع وتقول «سنعيدك الآن» ثمّ لا تجد عنواناً تعود
/// إليه — فتقف الشاشة إلى الأبد بينما المال مُصرَّحٌ به عند تابي.
///
/// هنا الجلسة يُنشئها خادمنا بعناوين عودةٍ حقيقيّة، وهذه الشاشة **تراقب
/// الرابط** فتعرف متى تُغلق. ويبقى الجسر مُسجَّلاً كطريقٍ ثانٍ لا وحيد.
class TabbyWebviewPage extends StatefulWidget {
  const TabbyWebviewPage({
    super.key,
    required this.checkoutUrl,
    required this.successUrl,
    required this.cancelUrl,
    required this.failureUrl,
  });

  final String checkoutUrl;
  final String successUrl;
  final String cancelUrl;
  final String failureUrl;

  @override
  State<TabbyWebviewPage> createState() => _TabbyWebviewPageState();
}

class _TabbyWebviewPageState extends State<TabbyWebviewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _done = false;

  /// نطابق بالمسار لا بالعنوان كاملاً: تابي تُلحق مُعاملات (`payment_id`…)
  /// بعنوان العودة، فالمطابقة الحرفيّة تفشل دائماً.
  bool _matches(String url, String configured) {
    if (configured.trim().isEmpty) return false;
    final target = Uri.tryParse(configured);
    final actual = Uri.tryParse(url);
    if (target == null || actual == null) return false;
    return actual.host == target.host && actual.path.startsWith(target.path);
  }

  TabbyWebviewOutcome? _outcomeFor(String url) {
    if (_matches(url, widget.successUrl)) return TabbyWebviewOutcome.success;
    if (_matches(url, widget.cancelUrl)) return TabbyWebviewOutcome.cancelled;
    if (_matches(url, widget.failureUrl)) return TabbyWebviewOutcome.failed;
    return null;
  }

  void _finish(TabbyWebviewOutcome outcome) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // الجسر نفسه الذي تعرفه صفحة تابي — طريقٌ ثانٍ إن أرسلت رسالةً بدل
      // التحويل. نقبل أيّ نصٍّ معروف ولا نُسقط ما لا نعرفه بصمت.
      ..addJavaScriptChannel(
        'tabbyMobileSDK',
        onMessageReceived: (message) {
          switch (message.message.toLowerCase().trim()) {
            case 'authorized':
              _finish(TabbyWebviewOutcome.success);
              break;
            case 'rejected':
            case 'expired':
              _finish(TabbyWebviewOutcome.failed);
              break;
            case 'close':
              _finish(TabbyWebviewOutcome.cancelled);
              break;
            default:
              debugPrint('Tabby bridge message ignored: ${message.message}');
          }
        },
      )
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
        if (!didPop) _finish(TabbyWebviewOutcome.closed);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: TintColors.charcoal,
          elevation: 0.5,
          title: const Text(
            'الدفع عبر Tabby',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            // ‼️ الإغلاق اليدويّ ليس إلغاءً مؤكّداً: قد يكون المشتري أتمّ
            // الدفع ثمّ أغلق. المُستدعي يسأل الخادم في الحالتين.
            onPressed: () => _finish(TabbyWebviewOutcome.closed),
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
