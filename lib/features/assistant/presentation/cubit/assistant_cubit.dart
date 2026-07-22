import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/chat_message_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../domain/repositories/assistant_repository.dart';

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
        super(AssistantState(messages: FakeSeedData.defaultAssistantMessages));

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
    emit(AssistantState(messages: FakeSeedData.defaultAssistantMessages));
  }
}
