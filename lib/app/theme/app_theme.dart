import 'package:flutter/material.dart';

class TintColors {
  static const charcoal = Color(0xFF353B43);
  static const sand = Color(0xFFC59C8F);
  static const cream = Color(0xFFFDFBF7);
  static const blush = Color(0xFFFFF8F6);
  static const line = Color(0xFFEEF0F2);
  static const textMuted = Color(0xFF8A8F98);
  static const success = Color(0xFF1F9D55);
  static const danger = Color(0xFFE53935);
  static const warning = Color(0xFFFB8C00);
  static const tintOrange = Color(0xFFF97316);
  static const tintYellow = Color(0xFFFFC107);

  /// أحمر السعر واسم العلامة في بطاقة المنتج.
  ///
  /// ‼️ **نفس درجة شارة الخصم عمداً** — فتُقرأ البطاقة وحدةً واحدةً بدل ثلاثة
  /// حمرٍ متقاربة تبدو خطأً في التصميم.
  ///
  /// ‼️ **ومنفصلٌ عن `danger` في الاسم رغم تطابق القيمة اليوم**: هذا تسعيرٌ
  /// وذاك خطأ. ولو وُحِّدا لجرّ أوّلُ تعديلٍ على لون رسائل الخطأ أسعارَ المتجر
  /// كلَّها معه — وهو آخر ما يخطر ببال من يعدّل لون خطأ.
  static const price = Color(0xFFE53935);

  /// أزرق اسم العلامة التجاريّة.
  ///
  /// ‼️ **لونٌ ثالثٌ لأنّ السعر يجب أن يفوز.** كان الاسم والسعر أحمرين معاً،
  /// فصار في البطاقة ثلاثةُ أحمر — الشارة والسعر والعلامة — ولا تعرف العين
  /// أيّها القرار. الأحمر للسعر وحده، والاسم لونٌ يفصله عنه.
  ///
  /// ‼️ **وليس أخضر عمداً**: الأخضر إشارةُ التوفّر («متوفّر» في صفحة المنتج)،
  /// وتكرارُه على اسمٍ لا علاقة له بالمخزون يُفرغ الإشارة من معناها.
  ///
  /// ودرجةٌ مكسورةٌ لا زرقةٌ صريحة: تكفي للقراءة عند ١٠ نقاط وتبقى تسميةً
  /// ثانويّة، ولا تنافس السعر فوقها.
  static const brand = Color(0xFF2B5FA8);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      // خطّ التطبيق كلّه — عربيّ مُحزَّم بدل خطّ النظام (انظر pubspec.yaml).
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TintColors.sand,
        primary: TintColors.sand,
        secondary: TintColors.charcoal,
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      dividerColor: TintColors.line,
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        foregroundColor: TintColors.charcoal,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE7E8EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TintColors.sand),
        ),
        hintStyle: const TextStyle(
          color: TintColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: TintColors.line),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: TintColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
