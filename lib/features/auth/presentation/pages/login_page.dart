import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/verification_channel.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.asSheet = false});

  /// تُعرَض ورقةً منبثقة (بوّابة الدفع) لا صفحةً في المُوجِّه.
  ///
  /// ‼️ **يغيّر طريقة الإغلاق لا الشكل**: الورقة مسارٌ على `Navigator` الجذر،
  /// و`context.pop()` الخاصّ بـgo_router يُغلق الصفحة التي تحتها بدلاً منها.
  final bool asSheet;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();

  /// ‼️ **«تسجيل جديد» ليس نقطةً أخرى في الخادم.**
  ///
  /// `verifyOtp` يُنشئ الحساب بـ`upsert` عند أوّل تحقّق — فمن يدخل برقمه أوّل
  /// مرّة، حسابُه أُنشئ. والفرق الوحيد بين الوضعين هو **التقاط الاسم**، وحفظُه
  /// بعد التحقّق. فلا تبحث عن مسار تسجيلٍ ثانٍ: لا وجود له.
  bool _signup = false;

  /// خطوةٌ أخيرة تُعرَض **بعد** الدخول لمن حسابه بلا اسم.
  ///
  /// ‼️ **ولماذا بعد التحقّق لا قبله؟** لأنّ السؤال «هل لهذا الرقم حساب؟»
  /// لا يُجاب قبل التحقّق **إلّا بكشف من يتسوّق عندنا**: نقطةٌ تقول «هذا الرقم
  /// مسجَّل» تُمكّن أيّ أحدٍ من تعداد عملائنا رقماً بعد رقم. ولذلك لا يُميّز
  /// الخادم بين الحالتين عمداً، و`verifyOtp` يُنشئ الحساب بـ`upsert`.
  ///
  /// ‼️ **وهذه الخطوة تُصلح ما لا يُصلحه تبويب «تسجيل جديد»**: الحسابات التي
  /// أُنشئت قبل وجود حقل الاسم أصلاً — وهي كلّ حسابات التطبيق حتّى اليوم —
  /// بلا اسم، ولا سبيل لها إليه إلّا من الملفّ الشخصيّ إن اهتدت إليه.
  bool _askName = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _done() {
    /// ‼️ **الورقة تُغلَق بـ`Navigator` لا بـ`context.pop` الخاصّ بـgo_router.**
    ///
    /// حين تُعرَض هذه الشاشة ورقةً منبثقة (بوّابة الدفع) تكون الورقة مساراً على
    /// `Navigator` الجذر، بينما `context.pop()` يُنادي مُوجِّه go_router —
    /// فيُغلق **الصفحة التي تحتها** (السلّة) وتبقى الورقة معلّقةً فوق شاشةٍ
    /// خاطئة. والفرق لا يظهر إلّا بتشغيلٍ حقيقيّ بعد دخولٍ ناجح.
    if (widget.asSheet) {
      Navigator.of(context).pop(true);
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TintColors.cream,
      appBar: AppBar(
        backgroundColor: TintColors.charcoal,
        foregroundColor: Colors.white,
        // ‼️ ولا يبقى «تسجيل الدخول» والمستخدم في تبويب «تسجيل جديد».
        title: Text(
          _signup ? 'حساب جديد' : 'تسجيل الدخول',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // ‼️ الاسم يُسأل مرّةً واحدة — ومن حسابه يحمله يمرّ بلا سؤال.
            if (!_askName && (state.customer?.name ?? '').trim().isEmpty) {
              _name.text = '';
              setState(() => _askName = true);
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمّ تسجيل الدخول ✅'), backgroundColor: TintColors.success),
            );
            _done();
          }
        },
        builder: (context, state) {
          final cubit = context.read<AuthCubit>();
          final onCode = state.status == AuthStatus.otpSent || state.status == AuthStatus.verifying;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: TintColors.blush,
                    child: Icon(Icons.lock_outline, color: TintColors.sand, size: 32),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _askName
                      ? 'بقي اسمك'
                      : onCode
                          ? 'أدخل رمز التحقّق'
                          : (_signup ? 'أنشئ حسابك في تِنت' : 'مرحباً بك في تِنت'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: TintColors.charcoal),
                ),
                const SizedBox(height: 6),
                Text(
                  _askName
                      ? 'دخلتَ بنجاح. اكتب اسمك مرّةً واحدة — يُكتب على طلباتك ولا نسألك عنه بعدها.'
                      : onCode
                          ? _sentLine(state)
                          : (_signup
                              ? 'اسمك ورقم جوّالك — ويصلك رمز التحقّق على واتساب.'
                              : 'اختر كيف نُرسل لك رمز التحقّق.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TintColors.textMuted, height: 1.6),
                ),
                const SizedBox(height: 24),

                if (_askName) ...[
                  _field(_name, 'الاسم الأوّل والأخير', Icons.person_outline,
                      TextInputType.name),
                ] else if (!onCode) ...[
                  _modeSwitch(),
                  const SizedBox(height: 16),

                  /// ‼️ **الاسم يُطلَب مرّةً هنا فيُغني عن كتابته في كلّ عنوان.**
                  ///
                  /// كان يُكتب يدويّاً في نموذج عنوان التوصيل كلّ مرّة، والحساب
                  /// يعرفه — لو كان قد سُئل عنه يوماً. (طلب المالك 2026-08-26.)
                  if (_signup) ...[
                    _field(_name, 'الاسم الأوّل والأخير', Icons.person_outline,
                        TextInputType.name),
                    const SizedBox(height: 14),
                  ],

                  // ‼️ **الاختيار قبل الإدخال — وحقلٌ واحد لا اثنان.**
                  //
                  //    كانت الشاشة تطلب الجوّال **والبريد** معاً ثمّ تُرسل إلى
                  //    البريد دائماً: فمن لا بريد له لا يدخل أصلاً، ومن أراد
                  //    واتساب لا يجد إليه سبيلاً. وهذا سبب أنّ التحقّق بواتساب
                  //    «غير مفعَّل» في التطبيق بينما هو القناة الأساسيّة في الموقع.
                  /// ‼️ **التسجيل بالجوّال وحده — لا اختيار قناة.**
                  ///
                  /// الحساب يُنشأ على **رقم الجوّال** (`{ phone }` هو مفتاح
                  /// `upsert` في الخادم)، فتسجيلٌ بالبريد يُنشئ حساباً بلا
                  /// جوّال — ثمّ يُطلَب الجوّال في أوّل عنوان توصيل. والاختيار
                  /// يبقى كاملاً في «دخول» لمن حسابه قائم.
                  if (!_signup) ...[
                    _channelPicker(context, state),
                    const SizedBox(height: 14),
                  ],
                  if (_signup || state.channel == VerificationChannel.whatsapp)
                    _field(_phone, 'رقم الجوّال', Icons.phone_outlined, TextInputType.phone)
                  else
                    _field(_email, 'البريد الإلكترونيّ', Icons.mail_outline, TextInputType.emailAddress),
                ] else if (!_askName) ...[
                  _field(_code, 'رمز التحقّق', Icons.key_outlined, TextInputType.number, isCode: true),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: state.isBusy ? null : cubit.editPhone,
                      child: const Text('تغيير الرقم', style: TextStyle(color: TintColors.sand, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  ..._switchChannel(context, state),
                ],

                if (state.error != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TintColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(state.error!, style: const TextStyle(color: TintColors.danger, fontWeight: FontWeight.w700)),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: TintColors.charcoal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: state.isBusy
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            if (_askName) {
                              if (_name.text.trim().length < 3) {
                                _snack(context, 'اكتب اسمك كما تريده على الطلب.');
                                return;
                              }
                              await cubit.updateName(_name.text);
                              if (!context.mounted) return;
                              // ‼️ يُغلَق هنا صراحةً: الحالة `authenticated`
                              //    أصلاً، فلا يُطلق المستمع مرّةً ثانية.
                              setState(() => _askName = false);
                              _done();
                              return;
                            }
                            if (onCode) {
                              // ‼️ الاسم يُمرَّر في التسجيل وحده — وتمريرُه في
                              //    «دخول» كان سيكتب فوق اسمٍ محفوظ بفراغ.
                              cubit.verifyOtp(
                                _code.text,
                                name: _signup ? _name.text : null,
                              );
                            } else {
                              // ‼️ يُتحقَّق ممّا **سيُرسَل** لا من كلّ الحقول:
                              //    من اختار واتساب لا يملك بريداً والعكس،
                              //    وفحصُ الاثنين كان يمنع الطريقتين معاً.
                              if (_signup && _name.text.trim().length < 3) {
                                _snack(context, 'اكتب اسمك كما تريده على الطلب.');
                                return;
                              }
                              // ‼️ التسجيل بالجوّال دائماً مهما كانت القناة
                              //    المختارة في وضع «دخول» — الحساب يُنشأ عليه.
                              final wantsEmail = !_signup &&
                                  state.channel == VerificationChannel.email;
                              if (wantsEmail) {
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(_email.text.trim())) {
                                  _snack(context, 'أدخل بريداً إلكترونيّاً صحيحاً.');
                                  return;
                                }
                              } else if (!looksLikeSaudiMobile(_phone.text)) {
                                _snack(context,
                                    'أدخل رقم جوّالٍ سعُدّ صحيح (5xxxxxxxx).');
                                return;
                              }
                              cubit.requestOtp(
                                phone: wantsEmail ? '' : _phone.text,
                                email: _email.text,
                              );
                            }
                          },
                    child: state.isBusy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(
                            _askName
                                ? 'حفظ ومتابعة'
                                : onCode
                                    ? (_signup ? 'تأكيد وإنشاء الحساب' : 'تأكيد الدخول')
                                    : 'إرسال الرمز',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                  ),
                ),

                /// ‼️ **ولا «متابعة كزائر» هنا — والسبب ليس تفضيلاً.**
                ///
                /// كان الزرّ موجوداً يوماً واحداً. ثمّ تبيّن أنّ مسار الزائر
                /// **لا يعمل أصلاً**: `POST /orders/checkout` يرفض بـ401
                /// «يلزم تأكيد رقم الجوّال» ما لم يصحبه توكن عميلٍ أو توكن
                /// طلبٍ مُصدَرٌ بعد رمز تحقّق — والتطبيق لا يعرف الثاني. فكان
                /// الزائر يختار ويحدّد موقعه ويكتب جوّاله **ثمّ يُرفَض عند آخر
                /// ضغطة** برسالةٍ لا يفهم سببها.
                ///
                /// ‼️ والحارس نفسه بُني لسببٍ أثقل من الطلبات الوهميّة: بلا
                /// هويّةٍ مُثبَتة كان يُصرَف **رصيد محفظة عميلٍ آخر** بكتابة
                /// جوّاله في نموذج العنوان.
              ],
            ),
          );
        },
      ),
    );
  }

  /// مبدّل «دخول / تسجيل جديد».
  ///
  /// ‼️ **تبويبان ظاهران لا رابطٌ صغير في الأسفل.** من لا حساب له يجب أن يرى
  /// طريقه من أوّل نظرة؛ ورابطٌ تحت الزرّ يُقرأ خياراً ثانويّاً فيُتجاهَل،
  /// فيُدخل رقمه في «دخول» ويصله رمزٌ ويُنشأ حسابه **بلا اسم** — وهو الوضع
  /// الذي نُصلحه أصلاً.
  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TintColors.blush,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _modeTab('دخول', !_signup, () => setState(() => _signup = false)),
          _modeTab('تسجيل جديد', _signup, () => setState(() => _signup = true)),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? TintColors.charcoal : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : TintColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// السطر الذي يقول للمستخدم **أين** وصل الرمز.
  ///
  /// ‼️ ويُعلَن التحويل صراحةً: الخادم قد يعجز عن القناة المطلوبة فيُرسل على
  /// أخرى، ومن لا يُخبَر ينتظر رسالةً لن تصله أبداً ويظنّ الخدمة معطّلة.
  String _sentLine(AuthState state) {
    final delivery = state.delivery;
    final channel = delivery?.channel ?? state.channel;
    final target = (delivery?.target ?? '').isNotEmpty
        ? delivery!.target
        : (channel == VerificationChannel.email ? state.email : state.phone);
    final line = 'أرسلنا الرمز عبر ${channel.label} إلى $target';
    return delivery?.usedFallback == true
        ? '$line — تعذّرت القناة التي اخترتها فحوّلناه'
        : line;
  }

  Widget _channelPicker(BuildContext context, AuthState state) {
    final cubit = context.read<AuthCubit>();
    return Row(
      children: [
        for (final channel in VerificationChannel.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: state.isBusy ? null : () => cubit.setChannel(channel),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: state.channel == channel
                      ? TintColors.blush
                      : Colors.transparent,
                  border: Border.all(
                    color: state.channel == channel
                        ? TintColors.sand
                        : const Color(0xFFE2E8F0),
                    width: state.channel == channel ? 1.6 : 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      channel == VerificationChannel.whatsapp
                          ? Icons.chat_bubble_outline
                          : Icons.mail_outline,
                      color: TintColors.sand,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      channel.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: TintColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (channel != VerificationChannel.values.last)
            const SizedBox(width: 10),
        ],
      ],
    );
  }

  /// ‼️ **لا يُعرَض إلّا ما يقوله الخادم إنّه مُتاح.**
  ///
  /// زرٌّ لقناةٍ غير مُعدّة يُنتج خطأً لا حيلة للمستخدم فيه — والقائمة تأتي من
  /// `availableChannels` في جواب الإرسال لا من افتراضٍ في التطبيق.
  List<Widget> _switchChannel(BuildContext context, AuthState state) {
    final cubit = context.read<AuthCubit>();
    final others = (state.delivery?.availableChannels ?? const <VerificationChannel>[])
        .where((c) => c != state.channel)
        .toList();
    if (others.isEmpty) return const [];

    return [
      for (final channel in others)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: state.isBusy
                ? null
                : () {
                    // ‼️ **تُعاد الشاشة الأولى حين ينقص العنوان.**
                    //
                    //    من دخل بجوّاله ثمّ طلب البريد كان يصله «أدخل بريداً
                    //    صحيحاً» **ولا حقل بريدٍ على الشاشة** — طريقٌ مسدود:
                    //    خطأٌ يطلب ما لا سبيل لإدخاله.
                    final missingEmail = channel == VerificationChannel.email &&
                        _email.text.trim().isEmpty;
                    final missingPhone =
                        channel == VerificationChannel.whatsapp &&
                            !looksLikeSaudiMobile(_phone.text);
                    if (missingEmail || missingPhone) {
                      cubit.setChannel(channel);
                      cubit.editPhone();
                      return;
                    }
                    cubit.requestOtp(
                      phone: channel == VerificationChannel.email ? '' : _phone.text,
                      email: _email.text,
                      channel: channel,
                    );
                  },
            child: Text(
              'أرسله عبر ${channel.label}',
              style: const TextStyle(
                color: TintColors.sand,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
    ];
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    TextInputType type, {
    bool isCode = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      inputFormatters: isCode ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)] : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: TintColors.sand),
      ),
    );
  }
}
