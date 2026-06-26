class TabbyConfirmationResult {
  const TabbyConfirmationResult({
    required this.orderId,
    required this.paymentStatus,
    required this.queued,
    required this.message,
  });

  final String orderId;
  final String paymentStatus;
  final bool queued;
  final String message;

  factory TabbyConfirmationResult.fromJson(Map<String, dynamic> json) {
    return TabbyConfirmationResult(
      orderId: json['orderId']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? 'unknown',
      queued: json['queued'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}
