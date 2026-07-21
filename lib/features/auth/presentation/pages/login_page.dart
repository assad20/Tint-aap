import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
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
                      ? 'أرسلنا رمزاً إلى بريدك ${state.email}'
                      : 'سجّل الدخول بجوّالك وبريدك — نرسل لك رمز تحقّق.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TintColors.textMuted, height: 1.6),
                ),
                const SizedBox(height: 24),

                if (!onCode) ...[
                  _field(_phone, 'رقم الجوّال', Icons.phone_outlined, TextInputType.phone),
                  const SizedBox(height: 12),
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
                              cubit.requestOtp(phone: _phone.text, email: _email.text);
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
