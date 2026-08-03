import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TintApp extends StatelessWidget {
  const TintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tint Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      locale: const Locale('ar'),
      /**
       * ‼️ كان التطبيق يفرض `Locale('ar')` بلا أيّ مُفوَّض ترجمة، فلا يعرف
       * Material العربيّة إطلاقاً — ولا يظهر أثر ذلك إلّا حين يطلب ودجت
       * ترجماتٍ فعليّة. ومنتقي التاريخ يطلبها: كان يفتح شاشةً رماديّةً تتجمّد
       * ولا تُغلق، لأنّه ينتظر ترجمةً لا تصل. (شوهد في «تاريخ الميلاد» عند
       * الدفع بتابي.)
       *
       * والقائمة تبدأ بالعربيّة: أوّل عنصرٍ هو ما يُرتَدّ إليه عند لغةٍ غير
       * مدعومة، فيبقى الارتداد عربيّاً لا إنجليزيّاً.
       */
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // تثبيت مقياس الخط ضمن نطاق آمن حتى لا يكسر إعداد النظام التخطيط
        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.2,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
