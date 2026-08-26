import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../cubit/search_cubit.dart';
import 'barcode_scanner_page.dart';
import '../widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  late final AppPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _preferences = context.read<AppPreferences>();
    context.read<SearchCubit>().search('', preferences: _preferences);
  }

  /// يفتح الماسح، وينتقل إلى المنتج إن وُجد.
  ///
  /// ‼️ **النقل هنا لا داخل الماسح** — كي لا يعود «رجوعُ» صفحةِ المنتج إلى
  /// كاميرا مفتوحة. والماسح يُغلق نفسه بالمنتج، وهذه الشاشة توجّه.
  Future<void> _openScanner() async {
    final repository = context.read<CatalogRepository>();
    final product = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        // ‼️ **ملء الشاشة لا ورقةً سفليّة**: المسح يحتاج تصويب الكاميرا بيدٍ
        //    ونظراً مستقرّاً، والنافذة الصغيرة تجعل الرمز خارج مجال العدسة.
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerPage(
          onLookup: (code) => repository.lookupBarcode(code),
        ),
      ),
    );

    if (!mounted || product == null) return;
    await context.push('/product', extra: product);
  }

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'البحث',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            return Column(
              children: [
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  // ‼️ **عند الإرسال لا عند كلّ حرف**: حدثٌ لكلّ ضغطة مفتاح
                  //    يُغرق GA4 بمئات الأحداث للبحث الواحد، ويجعل «أشيع
                  //    الكلمات» أحرفاً مبتورة لا كلماتٍ يبحث عنها أحد.
                  // ‼️ يُعاد البناء لتظهر «×» عند أوّل حرفٍ وتختفي عند محوه.
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) {
                    context.read<SearchCubit>().search(value, preferences: _preferences);
                    unawaited(context.read<TrackingService>().logSearch(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحثي عن عطر، فستان، هدية...',
                    prefixIcon: const Icon(Icons.search),
                    /// ‼️ **زرّان في ذيل الحقل لا زرّ واحد.**
                    ///
                    /// «المسح» يبقى ظاهراً دائماً — هو مدخلٌ للبحث لا إجراءٌ
                    /// على نصٍّ مكتوب. أمّا «المسح النصّيّ» فيظهر حين يكون
                    /// هناك ما يُمحى، وإظهاره على حقلٍ فارغ زرٌّ لا يفعل شيئاً.
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _controller.clear();
                              context.read<SearchCubit>().clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'مسح',
                          ),
                        IconButton(
                          onPressed: () => unawaited(_openScanner()),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          tooltip: 'مسح الباركود',
                          color: TintColors.charcoal,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_preferences.recentSearches.isNotEmpty) ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'عمليات البحث الأخيرة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _preferences.clearRecentSearches();
                          setState(() {});
                        },
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.recentSearches
                        .map(
                          (item) => ActionChip(
                            label: Text(item),
                            onPressed: () {
                              _controller.text = item;
                              context
                                  .read<SearchCubit>()
                                  .search(item, preferences: _preferences);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          itemCount: state.results.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            return ProductCard(product: state.results[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
