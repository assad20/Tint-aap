import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

/// يجمع أحداث ظهور المكوّنات ونقراتها ويُرسلها دفعاتٍ (المهمّة 5.1).
///
/// ‼️ **دفعاتٌ لا نداءٌ لكلّ حدث.** تمريرةٌ واحدة على الرئيسيّة تُنتج عشرة
/// أحداث، وعشرة نداءات لكلّ زائرٍ تجعل **القياس أثقل من المحتوى الذي يقيسه** —
/// ويستهلك بطّاريّةً وباقةً لأجل أرقامٍ في تقرير.
///
/// ‼️ **ولا يرمي ولا يُبلّغ المستخدم أبداً.** فشلُ إرسال قياسٍ حدثٌ لا يعني
/// شيئاً للمشتري، وإظهارُه له عطلٌ مُختلَق.
class SduiTracker with WidgetsBindingObserver {
  SduiTracker(this._api);

  final ApiClient _api;

  final Map<String, _Counter> _pending = {};
  Timer? _timer;

  /// ‼️ الظهور يُسجَّل **مرّةً لكلّ مكوّن في عمر التطبيق** لا في كلّ تمريرة.
  /// وبدون هذا، تمريرةٌ صعوداً ونزولاً تُضاعف رقم الرفّ الأعلى عشر مرّات —
  /// فيبدو أفضل مكوّنٍ في التقرير لأنّه في أعلى الشاشة لا لأنّه يُشاهَد.
  final Set<String> _seen = {};

  static const Duration _flushAfter = Duration(seconds: 5);
  static const int _flushAt = 20;

  void start() => WidgetsBinding.instance.addObserver(this);

  void recordImpression(String? listName, String? sectionType) {
    final key = listName?.trim() ?? '';
    if (key.isEmpty || !_seen.add(key)) return;
    _bump(key, sectionType, impression: true);
  }

  /// ‼️ **النقرة تُسجَّل في كلّ مرّة** بخلاف الظهور: تكرار النقر على الرفّ نفسه
  /// إشارةُ اهتمامٍ حقيقيّة، لا ضجيجَ تمرير.
  void recordClick(String? listName, String? sectionType) {
    final key = listName?.trim() ?? '';
    if (key.isEmpty) return;
    _bump(key, sectionType, impression: false);
  }

  void _bump(String listName, String? sectionType, {required bool impression}) {
    final counter = _pending.putIfAbsent(listName, () => _Counter(sectionType));
    if (impression) {
      counter.impressions++;
    } else {
      counter.clicks++;
    }

    if (_pending.length >= _flushAt) {
      unawaited(flush());
      return;
    }
    _timer ??= Timer(_flushAfter, () => unawaited(flush()));
  }

  /// ‼️ **يُفرَّغ عند خروج التطبيق من المقدّمة.** أغلبُ الجلسات تنتهي بالخروج لا
  /// بانتهاء مؤقّت، وبلا هذا تضيع أحداث آخر خمس ثوانٍ من كلّ جلسة — وهي
  /// الثواني التي يقع فيها القرار عادةً.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) return;

    // ‼️ تُنتزَع قبل الإرسال: حدثٌ يقع أثناء الرحلة يدخل الدفعة التالية ولا
    //    يُفقَد ولا يُرسَل مرّتين.
    final batch = Map<String, _Counter>.from(_pending);
    _pending.clear();

    final events = <Map<String, dynamic>>[];
    batch.forEach((listName, counter) {
      if (counter.impressions > 0) {
        events.add({
          'listName': listName,
          'sectionType': counter.sectionType,
          'type': 'impression',
          'count': counter.impressions,
        });
      }
      if (counter.clicks > 0) {
        events.add({
          'listName': listName,
          'sectionType': counter.sectionType,
          'type': 'click',
          'count': counter.clicks,
        });
      }
    });

    if (events.isEmpty) return;

    try {
      await _api.postMap(ApiRoutes.sduiEvents, data: {'events': events});
    } catch (error) {
      // ‼️ لا إعادة إرسال: طابورٌ يُعاد بلا حدٍّ ينمو بلا سقف على جهازٍ بلا
      //    شبكة، والقياس ليس بياناتٍ ماليّة تُبرّر ذلك. حدثٌ ضائع مقبول.
      debugPrint('[sdui] تعذّر إرسال القياس: $error');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}

class _Counter {
  _Counter(this.sectionType);
  final String? sectionType;
  int impressions = 0;
  int clicks = 0;
}
