import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

/// سجلّ التصفّح — من التخزين المحلّيّ لا من الخادم.
///
/// كان يقرأ `bundle.browsingHistory` وهي قائمةٌ فارغة ثابتة في المستودع، فظلّت
/// الشاشة تعرض «لا يوجد سجلّ» مهما تصفّح المستخدم. الجهاز يعرف ما شاهده صاحبه،
/// ولا حاجة لربط سلوكٍ بهويّة على الخادم لعرضه.
class BrowsingHistoryPage extends StatefulWidget {
  const BrowsingHistoryPage({super.key});

  @override
  State<BrowsingHistoryPage> createState() => _BrowsingHistoryPageState();
}

class _BrowsingHistoryPageState extends State<BrowsingHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final prefs = context.read<AppPreferences>();
    final items = prefs.recentlyViewed;

    return TintPageScaffold(
      title: 'سجل التصفح',
      child: items.isEmpty
          ? const TintEmptyState(
              icon: Icons.history_rounded,
              title: 'لا يوجد سجل تصفح بعد',
              subtitle: 'ابدأ التصفح وسيظهر سجل المنتجات التي شاهدتها هنا.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${items.length} منتجاً',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TintColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await prefs.clearRecentlyViewed();
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('مسح السجل'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 268,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) =>
                        ProductCard(product: items[index], dense: true),
                  ),
                ),
              ],
            ),
    );
  }
}
