import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/apple_pay_config_model.dart';

/// زرّ آبل باي — **شريحة النظام، وخادمُنا هو الذي يدفع.**
///
/// ‼️ **لا مفاتيح PayTabs على الجهاز.** الحزمة تعرض الشريحة وتُسلّم التوكن، ثمّ
/// يمضي إلى `/payments/paytabs/applepay/pay` — وهي **نفس نقطة الويب**: العقد
/// قناتيٌّ محايد، والتوكن كائنٌ مشفَّرٌ لا يفكّه إلّا من يملك شهادة المعالجة.
///
/// ‼️ **ولا يُعرَض إلّا على iOS وبإذن الخادم.** ثلاثة شروطٍ تجتمع: النظام،
/// و`available` من الخادم (يجمع تفعيل المتجر وتهيئة PayTabs)، وأن يقول النظام
/// إنّ الجهاز مؤهَّل. وزرٌّ يُعرَض بلا هذه يعني شريحةً تُفتَح ثمّ يُرفض الدفع
/// **بعد بصمة العميل** — وهو أسوأ من غياب الزرّ.
class ApplePaySection extends StatelessWidget {
  const ApplePaySection({
    super.key,
    required this.config,
    required this.amount,
    required this.label,
    required this.onToken,
    this.enabled = true,
  });

  final ApplePayConfigModel config;

  /// الإجماليّ كما يراه المشتري — يُعرَض في الشريحة **ويُرسَل ليُقارَن**.
  final double amount;

  /// اسم المتجر في سطر الشريحة الأخير.
  final String label;

  /// يُنادى بتوكن آبل جاهزاً بشكل الخادم.
  final Future<void> Function(Map<String, dynamic> token, String sheetTotal) onToken;

  final bool enabled;

  /// ‼️ **`Platform` تُسأل داخل حارس `kIsWeb`**: قراءتها على الويب ترمي.
  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// نصّ المبلغ بمنزلتين — **نفس ما يُعرَض في الشريحة يُرسَل للمقارنة**، وأيّ
  /// تقريبٍ مختلفٍ بين الاثنين يُنتج رفضاً لا يفهمه أحد.
  String get _sheetTotal => amount.toStringAsFixed(2);

  /// يُحوّل ردّ الحزمة إلى شكل `payment.token` الذي يعرفه خادمنا.
  ///
  /// ‼️ **الحزمة تُسلّم `paymentData` نصّاً لا كائناً** (`String(decoding:)` في
  /// جانب iOS)، والخادم — كالويب — ينتظر كائناً. فتمريرُ النصّ كما هو يُرفَض
  /// من PayTabs برسالةٍ عامّة لا تدلّ على السبب.
  static Map<String, dynamic>? normalizeToken(Map<String, dynamic> result) {
    try {
      final raw = result['token'];
      final paymentData = raw is String ? jsonDecode(raw) : raw;
      if (paymentData is! Map) return null;
      return {
        'paymentData': Map<String, dynamic>.from(paymentData),
        if (result['paymentMethod'] is Map)
          'paymentMethod': Map<String, dynamic>.from(result['paymentMethod'] as Map),
        if (result['transactionIdentifier'] != null)
          'transactionIdentifier': result['transactionIdentifier'].toString(),
      };
    } catch (error) {
      debugPrint('[applepay] توكنٌ لم يُقرأ: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIOS || !config.available || amount <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// ‼️ **الفاصل فوقه لا تحته** — مذ صار أسفل الوسائل.
          ///
          /// كان تحته «أو أكملي بالطرق أدناه» حين كان فوق زرّ الدفع. وبقاؤه
          /// هناك بعد النقل يُحيل إلى وسائل **فوقه** لا تحته — إشارةٌ تدلّ على
          /// الاتّجاه الخاطئ، وهي أسوأ من غياب الإشارة.
          Row(
            children: [
              const Expanded(child: Divider(height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'أو',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: TintColors.textMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider(height: 1)),
            ],
          ),
          const SizedBox(height: 10),
          ApplePayButton(
            paymentConfiguration: PaymentConfiguration.fromJsonString(
              jsonEncode(config.toPayPluginConfig()),
            ),
            paymentItems: [
              PaymentItem(
                label: label,
                amount: _sheetTotal,
                status: PaymentItemStatus.final_price,
              ),
            ],
            style: ApplePayButtonStyle.black,
            type: ApplePayButtonType.buy,
            height: 48,
            // ‼️ **لا يُنادى إلّا بعد بصمة العميل** — لا عند لمس الزرّ.
            onPaymentResult: (result) async {
              if (!enabled) return;
              final token = normalizeToken(Map<String, dynamic>.from(result));
              if (token == null) return;
              await onToken(token, _sheetTotal);
            },
            onError: (error) => debugPrint('[applepay] $error'),
            loadingIndicator: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
