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
    this.secureLabel,
    this.amountLabel,
  });

  final String title;
  final String checkoutUrl;
  final String successUrl;
  final String cancelUrl;
  final String failureUrl;

  /// اسم قناة الجسر إن كان للمزوّد واحدة (تابي: `tabbyMobileSDK`).
  final String? jsBridgeName;

  /// سطر الطمأنة في الترويسة — «دفعٌ آمن عبر …».
  ///
  /// ‼️ **يُعاد ذكر اسم المزوّد هنا عمداً وإن قُرئ في الشاشة السابقة.** شاشة
  /// «إتمام الطلب» تقول «دفع آمن ببطاقة مدى عبر PayTabs»، ثمّ يختفي الاسم
  /// تماماً عند فتح صفحته — فينقطع الخيط بين ما قرأه المشتري وما يراه.
  final String? secureLabel;

  /// المبلغ كما يراه المشتري في الطلب — يبقى أمام عينه وهو يدفع.
  final String? amountLabel;

  /// يعرض صفحة المزوّد **ورقةً تصعد من الأسفل** فوق شاشة الطلب.
  ///
  /// ‼️ **لماذا ورقةٌ لا صفحةٌ مستقلّة؟** الانتقال إلى شاشةٍ كاملة يقطع الصلة
  /// بالطلب: يرى المشتري نموذج بطاقةٍ يملأ الشاشة لا يربطه بالمتجر شيء — وهو
  /// أوّل ما يُقرأ احتيالاً. وبالورقة يبقى طرفُ شاشة الطلب ظاهراً فوقها، فيقرأ
  /// أنّه لم يُنقَل إلى مكانٍ آخر بل فُتحت نافذةٌ فوق طلبه.
  ///
  /// ‼️ **والإغلاق اليدويّ يعود `closed` لا `cancelled`** — والفرق ليس تسمية:
  /// المُستدعي يسأل الخادم عن `closed` ولا يسأله عن `cancelled`. وقد يُغلق
  /// المشتري الورقة بعد أن أتمّ الدفع، فعدُّ ذلك إلغاءً يُضيّع طلباً مدفوعاً.
  ///
  /// ‼️ **ولا تُغلَق بسحبٍ ولا بلمس ما فوقها** — وهذا **نقضٌ مقصود** لما كان
  /// مكتوباً هنا: كان السحب طريقَ خروجٍ معتبَراً.
  ///
  /// والسبب بلاغٌ من جهازٍ حقيقيّ على صفحة تابي. الورقة ٩٢٪ من الشاشة، فما
  /// فوقها حاجزٌ يُغلقها بلمسة. وعند تعديل الجوّال تجتمع ثلاثة في لحظة: لوحة
  /// المفاتيح تفتح ⇒ الورقة تنكمش ⇒ **يتّسع الحاجز تحت الإبهام**، والمشتري
  /// يسحب ليصل إلى الحقل ⇒ **فيُقرأ سحبه إغلاقاً**. فتنغلق الورقة، ويُسأل
  /// الخادم، وتابي لم تُصرّح بعد ⇒ «لم يكتمل الدفع» **وطلبٌ لا يُنشأ**.
  ///
  /// والحارس السابق (`closed` لا `cancelled`) يحمي من **سوء تفسير** الإغلاق،
  /// ولا يمنع وقوعه عرضاً. والأولى ألّا يقع: يبقى الخروج بـ✕ في الترويسة أو
  /// بزرّ الرجوع — كلاهما فعلٌ مقصود، وكلاهما ما زال يعيد `closed`.
  static Future<PaymentWebviewOutcome> present(
    BuildContext context, {
    required String title,
    required String checkoutUrl,
    required String successUrl,
    required String cancelUrl,
    required String failureUrl,
    String? jsBridgeName,
    String? secureLabel,
    String? amountLabel,
  }) async {
    final outcome = await showModalBottomSheet<PaymentWebviewOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // ‼️ دفعةٌ جارية لا تُقطَع بلمسةٍ عارضة — انظر شرح `present` أعلاه.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => PaymentWebviewPage(
        title: title,
        checkoutUrl: checkoutUrl,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        failureUrl: failureUrl,
        jsBridgeName: jsBridgeName,
        secureLabel: secureLabel,
        amountLabel: amountLabel,
      ),
    );
    return outcome ?? PaymentWebviewOutcome.closed;
  }

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
    final media = MediaQuery.of(context);

    /// ‼️ **الارتفاع 0.92 لا نصف الشاشة.**
    ///
    /// صفحة المزوّد صفحةُ ويبٍ كاملة: اسمٌ على البطاقة · رقمٌ · شهرٌ وسنةٌ ورمز ·
    /// مبلغٌ · زرّان · مبدّل لغة. وورقةٌ قصيرة تجعلها تُمرَّر **داخل نفسها**،
    /// فيصير على المشتري تمريران متداخلان — أسوأ من الصفحة الكاملة لا أفضل.
    /// والغاية أن يبقى طرفُ شاشة الطلب ظاهراً فوقها، لا أن تُحشر الصفحة.
    final maxHeight = media.size.height * 0.92;

    /// ‼️ **الورقة تنكمش للوحة المفاتيح ولا تُدفَع تحتها.**
    ///
    /// إدخال البطاقة يستدعي اللوحة حتماً. وارتفاعٌ ثابت يُبقي الحقول خلفها
    /// فيكتب المشتري في حقلٍ لا يراه. وبانكماش الإطار تصغر نافذة العرض فتُمرّر
    /// الصفحة نفسها إلى الحقل المُركَّز — وهو سلوك المتصفّح الطبيعيّ، فلا نُعيد
    /// بناءه بحسابات موضعٍ من عندنا.
    final height = (maxHeight - media.viewInsets.bottom)
        .clamp(media.size.height * 0.45, maxHeight);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(PaymentWebviewOutcome.closed);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: height,
          /// ‼️ **بلا `clipBehavior` — وهذا سببُ التجمّد لا زينةٍ حُذفت.**
          ///
          /// `WebView` على أندرويد **عرضُ منصّةٍ** لا ودجةُ رسم. وقصُّ عرض
          /// منصّةٍ يُجبر فلاتر على مسارٍ بطيء: طبقةٌ تُحفَظ ونسيجٌ يُنسَخ **في
          /// كلّ إطار** ما دامت الصفحة تتحرّك. وصفحة الدفع مليئةٌ بجافاسكربت،
          /// فيمتلئ الخيط الرئيسيّ ويقول أندرويد `isn't responding`.
          ///
          /// والقصّ كان بلا أثرٍ بصريّ أصلاً: الزوايا المستديرة في **أعلى**
          /// الورقة حيث الترويسة البيضاء المُعتِمة، والـWebView تحتها.
          child: Material(
            color: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ‼️ **شريطٌ يقول «ورقةٌ لا شاشة» — ولا يقول «تُسحَب».**
                //
                // كان مقبضاً بعرض 44، وهي لغة المقابض المعروفة. ومذ صار السحب
                // معطَّلاً (انظر `present`) يصير المقبض وعداً لا يُوفى: يسحب
                // المشتري فلا يحدث شيء، فيظنّ الشاشة معلَّقة وسط دفعة. فبقي
                // الشريط أوسعَ وأخفت — إشارةُ حدٍّ لا دعوةُ سحب.
                Container(
                  width: 72,
                  height: 3,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _header(),
                const Divider(height: 1),
                /// ‼️ **بديلٌ لا طبقةٌ فوقه.**
                ///
                /// كان مؤشّر التحميل يُرسَم **فوق** الـWebView في `Stack` —
                /// وطبقةٌ فوق عرض منصّةٍ تُكلّف ما يُكلّفه القصّ: تركيبٌ في كلّ
                /// إطار بينما الصفحة تُحمّل، وهي أثقل لحظةٍ في العمر كلّه.
                ///
                /// و`Offstage` لا `if`: بناء الـWebView من جديد بعد التحميل
                /// يُعيد تحميل الصفحة من أوّلها.
                Expanded(
                  child: Stack(
                    children: [
                      Offstage(
                        offstage: _loading,
                        child: WebViewWidget(controller: _controller),
                      ),
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ترويسة الورقة: من أنت، وكم تدفع، ومن يعالج الدفع.
  ///
  /// ‼️ الثلاثة معاً لا أحدها: الترويسة القديمة كانت عنواناً و✕ فقط، فلا مبلغ
  /// يُطمئن ولا اسم مزوّدٍ يُفسّر لماذا تبدّل شكل الصفحة فجأة.
  Widget _header() {
    final secure = widget.secureLabel?.trim();
    final amount = widget.amountLabel?.trim();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: TintColors.charcoal,
            // ‼️ الإغلاق اليدويّ ليس إلغاءً مؤكّداً: قد يكون المشتري أتمّ
            // الدفع ثمّ أغلق. المُستدعي يسأل الخادم في الحالتين.
            onPressed: () => _finish(PaymentWebviewOutcome.closed),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: TintColors.charcoal,
                  ),
                ),
                if (secure != null && secure.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: Colors.black54),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            secure,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (amount != null && amount.isNotEmpty)
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: TintColors.charcoal,
              ),
            ),
        ],
      ),
    );
  }
}
