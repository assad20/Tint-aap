import 'package:flutter/foundation.dart';

/// عنصرُ تنقّلٍ من `/cms/public/app-navigation` (المهمّة 1.6).
///
/// الشكل مقيسٌ على النقطة الحيّة:
/// `id · label · labelEn · image · highlight · action{type,value} · children[]`
@immutable
class AppNavItem {
  const AppNavItem({
    required this.id,
    required this.label,
    required this.actionType,
    required this.actionValue,
    this.labelEn,
    this.image,
    this.highlight = false,
    this.icon,
    this.children = const <AppNavItem>[],
  });

  final String id;
  final String label;
  final String? labelEn;
  final String? image;
  final bool highlight;

  /// اسم الأيقونة كما يقوله الخادم للتبويبات (`home` · `grid` · …).
  /// ‼️ نصٌّ لا أيقونة: الخادم لا يعرف `IconData`، والتطبيق يُترجمه بما لديه.
  final String? icon;

  final String actionType;
  final String actionValue;
  final List<AppNavItem> children;

  /// ‼️ **لا يرمي** — عنصرٌ تالف يسقط وحده، تماماً كأقسام التخطيط.
  static AppNavItem? tryParse(dynamic raw, {int depth = 1}) {
    try {
      if (raw is! Map) return null;
      final json = Map<String, dynamic>.from(raw);

      final label = json['label']?.toString().trim() ?? '';
      if (label.isEmpty) return null;

      final action = json['action'] is Map
          ? Map<String, dynamic>.from(json['action'] as Map)
          : const <String, dynamic>{};

      // ‼️ حدٌّ للعمق هنا أيضاً لا في الخادم وحده: كاشٌ قديم قد يحمل شجرةً
      //    أعمق، وبناؤها يُجمّد الواجهة على شجرةٍ فيها آلاف المسارات.
      final children = depth >= 3
          ? const <AppNavItem>[]
          : (json['children'] is List ? json['children'] as List : const [])
              .map((child) => AppNavItem.tryParse(child, depth: depth + 1))
              .whereType<AppNavItem>()
              .toList(growable: false);

      return AppNavItem(
        id: json['id']?.toString().trim() ?? label,
        label: label,
        labelEn: _nonEmpty(json['labelEn']),
        image: _nonEmpty(json['image']),
        highlight: json['highlight'] == true,
        icon: _nonEmpty(json['icon']),
        actionType: action['type']?.toString().trim() ?? '',
        actionValue: action['value']?.toString().trim() ?? '',
        children: children,
      );
    } catch (error) {
      debugPrint('[sdui] عنصر تنقّلٍ تالف ⇒ أُسقط: $error');
      return null;
    }
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// تنقّل التطبيق كاملاً: القائمة الجانبيّة + التبويبات السفليّة.
@immutable
class AppNavigationModel {
  const AppNavigationModel({this.drawer = const [], this.bottomTabs = const []});

  final List<AppNavItem> drawer;
  final List<AppNavItem> bottomTabs;

  bool get isEmpty => drawer.isEmpty && bottomTabs.isEmpty;

  factory AppNavigationModel.fromJson(Map<String, dynamic> json) {
    List<AppNavItem> parse(dynamic raw) => (raw is List ? raw : const [])
        .map((item) => AppNavItem.tryParse(item))
        .whereType<AppNavItem>()
        .toList(growable: false);

    return AppNavigationModel(
      drawer: parse(json['drawer']),
      bottomTabs: parse(json['bottomTabs']),
    );
  }
}
