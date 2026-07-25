import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_theme.dart';

// نافذة نون بيمنت المستضافة داخل التطبيق (Hosted Checkout).
// تفتح رابط الدفع، وترصد وصول رابط العودة (callback/success/failed) فتُغلق
// وتُعيد true — ثمّ يتحقّق المُستدعي من الحالة عبر الخادم (المصدر الموثوق).
class NoonWebviewPage extends StatefulWidget {
  const NoonWebviewPage({super.key, required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<NoonWebviewPage> createState() => _NoonWebviewPageState();
}

class _NoonWebviewPageState extends State<NoonWebviewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  // روابط العودة التي تعني انتهاء الدفع (النتيجة تُحسم من الخادم لا منها).
  // الأوّل هو ما يصل فعليّاً؛ البقيّة صفحات نتيجة المتجر تُلتقط احتياطاً إن
  // اكتمل التحويل قبل أن نعترضه.
  bool _isReturnUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('/payments/noon/callback') ||
        u.contains('/checkout/noon/result') ||
        u.contains('/payment/success') ||
        u.contains('/payment/failed') ||
        u.contains('/payment/pending');
  }

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pop(true); // انتهى — المُستدعي يتحقّق
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
            if (url != null && _isReturnUrl(url)) _finish();
          },
          onNavigationRequest: (req) {
            if (_isReturnUrl(req.url)) {
              _finish();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: TintColors.charcoal,
        elevation: 0.5,
        title: const Text(
          'الدفع الآمن',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          // إغلاق يدويّ = إلغاء (false).
          onPressed: () => Navigator.of(context).pop(false),
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
    );
  }
}
