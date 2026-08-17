import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/app_preferences.dart';

/// هل في شريط المقاطع جديدٌ لم يُشاهَد؟ — تُغذّي نبضة الشعار في الشريط السفليّ.
///
/// ‼️ **الحركة مربوطةٌ بحالةٍ حقيقيّة، لا دائمة.** نبضةٌ لا تنقطع يتعلّم النظر
/// تجاهلها خلال يومين فتصير كالسكون، ثمّ لا يبقى للمتجر ما يقول به «انظر هنا».
/// فتنبض متى وصل مقطعٌ جديد وتسكن متى فُتح الشريط.
///
/// ‼️ **والمقارنة بمُعرّف الأحدث لا بعدد المقاطع.** العدد يبقى كما هو حين
/// يُستبدل مقطعٌ بمقطع — فيضيف المالك ترويجاً جديداً ولا ينبض شيء.
///
/// ‼️ **والصنف نفسه ليس `Listenable`** بل يحمل واحداً: `RepositoryProvider`
/// يرفض تسجيل أيّ `Listenable` عمداً — كي لا يُوضع في الشجرة ثمّ يُنسى الإصغاء
/// إليه فتبقى الواجهة ساكنةً بلا خطأ يدلّ على السبب. (رُصد بالتشغيل.)
class ReelBadge {
  ReelBadge({required ApiClient api, required AppPreferences preferences})
      : _api = api,
        _preferences = preferences;

  final ApiClient _api;
  final AppPreferences _preferences;

  String _latestId = '';

  /// ‼️ يبدأ `false` ولا يُخمَّن: علامةٌ تظهر ثمّ تختفي بعد أوّل ردٍّ من الخادم
  /// أسوأ من علامةٍ تتأخّر ثانية.
  final ValueNotifier<bool> hasNew = ValueNotifier<bool>(false);

  void _recompute() {
    hasNew.value = _latestId.isNotEmpty && _latestId != _preferences.seenReelId;
  }

  /// يُسأل عند الإقلاع — والفشل يُبقي الحال كما هو.
  Future<void> refresh() async {
    try {
      final data = await _api.getMap('/catalog/reels/latest');
      _latestId = (data['promoId'] ?? '').toString().trim();
      _recompute();
    } catch (error) {
      /// ‼️ **صمتٌ مقصود.** تعذّر معرفة «هل يوجد جديد» ليس خطأً يُعرَض للمشتري،
      /// وأسوأ أثرٍ له نبضةٌ لا تظهر هذه المرّة.
      debugPrint('[reels] تعذّرت قراءة علامة الجديد: $error');
    }
  }

  /// يُستدعى لحظة فتح الشريط — فتسكن النبضة فوراً بلا انتظار كتابةٍ على القرص.
  Future<void> markSeen() async {
    if (_latestId.isEmpty) return;
    hasNew.value = false;
    await _preferences.setSeenReelId(_latestId);
  }
}
