/// إعدادات القياس كما يُصدرها الوسيط — `GET /v1/tracking/config`.
///
/// ‼️ **مقروءةٌ من `docs/app-tracking-contract.md` حرفيّاً**، وهي المرجع الملزم
/// للطرفين. وما ليس فيها لا يُخمَّن.
///
/// ‼️ **ولا سرّ فيها بالتصميم**: التطبيق يُشحَن إلى أجهزة الناس، ويكفي اعتراض
/// نداءٍ واحد بأداةٍ مجّانيّة لقراءة كلّ ما يمرّ. فما هنا **علنيٌّ بطبيعته**
/// (مُعرّفات تُرسَل في كلّ صفحة ويب أصلاً)، والحماية في ألّا يحوي الردّ سرّاً
/// لا في إخفائه.
class TrackingConfig {
  const TrackingConfig({
    required this.storeId,
    required this.channelEnabled,
    required this.consentRequired,
    required this.requestAtt,
    required this.platforms,
  });

  final String storeId;

  /// ‼️ **`false` ⇒ لا يُرسَل شيء إطلاقاً.** متجرٌ لم تُفعَّل قناة تطبيقه.
  final bool channelEnabled;

  /// ‼️ **دائماً `true` في العقد** — والحقل موجودٌ لأنّ التطبيق لا يفترض،
  /// يقرأ. ولو عاد `false` يوماً فذاك قرار الخادم لا اجتهاد الجهاز.
  final bool consentRequired;

  /// ‼️ **iOS فقط، ولا تُطلَب النافذة إن كانت `false`.** نافذةٌ تظهر بلا سببٍ
  /// تُرفَض غالباً، **وتُحرَق الفرصة الوحيدة لطلبها** — فآبل لا تسمح بعرضها
  /// مرّةً ثانية أبداً.
  final bool requestAtt;

  /// المنصّات المفعَّلة لقناة التطبيق بمعرّفاتها العلنيّة.
  ///
  /// ‼️ **قد تعود فارغة** — متجرٌ لم تُهيّأ منصّاته. وحينها لا يُهيَّأ أيّ SDK:
  /// تهيئةٌ بمعرّفٍ فارغ تُسجّل أحداثاً لا تصل أحداً، **ويبدو كلّ شيءٍ سليماً**.
  final List<String> platforms;

  /// ‼️ **افتراضٌ آمن عند تعذّر القراءة: القناة مُطفأة.**
  ///
  /// شبكةٌ منقطعة أو ردٌّ معطوب لا يعنيان «أرسِل على أيّ حال». والصمت خسارةُ
  /// قياسٍ ليوم؛ والإرسال بلا إعدادات قد يعني إرسالاً لمتجرٍ خاطئ أو بلا موافقة.
  static const TrackingConfig disabled = TrackingConfig(
    storeId: '',
    channelEnabled: false,
    consentRequired: true,
    requestAtt: false,
    platforms: <String>[],
  );

  factory TrackingConfig.fromJson(Map<String, dynamic> json) {
    final channel = json['channel'];
    final consent = json['consent'];
    final platforms = json['platforms'];

    return TrackingConfig(
      storeId: (json['storeId'] ?? '').toString(),
      channelEnabled: channel is Map && channel['enabled'] == true,
      // ‼️ الغياب يُقرأ «مطلوبة» لا «غير مطلوبة»: الخطأ في اتّجاه الحماية.
      consentRequired: consent is Map ? consent['required'] != false : true,
      requestAtt: consent is Map && consent['requestAtt'] == true,
      platforms: platforms is List
          ? platforms
              .whereType<Map>()
              .map((row) => (row['platform'] ?? '').toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
    );
  }

  /// هل يُقاس أصلاً؟ قناةٌ مُطفأة أو بلا منصّات = لا تهيئة.
  bool get isMeasurable => channelEnabled && platforms.isNotEmpty;
}
