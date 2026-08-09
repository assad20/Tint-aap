import 'package:flutter/foundation.dart';

import '../utils/app_version.dart';

/// قسمٌ واحد من تخطيطٍ تصنعه لوحة التحكّم.
///
/// ‼️ **لا يحمل `schedule` ولا `visibility`** عمداً. الخادم يُرشّح بهما قبل أن
/// يُرسل (`isSectionActive`: الجدولة والقناة والجمهور والتفعيل)، فتكرارُهما هنا
/// يعني منطق ترشيحٍ ثانياً ينحرف عن الأوّل — وعندها يرى الويب شيئاً والتطبيق
/// شيئاً آخر من نفس الوثيقة. المبدأ الرابع في الخطّة: **المنطق في الخادم
/// والمكوّن غبيّ.**
///
/// والاستثناء الوحيد `minAppVersion`: لا يستطيع الخادم تطبيقه لأنّه لا يعرف
/// نسخة التطبيق الطالب — لا ترويسة تحملها اليوم.
@immutable
class CmsSectionModel {
  const CmsSectionModel({
    required this.id,
    required this.type,
    this.label = '',
    this.title,
    this.subtitle,
    this.position = 0,
    this.minAppVersion,
    this.listName,
    this.settings = const <String, dynamic>{},
    this.items = const <Map<String, dynamic>>[],
  });

  final String id;

  /// اسم النوع كما في `CmsSectionType` بالخادم (`product_carousel`, `hero`, …).
  /// ‼️ يُستعمل كما ورد بلا ترجمةٍ إلى قاموسٍ محلّيّ — «اسمٌ واحد لكلّ مكوّن».
  final String type;

  final String label;
  final String? title;
  final String? subtitle;
  final int position;

  /// أدنى إصدار تطبيقٍ يفهم هذا المكوّن. `null` = كلّ الإصدارات.
  final String? minAppVersion;

  /// مفتاح القياس كما يُصدره الخادم (`product_carousel:sec-1`) — المهمّة 1.4.
  ///
  /// ‼️ **يُشتقّ في الخادم ولا يُبنى هنا.** الويب والتطبيق يعرضان نفس القسم،
  /// ولو اشتقّ كلٌّ مفتاحه لظهر رفٌّ واحد باسمين في التقرير فتُقسَم أرقامه.
  /// وغيابُه يعني «لا تقس» لا «اخترع مفتاحاً».
  final String? listName;

  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> items;

  /// هل تعرض هذه النسخة هذا المكوّن؟ (المهمّة 2.3 — تجاهلٌ صامت للأقدم)
  bool get isSupportedByThisApp => supportsMinVersion(minAppVersion);

  /// يُحلّل قسماً واحداً، ويُعيد `null` إن كان تالفاً — **فيسقط وحده**.
  ///
  /// ‼️ **الرمي ممنوع هنا.** استثناءٌ واحد أثناء تحليل قسمٍ في وسط القائمة كان
  /// سيُسقط الصفحة كلّها، فيرى العميل شاشةً فارغة بسبب حقلٍ واحد أخطأ فيه
  /// المحرّر. والفشل اللطيف قاعدةٌ لا استثناء (المبدأ الثاني).
  static CmsSectionModel? tryParse(dynamic raw, {int fallbackPosition = 0}) {
    try {
      if (raw is! Map) {
        debugPrint('[sdui] قسمٌ ليس كائناً ⇒ أُسقط: ${raw.runtimeType}');
        return null;
      }
      final json = Map<String, dynamic>.from(raw);

      /// ‼️ **نصٌّ لا `toString()`.** الاسم يُطابَق بـ`CmsSectionType` في
      /// الخادم، فقيمةٌ رقميّة تصير `"42"` وتمرّ كأنّها نوعٌ مجهول — فيُخفيها
      /// سجلّ المكوّنات (2.2) بصمتٍ ويضيع أنّ الحقل **تالف** لا أنّ النوع جديد.
      /// وهما حالتان مختلفتان: الأولى بياناتٌ خطأ، والثانية نسخةٌ قديمة.
      final rawType = json['type'];
      final type = rawType is String ? rawType.trim() : '';
      if (type.isEmpty) {
        debugPrint('[sdui] قسمٌ بلا نوعٍ نصّيّ ⇒ أُسقط: id=${json['id']} type=$rawType');
        return null;
      }

      final id = json['id']?.toString().trim() ?? '';

      return CmsSectionModel(
        // مُعرّفٌ اشتقاقيّ عند غيابه: يُستعمل مفتاحاً للودجة وللقياس، وتكرارُ
        // مفتاحٍ فارغ بين قسمين يُربك إعادة بناء القائمة في Flutter.
        id: id.isNotEmpty ? id : '$type#$fallbackPosition',
        type: type,
        label: json['label']?.toString() ?? '',
        title: _nonEmpty(json['title']),
        subtitle: _nonEmpty(json['subtitle']),
        position: _asInt(json['position']) ?? fallbackPosition,
        minAppVersion: _nonEmpty(json['minAppVersion']),
        listName: _nonEmpty(_asMap(json['analytics'])['listName']),
        settings: _asMap(json['settings']),
        items: _asMapList(json['items']),
      );
    } catch (error) {
      debugPrint('[sdui] تعذّر تحليل قسم ⇒ أُسقط: $error');
      return null;
    }
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

  /// ‼️ عنصرٌ تالف داخل القسم يسقط وحده ولا يُسقط القسم: رفٌّ فيه تسعة منتجات
  /// صحيحة وواحدٌ فاسد يُعرَض بتسعة، لا يختفي كلّه.
  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
