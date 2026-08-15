import 'package:flutter/foundation.dart';

import '../../../app/config/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/reel_model.dart';

/// صفحةٌ من شريط الفيديو.
class ReelsPage {
  const ReelsPage({required this.items, required this.hasMore, this.failed = false});

  final List<ReelModel> items;
  final bool hasMore;

  /// ‼️ **يُفرَّق الفشل عن الفراغ.** كلاهما ينتهي بقائمةٍ خالية، ورسالةٌ واحدة
  /// لهما تعني أنّ منفذاً معطّلاً يُقرأ «لا مقاطع في المتجر» — فلا يُبلَّغ عنه
  /// أحد ولا يُصلَح. (وقع فعلاً عند أوّل تشغيل: المنفذ لم يُنشر بعد.)
  final bool failed;

  static const empty = ReelsPage(items: <ReelModel>[], hasMore: false, failed: true);
}

class ReelsRepository {
  const ReelsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// ‼️ **لا يرمي**: الشريط شاشةُ ترفيهٍ لا تدفّقُ شراء، وسقوطُها بخطأٍ أحمر
  /// على انقطاعٍ لحظيّ أسوأ من صفحةٍ فارغة تُعيد المحاولة. والخطأ يُطبع للمطوّر.
  Future<ReelsPage> fetch({int page = 1, int limit = 8}) async {
    try {
      final data = await _apiClient.getMap(
        ApiRoutes.catalogReels,
        queryParameters: {'page': page, 'limit': limit},
      );
      final rows = data['items'];
      final items = <ReelModel>[];
      if (rows is List) {
        for (final row in rows) {
          final reel = ReelModel.fromJson(row);
          if (reel != null) items.add(reel);
        }
      }
      return ReelsPage(items: items, hasMore: data['hasMore'] == true);
    } catch (error) {
      debugPrint('[reels] تعذّر تحميل الصفحة $page: $error');
      return ReelsPage.empty;
    }
  }
}
