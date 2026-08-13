import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/verification_channel.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _done() {
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
        title: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
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
                  onCode ? 'أدخل رمز التحقّق' : 'مرحباً بك في تِنت',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: TintColors.charcoal),
                ),
                const SizedBox(height: 6),
                Text(
                  onCode
                      ? _sentLine(state)
                      : 'اختر كيف نُرسل لك رمز التحقّق.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TintColors.textMuted, height: 1.6),
                ),
                const SizedBox(height: 24),

                if (!onCode) ...[
                  // ‼️ **الاختيار قبل الإدخال — وحقلٌ واحد لا اثنان.**
                  //
                  //    كانت الشاشة تطلب الجوّال **والبريد** معاً ثمّ تُرسل إلى
                  //    البريد دائماً: فمن لا بريد له لا يدخل أصلاً، ومن أراد
                  //    واتساب لا يجد إليه سبيلاً. وهذا سبب أنّ التحقّق بواتساب
                  //    «غير مفعَّل» في التطبيق بينما هو القناة الأساسيّة في الموقع.
                  _channelPicker(context, state),
                  const SizedBox(height: 14),
                  if (state.channel == VerificationChannel.whatsapp)
                    _field(_phone, 'رقم الجوّال', Icons.phone_outlined, TextInputType.phone)
                  else
                    _field(_email, 'البريد الإلكترونيّ', Icons.mail_outline, TextInputType.emailAddress),
                ] else ...[
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
                        : () {
                            FocusScope.of(context).unfocus();
                            if (onCode) {
                              cubit.verifyOtp(_code.text);
                            } else {
                              // ‼️ يُتحقَّق ممّا **سيُرسَل** لا من كلّ الحقول:
                              //    من اختار واتساب لا يملك بريداً والعكس،
                              //    وفحصُ الاثنين كان يمنع الطريقتين معاً.
                              final wantsEmail =
                                  state.channel == VerificationChannel.email;
                              if (wantsEmail) {
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(_email.text.trim())) {
                                  _snack(context, 'أدخل بريداً إلكترونيّاً صحيحاً.');
                                  return;
                                }
                              } else if (!looksLikeSaudiMobile(_phone.text)) {
                                _snack(context,
                                    'أدخل رقم جوّالٍ سعوديّ صحيح (5xxxxxxxx).');
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
                            onCode ? 'تأكيد الدخول' : 'إرسال الرمز',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
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
