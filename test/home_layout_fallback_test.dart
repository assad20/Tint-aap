import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/core/network/api_exception.dart';
import 'package:tint_mobile/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:tint_mobile/features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'package:tint_mobile/features/catalog/domain/entities/home_layout_fetch.dart';

/// مصدرٌ بعيدٌ مزيّف: يُعيد ما يُملى عليه أو يرمي ما يُملى عليه.
class _FakeRemote implements CatalogRemoteDataSource {
  _FakeRemote({this.layout, this.error});

  final Map<String, dynamic>? layout;
  final Object? error;

  @override
  Future<Map<String, dynamic>> fetchAppHomeLayout() async {
    if (error != null) throw error!;
    return layout!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('لا يُنادى في هذا الاختبار: ${invocation.memberName}');
}

Map<String, dynamic> _page({required bool withSection}) => {
      'id': 'home',
      'slug': 'home',
      'title': 'الرئيسيّة',
      'sections': withSection
          ? [
              {
                'id': 's1',
                'type': 'rich_text',
                'enabled': true,
                'position': 0,
                'settings': {'text': 'مرحباً'},
                'items': const [],
              }
            ]
          : const [],
    };

Future<HomeLayoutFetch> _fetch({Map<String, dynamic>? layout, Object? error}) {
  final repo = CatalogRepositoryImpl(
    remoteDataSource: _FakeRemote(layout: layout, error: error),
  );
  return repo.fetchAppHomeLayout();
}

/// **رئيسيّةٌ حُذفت من اللوحة يجب أن تُعيد الجهاز إلى الرئيسيّة الرسميّة.**
///
/// ‼️ **ولماذا اختبارٌ لهذا تحديداً؟** لأنّ الخطأ الذي عولج كان *تبسيطاً يبدو
/// سليماً*: `catch (_) => null` تجمع «حُذفت» و«الشبكة مقطوعة» في قيمةٍ واحدة،
/// والسلوك المطلوب فيهما **متعاكس**. وبلا حارسٍ مكتوب يعود هذا التبسيط في أوّل
/// إعادة كتابة — والعطل صامتٌ تماماً: لا خطأ في أيّ سجلّ، والأجهزة التي لم ترَ
/// الصفحة قطّ تبدو سليمة، فيختلف جهازان في المتجر نفسه بلا سببٍ ظاهر.
void main() {
  group('تخطيط الرئيسيّة — الحالات الثلاث', () {
    test('تخطيطٌ فيه أقسام ⇒ ok ويحمل الخام', () async {
      final result = await _fetch(layout: _page(withSection: true));
      expect(result.status, HomeLayoutStatus.ok);
      expect(result.raw, isNotNull);
      // خامٌ لا مُحلَّل: يُخزَّن نصّاً ويُعاد تقييم `minAppVersion` كلّ إقلاع.
      expect(CmsPageModel.fromJson(result.raw!).sections, hasLength(1));
    });

    test('‼️ ٤٠٤ (حُذفت من اللوحة) ⇒ none — حكمٌ لا عُطل', () async {
      final result = await _fetch(error: ApiException('not found', statusCode: 404));
      expect(result.status, HomeLayoutStatus.none);
      expect(result.raw, isNull);
    });

    test('صفحةٌ بلا قسمٍ تعرضه هذه النسخة ⇒ none لا شاشةٌ بيضاء', () async {
      final result = await _fetch(layout: _page(withSection: false));
      expect(result.status, HomeLayoutStatus.none);
    });

    test('‼️ ٥٠٠ ومهلةٌ وانقطاع ⇒ unavailable — يبقى المعروض', () async {
      for (final error in <Object>[
        ApiException('server', statusCode: 500),
        ApiException('gateway', statusCode: 502),
        ApiException('offline'), // بلا رمز حالة أصلاً
        Exception('جسمٌ تالف'),
      ]) {
        final result = await _fetch(error: error);
        expect(
          result.status,
          HomeLayoutStatus.unavailable,
          reason: 'عُطلٌ مؤقّت لا يجوز أن يمحو تخطيط اللوحة: $error',
        );
      }
    });

    test('ولا حالة تحمل خاماً إلّا ok', () async {
      for (final result in [
        await _fetch(error: ApiException('x', statusCode: 404)),
        await _fetch(error: ApiException('x', statusCode: 500)),
        await _fetch(layout: _page(withSection: false)),
      ]) {
        expect(result.raw, isNull);
      }
    });
  });
}
