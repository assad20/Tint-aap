import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';

class TabbyCheckoutSession {
  const TabbyCheckoutSession({
    required this.sessionId,
    required this.paymentId,
    required this.checkoutUrl,
    this.paymentToken,
  });

  final String sessionId;
  final String paymentId;
  final String checkoutUrl;
  final String? paymentToken;
}

class TabbyCheckoutService {
  const TabbyCheckoutService(this._config);

  final AppConfig _config;

  Currency get _currency => Currency.sar;

  Lang get _lang =>
      _config.tabbyLanguage.toLowerCase() == 'en' ? Lang.en : Lang.ar;

  Future<TabbyCheckoutSession> createSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required double totalAmount,
    required String buyerName,
    required String buyerEmail,
    required String buyerDob,
    required String orderReference,
  }) async {
    final payment = Payment(
      amount: totalAmount.toStringAsFixed(2),
      currency: _currency,
      buyer: Buyer(
        email: buyerEmail,
        phone: _normalizePhone(address.mobile),
        name: buyerName,
        dob: buyerDob,
      ),
      buyerHistory: BuyerHistory(
        loyaltyLevel: 0,
        registeredSince: DateTime.now().toUtc().toIso8601String(),
        wishlistCount: 0,
      ),
      shippingAddress: ShippingAddress(
        city: address.city,
        address: '${address.neighborhood} - ${address.details}',
        zip: '00000',
      ),
      order: Order(
        referenceId: orderReference,
        items: items
            .map(
              (item) => OrderItem(
                title: item.product.title,
                description: item.variant,
                quantity: item.quantity,
                unitPrice: item.product.price.toStringAsFixed(2),
                referenceId: item.product.id,
                productUrl: 'https://tint.app/products/${item.product.id}',
                category: item.product.category,
              ),
            )
            .toList(),
      ),
      orderHistory: const [],
    );

    final session = await TabbySDK().createSession(
      TabbyCheckoutPayload(
        merchantCode: _config.tabbyMerchantCode,
        lang: _lang,
        payment: payment,
      ),
    );

    final dynamic sessionData = session;

    if (sessionData.status == SessionStatus.rejected) {
      throw Exception(
        _lang == Lang.ar
            ? TabbySDK.rejectionTextAr
            : TabbySDK.rejectionTextEn,
      );
    }

    return TabbyCheckoutSession(
      sessionId: sessionData.id.toString(),
      paymentId: sessionData.payment.id.toString(),
      checkoutUrl: sessionData.availableProducts.installments.webUrl.toString(),
      paymentToken: sessionData.token?.toString(),
    );
  }

  Future<WebViewResult> openCheckout({
    required BuildContext context,
    required String checkoutUrl,
  }) {
    final completer = Completer<WebViewResult>();

    TabbyWebView.showWebView(
      context: context,
      webUrl: checkoutUrl,
      onResult: (result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      },
    );

    return completer.future.timeout(
      const Duration(minutes: 25),
      onTimeout: () => WebViewResult.expired,
    );
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('966')) return '+$digits';
    if (digits.startsWith('05')) return '+966${digits.substring(1)}';
    return digits;
  }
}
