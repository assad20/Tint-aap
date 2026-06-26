# Tint Store Mobile (Flutter)

مشروع Flutter احترافي لمتجر **Tint Store** مبني على:
- Clean Architecture / Feature-first
- `flutter_bloc` لإدارة الحالة
- `go_router` للملاحة
- `dio` للشبكات
- `flutter_secure_storage` لحفظ التوكن
- `shared_preferences` لتفضيلات محلية خفيفة

## قاعدة الربط الشبكي
التطبيق **لا يتصل بـ Odoo مباشرة**.
جميع طلبات الشبكة تمر فقط عبر **Node.js Middleware** من خلال:

- `GET /catalog/bootstrap`
- `GET /catalog/trends`
- `GET /catalog/search?q=...`
- `GET /me/dashboard`
- `GET /me/rewards`
- `GET /me/orders`
- `GET /me/favorites`
- `GET /me/addresses`
- `POST /orders/checkout`
- `POST /assistant/chat`

> يمكن تعديل المسار الأساسي من خلال:
```bash
flutter run --dart-define=TINT_API_BASE_URL=http://10.0.2.2:3000/api
```

## تشغيل المشروع
```bash
flutter pub get
flutter run --dart-define=TINT_API_BASE_URL=http://10.0.2.2:3000/api
```

## الهيكل العام
```text
lib/
├─ app/
│  ├─ config/
│  ├─ router/
│  └─ theme/
├─ core/
│  ├─ models/
│  ├─ network/
│  ├─ storage/
│  ├─ utils/
│  └─ widgets/
└─ features/
   ├─ account/
   ├─ assistant/
   ├─ cart/
   ├─ catalog/
   ├─ checkout/
   └─ shell/
```

## ما تم تحويله من واجهة React
- الصفحة الرئيسية مع التبويبات العليا
- الترندات
- الأقسام
- السلة
- إتمام الطلب
- الملف الشخصي
- النقاط والمكافآت
- الكوبونات
- المحفظة
- الطلبات + تفاصيل الطلب
- المفضلة
- العناوين + إضافة/تعديل
- طرق الدفع
- سجل التصفح
- المقاسات
- بطاقات الهدايا
- تنبيهات التوفر
- البحث
- مستشار Tint الذكي

## ملاحظة تنفيذية
تمت إضافة **fallback seed data** حتى يعمل التطبيق بصريًا حتى قبل اكتمال كل endpoints في الـ middleware، لكن أي محاولة API حقيقية ما زالت تُوجّه إلى السيرفر الوسيط فقط.
