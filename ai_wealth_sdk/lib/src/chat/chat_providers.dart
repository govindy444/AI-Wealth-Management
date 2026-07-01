import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/chat_remote_datasource.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/usecases/chat_usecases.dart';
import 'presentation/state/chat_controller.dart';
import 'presentation/state/chat_state.dart';



final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>(
  (ref) => ChatRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(
    remote: ref.watch(chatRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(chatRepositoryProvider)),
);
final getConversationUseCaseProvider = Provider<GetConversationUseCase>(
  (ref) => GetConversationUseCase(ref.watch(chatRepositoryProvider)),
);
final listConversationsUseCaseProvider = Provider<ListConversationsUseCase>(
  (ref) => ListConversationsUseCase(ref.watch(chatRepositoryProvider)),
);
final deleteConversationUseCaseProvider = Provider<DeleteConversationUseCase>(
  (ref) => DeleteConversationUseCase(ref.watch(chatRepositoryProvider)),
);

/// Active-conversation controller. `autoDispose` so each chat screen starts
/// from a clean state and releases when closed.
final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatState>(
  (ref) => ChatController(
    sendMessage: ref.watch(sendMessageUseCaseProvider),
    getConversation: ref.watch(getConversationUseCaseProvider),
  ),
);
