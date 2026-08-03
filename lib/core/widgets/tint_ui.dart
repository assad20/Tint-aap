import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';

// رسالة تأكيد لطيفة عائمة مدوّرة بأيقونة، تختفي تلقائيّاً خلال ثانيتين.
// موحّدة لكلّ إشعارات النجاح (إضافة للسلة…) بدل الأشرطة العريضة الثابتة.
/// رسالة عابرة.
///
/// ‼️ `isError` ليست زينة: الودجة كانت خضراء بعلامة صحّ **دائماً**، فرفضٌ
/// مثل «نفدت كمية هذا المنتج» يظهر بلون النجاح وأيقونته — يقرأ المتسوّق
/// شكلاً يناقض نصّه، فيظنّ الإضافة تمّت.
void showTintToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: isError ? TintColors.danger : TintColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
    );
}

class TintPageScaffold extends StatelessWidget {
  const TintPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onBack,
    this.bottomPadding = 24,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          onPressed: onBack ?? () => context.pop(),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: child,
        ),
      ),
    );
  }
}

class TintBrandLogo extends StatelessWidget {
  const TintBrandLogo({
    super.key,
    this.isLight = false,
    this.compact = false,
  });

  final bool isLight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isLight ? Colors.white : TintColors.charcoal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              'تنت',
              style: TextStyle(
                color: color,
                fontSize: compact ? 20 : 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            Positioned(
              bottom: compact ? -1 : -2,
              left: compact ? -10 : -14,
              child: SizedBox(
                width: compact ? 24 : 34,
                height: compact ? 8 : 12,
                child: CustomPaint(
                  painter: _UnderlinePainter(
                    isLight ? Colors.white.withOpacity(0.85) : TintColors.sand,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tint',
          style: TextStyle(
            color: color,
            fontSize: compact ? 9 : 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(2, size.height - 2)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height - 2,
        size.width * 0.55,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        0,
        size.width - 2,
        size.height * 0.35,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class TintPrimaryButton extends StatelessWidget {
  const TintPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.backgroundColor = TintColors.charcoal,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expanded;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    if (expanded) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}

class TintSecondaryButton extends StatelessWidget {
  const TintSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: TintColors.sand),
        foregroundColor: TintColors.sand,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class TintSectionHeader extends StatelessWidget {
  const TintSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: TintColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class TintSurfaceCard extends StatelessWidget {
  const TintSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TintColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TintEmptyState extends StatelessWidget {
  const TintEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F0),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF6E3DA)),
              ),
              child: Icon(icon, color: TintColors.sand, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: TintColors.charcoal,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: TintColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class TintStatusPill extends StatelessWidget {
  const TintStatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class TintStatTile extends StatelessWidget {
  const TintStatTile({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TintColors.line),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: TintColors.charcoal,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: TintColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TintNetworkImage extends StatelessWidget {
  const TintNetworkImage({
    super.key,
    required this.url,
    required this.fit,
    this.borderRadius = BorderRadius.zero,
    this.height,
    this.width,
    this.overlay,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double? height;
  final double? width;
  final Widget? overlay;

  // يُضبط مرّة في main() من AppConfig.origin. يعيد كتابة مضيف الصور المحلّيّ
  // (localhost/127.0.0.1) إلى مضيف الـAPI نفسه لتظهر الصور على المحاكي/الجهاز.
  // آمن في الإنتاج: روابط الإنتاج لا تحوي localhost فلا تتأثّر.
  static String apiOrigin = '';

  // معلَنة كي يستعملها التحميل المسبق (precache) بالرابط نفسه؛ وإلّا خُزّن
  // رابطٌ وطُلب آخر فلا ينفع التحميل المسبق في البيئة المحلّيّة.
  static String resolve(String url) {
    if (url.isEmpty || apiOrigin.isEmpty) return url;
    return url.replaceFirst(
      RegExp(r'^https?://(localhost|127\.0\.0\.1)(:\d+)?'),
      apiOrigin,
    );
  }

  String get _resolvedUrl => resolve(url);

  Widget _placeholder() => Container(
        height: height,
        width: width,
        color: const Color(0xFFF2F3F5),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: TintColors.textMuted),
      );

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedUrl;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        // صريحة لا افتراضيّة: افتراضيّ Stack هو AlignmentDirectional.topStart،
        // و`start` في واجهةٍ عربيّة = اليمين — فكانت الصورة التي لا تملأ
        // صندوقها تُثبَّت في الزاوية العلويّة اليمنى بدل أن تتوسّطه.
        alignment: Alignment.center,
        children: [
          if (resolved.isEmpty)
            _placeholder()
          else
            CachedNetworkImage(
              imageUrl: resolved,
              fit: fit,
              height: height,
              width: width,
              // تخزين دائم على القرص: تظهر فوراً في الجلسات/العروض التالية.
              fadeInDuration: const Duration(milliseconds: 220),
              placeholder: (context, url) => _placeholder(),
              errorWidget: (context, url, error) => _placeholder(),
            ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }
}
