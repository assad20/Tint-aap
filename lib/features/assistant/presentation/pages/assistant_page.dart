import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/chat_message_model.dart';
import '../cubit/assistant_cubit.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: TintColors.charcoal,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0x1AFFFFFF),
              child: Icon(Icons.smart_toy_outlined, color: TintColors.sand),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مستشار تنت الذكي ✨',
                  style: TextStyle(
                    color: TintColors.sand,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'متخصص في أناقتك وجمالك',
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AssistantCubit, AssistantState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isLoading) {
                        return _Bubble(
                          text: 'جاري التفكير...',
                          isUser: false,
                          isLoading: true,
                        );
                      }

                      final message = state.messages[index];
                      return _Bubble(
                        text: message.content,
                        isUser: message.role == ChatRole.user,
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: TintColors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(context),
                          decoration: const InputDecoration(
                            hintText: 'اسألي عن عطر، تنسيق فستان، هدية...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: state.isLoading ? null : () => _send(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: TintColors.charcoal,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _send(BuildContext context) {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    context.read<AssistantCubit>().send(message);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });

  final String text;
  final bool isUser;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final background = isUser ? TintColors.sand : Colors.white;
    final foreground = isUser ? Colors.white : TintColors.charcoal;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(6),
            bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(20),
          ),
          border: isUser ? null : Border.all(color: TintColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
