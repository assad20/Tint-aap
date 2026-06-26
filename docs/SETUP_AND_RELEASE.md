# دليل التهيئة والنشر — Tint Store

تم تجهيز ملفات الإعداد النصية لكل من Android و iOS مسبقاً (Bundle ID = `com.tintstore.app`،
اسم العرض = `Tint Store`). يبقى توليد الملفات الثنائية (gradle wrapper، مشروع Xcode، الأيقونات)
عبر أداة `flutter create`، ثم البناء.

---

## 1) توليد مجلدات المنصات (مرة واحدة)

الأمر التالي **لا يحذف** ملفات `lib/` ولا الإعدادات التي جهّزناها — يضيف فقط الملفات الناقصة:

```bash
flutter create . --org com.tintstore --platforms=android,ios
flutter pub get
```

> إن طُلب استبدال ملف موجود (مثل `AndroidManifest.xml` أو `Info.plist`)، **ارفض** للإبقاء
> على نسختنا المُهيّأة (التي تحوي صلاحيات Tabby والاسم العربي).

## 2) توليد الأيقونة وشاشة البداية

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

> أيقونة المصدر مؤقتة في `assets/icon/app_icon.png` — استبدلها بشعار Tint الحقيقي (1024×1024).

## 3) إعداد التوقيع

### Android
1. أنشئ مفتاح التوقيع مرة واحدة:
   ```bash
   keytool -genkey -v -keystore %USERPROFILE%\tint-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. انسخ `android/key.properties.example` إلى `android/key.properties` واملأ القيم.

### iOS
يتطلب حساب **Apple Developer** + جهاز Mac (أو Codemagic). التوقيع يُدار من Xcode أو Codemagic.

## 4) القيم المطلوبة وقت البناء

| المتغير | المثال | ملاحظة |
|---------|--------|--------|
| `TINT_API_BASE_URL` | `https://api.tintstore.com/api` | **HTTPS إلزامي** في الإنتاج |
| `TINT_TABBY_PUBLIC_KEY` | `pk_live_xxx` | مفتاح Tabby العام |
| `TINT_TABBY_MERCHANT_CODE` | `ksa_code` | كود التاجر |
| `TINT_TABBY_LANG` | `ar` | اللغة |

## 5) البناء النهائي

```bash
# Android (للنشر على Google Play)
flutter build appbundle --release \
  --dart-define=TINT_API_BASE_URL=https://api.tintstore.com/api \
  --dart-define=TINT_TABBY_PUBLIC_KEY=pk_live_xxx \
  --dart-define=TINT_TABBY_MERCHANT_CODE=ksa_code \
  --dart-define=TINT_TABBY_LANG=ar

# iOS (للنشر على App Store — يتطلب Mac أو Codemagic)
flutter build ipa --release --dart-define=... (نفس القيم)
```

## 6) البناء السحابي (بدون تثبيت محلي / بدون Mac)

- **معاينة الواجهة:** ارفع المشروع إلى [FlutLab.io](https://flutlab.io) أو [Zapp.run](https://zapp.run).
- **بناء للنشر:** اربط مستودع Git بـ [Codemagic](https://codemagic.io) — ملف `codemagic.yaml` جاهز
  في جذر المشروع ويبني Android (`.aab`) و iOS (`.ipa`).

---

## قائمة التحقق قبل النشر

- [ ] استبدال أيقونة المصدر بشعار Tint الحقيقي
- [ ] رابط API إنتاجي عبر HTTPS
- [ ] مفاتيح Tabby الحقيقية (`pk_live_`)
- [ ] إنشاء keystore وملف `key.properties` (Android)
- [ ] حساب Apple Developer + توقيع iOS
- [ ] رفع `usesCleartextTraffic="false"` (مضبوط مسبقاً في الإنتاج)
- [ ] حذف `NSAllowsLocalNetworking` من `Info.plist` قبل نسخة الإنتاج النهائية
- [ ] التأكد أن البيانات تأتي من الـ API الحقيقي وليس `fake_seed_data.dart`
- [ ] `flutter analyze` بلا أخطاء + رفع `versionCode`/`versionName` عند كل تحديث
