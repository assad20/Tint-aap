import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/chat_message_model.dart';
import '../../domain/repositories/assistant_repository.dart';

/// رسالة ترحيب المستشار — نصّ واجهةٍ لا بضاعة.
///
/// كانت تسكن `FakeSeedData` مع ٢٣ منتجاً مخترعاً، فبقي الملفّ حيّاً لأجلها
/// وحدها بعد فصل تلك المنتجات عن الواجهة. نُقلت إلى ميزتها وحُذف الملفّ.
List<ChatMessageModel> assistantGreeting() => [
      ChatMessageModel(
        role: ChatRole.assistant,
        content:
            'أهلاً بك في تنت (Tint)! أنا مستشار الموضة والجمال ✨. أي قسم تتصفحين اليوم لأساعدك في الاختيار؟',
        createdAt: DateTime.now(),
      ),
    ];

class AssistantState {
  const AssistantState({
    this.isLoading = false,
    this.messages = const [],
  });

  final bool isLoading;
  final List<ChatMessageModel> messages;

  AssistantState copyWith({
    bool? isLoading,
    List<ChatMessageModel>? messages,
  }) {
    return AssistantState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
    );
  }
}

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({required AssistantRepository repository})
      : _repository = repository,
        super(AssistantState(messages: assistantGreeting()));

  final AssistantRepository _repository;

  Future<void> send(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessageModel(
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final pendingMessages = [...state.messages, userMessage];

    emit(
      state.copyWith(
        isLoading: true,
        messages: pendingMessages,
      ),
    );

    final reply = await _repository.sendMessage(
      message: trimmed,
      history: pendingMessages,
    );

    final assistantMessage = ChatMessageModel(
      role: ChatRole.assistant,
      content: reply.answer,
      createdAt: DateTime.now(),
      products: reply.products,
    );

    emit(
      state.copyWith(
        isLoading: false,
        messages: [...pendingMessages, assistantMessage],
      ),
    );
  }

  void reset() {
    emit(AssistantState(messages: assistantGreeting()));
  }
}
