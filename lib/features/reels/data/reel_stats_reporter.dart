import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

/// عدّاد مشاهدات المقاطع الترويجيّة ونقراتها.
///
/// ‼️ **يُرسل عدّاداتٍ مجمّعة لا أحداثاً خام** — ويستعمل نقطة قياس المكوّنات
/// القائمة (`/catalog/sdui-events`) بمفتاح `reel:<id>` بدل نقطةٍ ثانية. فيرث
/// منها ما دُفع ثمنه سلفاً: التجميع الذرّيّ بـ`$inc`، وحدَّ المعدّل، وحذفَ
/// السجلّ بعد ١٨٠ يوماً، وخلوَّه من أيّ مُعرّف زائر.
///
/// ‼️ **والمقاطع الترويجيّة وحدها تُقاس، لا مقاطع المنتجات.** وثيقةٌ لكلّ
/// (يوم · منتج) مع كتالوجٍ بألفي منتج تعني مئات الآلاف من الوثائق في نافذة
/// الاحتفاظ — وهو عين التضخّم الذي أسقط هذه القاعدة مرّتين. والترويج معدودٌ
/// بالأصابع، فقياسه لا يكلّف شيئاً ويُجيب عن السؤال المطلوب.
class ReelStatsReporter {
  ReelStatsReporter(this._api);

  final ApiClient _api;

  /// ما لم يُرسَل بعد: مُعرّف المقطع ← (مشاهدات · نقرات).
  final Map<String, _ReelCounts> _pending = <String, _ReelCounts>{};

  Timer? _timer;

  /// ‼️ **لا تُرسَل كلّ مشاهدةٍ وحدها.** المستخدم يمرّ على عشرة مقاطع في دقيقة،
  /// وعشر رحلاتٍ إلى خادمٍ في منطقةٍ أخرى ثمنٌ يدفعه من بطاريّته وشبكته مقابل
  /// رقمٍ لا يُقرأ إلّا بعد ساعات. فتُجمَّع وتُرسَل دفعةً كلّ خمس ثوانٍ.
  static const Duration _window = Duration(seconds: 5);

  void view(String reelId) => _add(reelId, views: 1);

  void click(String reelId) => _add(reelId, clicks: 1);

  void like(String reelId) => _add(reelId, likes: 1);

  void share(String reelId) => _add(reelId, shares: 1);

  /// طلبٌ يُنسَب إلى مقطع — **يُرسَل فوراً لا مع الدفعة.**
  ///
  /// ‼️ لحظة نجاح الطلب يغادر المستخدم الشاشة غالباً، ودفعةٌ تنتظر خمس ثوانٍ
  /// كانت تُفقَد. وهو حدثٌ نادر (طلبٌ لا مشاهدة) فلا كلفة في إفراده.
  Future<void> order(String reelId, double value) async {
    final id = reelId.trim();
    if (id.isEmpty) return;
    try {
      await _api.postMap('/catalog/sdui-events', data: {
        'events': [
          {
            'listName': 'reel:$id',
            'sectionType': 'reel',
            'type': 'order',
            'count': 1,
            'value': value.round(),
          },
        ],
      });
    } catch (error) {
      debugPrint('[reels] تعذّر إرسال نسبة الطلب: $error');
    }
  }

  void _add(
    String reelId, {
    int views = 0,
    int clicks = 0,
    int likes = 0,
    int shares = 0,
  }) {
    final id = reelId.trim();
    if (id.isEmpty) return;

    final entry = _pending.putIfAbsent(id, _ReelCounts.new);
    entry.views += views;
    entry.clicks += clicks;
    entry.likes += likes;
    entry.shares += shares;

    _timer ??= Timer(_window, flush);
  }

  /// يُفرغ ما تجمّع — يُستدعى عند مغادرة الشريط كي لا تضيع آخر دفعة.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) return;

    final batch = Map<String, _ReelCounts>.from(_pending);
    _pending.clear();

    final events = <Map<String, dynamic>>[];
    batch.forEach((id, counts) {
      if (counts.views > 0) {
        events.add(_event(id, 'impression', counts.views));
      }
      if (counts.clicks > 0) {
        events.add(_event(id, 'click', counts.clicks));
      }
      if (counts.likes > 0) {
        events.add(_event(id, 'like', counts.likes));
      }
      if (counts.shares > 0) {
        events.add(_event(id, 'share', counts.shares));
      }
    });
    if (events.isEmpty) return;

    try {
      await _api.postMap('/catalog/sdui-events', data: {'events': events});
    } catch (error) {
      /// ‼️ **لا يُعاد الإرسال ولا تُسقَط الشاشة.** رقمٌ ناقص في تقريرٍ تشغيليّ
      /// أهون من طابور إعادةٍ ينمو في ذاكرة جهازٍ على شبكةٍ منقطعة.
      debugPrint('[reels] تعذّر إرسال القياس: $error');
    }
  }

  Map<String, dynamic> _event(String reelId, String type, int count) => {
        'listName': 'reel:$reelId',
        'sectionType': 'reel',
        'type': type,
        'count': count,
      };
}

class _ReelCounts {
  int views = 0;
  int clicks = 0;
  int likes = 0;
  int shares = 0;
}
