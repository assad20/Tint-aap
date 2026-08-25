package com.tintstore.app

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import java.util.Locale

/**
 * ‼️ **تُفرَض العربيّة على سياق أندرويد نفسه، لا على Flutter وحده.**
 *
 * `MaterialApp` تفرض `Locale('ar')` — وهي تحكم ما ترسمه Flutter لا غير. أمّا
 * المكوّنات **الأصليّة** فتقرأ لغة الجهاز:
 *
 * · **خرائط جوجل** تكتب أسماء الشوارع والأحياء بلغة النظام — فعلى هاتفٍ
 *   إنجليزيّ تظهر «King Fahd Rd» بينما التطبيق كلّه عربيّ. وهذا أوّل ما
 *   يُقارَن بمنافسٍ تظهر خريطته عربيّةً دائماً.
 * · ونوافذ الأذونات ورسائل النظام: المِثل.
 *
 * والتطبيق عربيٌّ بالكامل ولا يعرض لغةً أخرى، فلا معنى لأن يتبع لغة الجهاز.
 *
 * ‼️ ويُضبَط في `attachBaseContext` **قبل** إنشاء أيّ شيء: ضبطُه بعده يُنتج
 * مكوّناتٍ وُلدت بلغةٍ وأخرى بلغةٍ ثانية في الشاشة الواحدة.
 */
class MainActivity : FlutterActivity() {
    override fun attachBaseContext(newBase: Context) {
        val arabic = Locale("ar")
        Locale.setDefault(arabic)
        val configuration = Configuration(newBase.resources.configuration)
        configuration.setLocale(arabic)
        super.attachBaseContext(newBase.createConfigurationContext(configuration))
    }
}
