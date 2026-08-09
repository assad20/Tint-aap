import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/api_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/tint_ui.dart';
import 'product_detail_page.dart';

/// يفتح صفحة منتجٍ **بمعرّفه** — وجهة `tint://product/<id>` (المهمّة 3.3).
///
/// ‼️ **لماذا شاشةٌ وسيطة؟** مسار `/product` القائم يستقبل كائن المنتج جاهزاً
/// (`extra`) لأنّه يُفتَح من بطاقةٍ تحمله سلفاً. ورابطٌ خارجيّ لا يحمل إلّا
/// معرّفاً — فبلا هذه الشاشة كان الرابط يفتح «المنتج غير متاح» **على منتجٍ
/// موجود**، وهو أسوأ من ألّا يفتح شيئاً.
///
/// ‼️ **ولا تُعيد بناء صفحة المنتج**: تجلب ثمّ تُسلّم إلى `ProductDetailPage`
/// نفسها. نسخةٌ ثانية كانت ستنحرف في السعر والمقاسات وزرّ السلّة.
class ProductByIdPage extends StatefulWidget {
  const ProductByIdPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductByIdPage> createState() => _ProductByIdPageState();
}

class _ProductByIdPageState extends State<ProductByIdPage> {
  ProductModel? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await context
          .read<ApiClient>()
          .getMap('${ApiRoutes.catalogProducts}/${Uri.encodeComponent(widget.productId)}');
      final raw = data['product'];
      if (raw is! Map) {
        throw StateError('لا منتج في الاستجابة');
      }
      if (!mounted) return;
      setState(() {
        _product = ProductModel.fromJson(Map<String, dynamic>.from(raw));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // ‼️ رسالةٌ واحدة للحالتين — «غير موجود» و«تعذّر الاتّصال»: العميل لا
        //    يملك فعلاً مختلفاً لكلٍّ منهما، وتفصيلُهما يُقلق بلا فائدة.
        //    والفرق يهمّ المطوّر، وهو في السجلّ.
        _error = 'تعذّر فتح هذا المنتج';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product != null) {
      return ProductDetailPage(product: product);
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'تعذّر فتح هذا المنتج',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: TintColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ‼️ «حاول ثانيةً» لا رجوعٌ فقط: أغلب الأسباب عابرة (شبكة
                    //    عند الفتح من إشعارٍ أو رسالة)، وإخراجُ المستخدم من
                    //    المنتج يعني فقدان الزيارة كلّها.
                    FilledButton(onPressed: _load, child: const Text('حاول ثانيةً')),
                  ],
                ),
              ),
      ),
    );
  }
}
