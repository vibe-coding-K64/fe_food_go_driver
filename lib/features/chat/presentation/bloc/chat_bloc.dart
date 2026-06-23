import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../models/driver_realtime_payloads.dart';
import '../../../../services/driver_realtime_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final DriverRealtimeService _realtimeService;
  final FlutterSecureStorage _secureStorage;

  bool consumeScrollToBottom() {
    if (_shouldScrollToBottom) {
      _shouldScrollToBottom = false;
      return true;
    }
    return false;
  }

  StreamSubscription<DriverRealtimeChatMessage>? _chatMessageSub;
  String? _lastMessageId;
  bool _shouldScrollToBottom = false;

  ChatBloc({
    required ChatRepository chatRepository,
    required DriverRealtimeService realtimeService,
    required FlutterSecureStorage secureStorage,
  }) : _chatRepository = chatRepository,
       _realtimeService = realtimeService,
       _secureStorage = secureStorage,
       super(const ChatState()) {
    on<ChatLoadConversation>(_onLoadConversation);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatConnect>(_onConnect);
    on<ChatDisconnect>(_onDisconnect);
    on<ChatLoadMoreMessages>(_onLoadMoreMessages);
    on<ChatScrollToBottomRequested>(_onScrollToBottomRequested);

    // Set up chat realtime listener immediately.
    // DriverRealtimeService is already connected by HomeBloc.
    _chatMessageSub = _realtimeService.chatMessages.listen((wsMsg) {
      if (wsMsg.conversationId == state.conversation?.id &&
          wsMsg.senderId != state.currentUserId) {
        add(ChatMessageReceived(
          conversationId: wsMsg.conversationId,
          senderId: wsMsg.senderId,
          senderName: wsMsg.senderName,
          senderRole: wsMsg.senderRole,
          content: wsMsg.content,
          messageId: wsMsg.createdAt.millisecondsSinceEpoch.toString(),
          createdAt: wsMsg.createdAt,
        ));
      }
    });
  }

  Future<String> _getDriverId() async {
    return await _secureStorage.read(key: AppConstants.driverIdKey) ?? '';
  }

  Future<void> _onConnect(ChatConnect event, Emitter<ChatState> emit) async {
    // DriverRealtimeService is already connected and managed by HomeBloc.
    // Chat subscription was set up in the constructor.
  }

  Future<void> _onDisconnect(ChatDisconnect event, Emitter<ChatState> emit) async {
    _chatMessageSub?.cancel();
    _chatMessageSub = null;
  }

  Future<void> _onLoadConversation(
    ChatLoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    // Prevent duplicate loads for same conversation
    if (state.conversation?.id == event.orderId && state.messages.isNotEmpty) {
      return;
    }

    // Only scroll to bottom on first load, not on subsequent loads
    _shouldScrollToBottom = state.messages.isEmpty;

    // Clear old messages when switching to a different conversation
    final isSameConversation = state.conversation?.id == event.orderId;
    emit(state.copyWith(
      status: ChatStatus.loading,
      orderId: event.orderId,
      messages: isSameConversation ? state.messages : const [],
      hasMoreMessages: isSameConversation ? state.hasMoreMessages : true,
      isLoadingMore: false,
      oldestMessageTimestamp: isSameConversation ? state.oldestMessageTimestamp : null,
      clearError: true,
    ));

    final driverId = await _getDriverId();

    try {
      final conv = await _chatRepository.getOrCreateConversation(event.orderId);
      if (conv == null) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Khong the tao cuoc tro chuyen.',
        ));
        return;
      }

      final messages = await _chatRepository.getMessages(conv.id);
      await _chatRepository.markAsRead(conv.id);

      final hasMore = messages.length >= 20;
      final oldestTimestamp = messages.isNotEmpty ? messages.last.createdAt : null;

      emit(state.copyWith(
        status: ChatStatus.loaded,
        conversation: conv,
        messages: messages,
        currentUserId: driverId,
        hasMoreMessages: hasMore,
        oldestMessageTimestamp: oldestTimestamp,
      ));
    } catch (e) {
      debugPrint('[ChatBloc] Load conversation error: $e');
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Khong the tai cuoc tro chuyen.',
      ));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state.conversation == null || event.content.trim().isEmpty) return;

    _shouldScrollToBottom = true;
    try {
      final message = await _chatRepository.sendMessage(
        state.orderId,
        event.content.trim(),
      );

      if (message != null) {
        emit(state.copyWith(
          messages: [...state.messages, message],
        ));
      }
    } catch (e) {
      debugPrint('[ChatBloc] Send message error: $e');
      emit(state.copyWith(
        errorMessage: 'Khong the gui tin nhan.',
      ));
    }
  }

  void _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (event.messageId == _lastMessageId) return;
    _lastMessageId = event.messageId;

    final newMsg = ChatMessage(
      id: event.messageId,
      conversationId: event.conversationId,
      senderId: event.senderId,
      senderName: event.senderName,
      senderRole: event.senderRole,
      content: event.content,
      type: 'TEXT',
      isRead: true,
      createdAt: event.createdAt,
    );

    final exists = state.messages.any((m) => m.id == newMsg.id);
    if (!exists) {
      _shouldScrollToBottom = true;
      emit(state.copyWith(
        messages: [...state.messages, newMsg],
      ));
    }
  }

  Future<void> _onLoadMoreMessages(
    ChatLoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMoreMessages || state.oldestMessageTimestamp == null) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final olderMessages = await _chatRepository.getMessages(
        state.conversation!.id,
        before: state.oldestMessageTimestamp,
      );

      final existingIds = state.messages.map((m) => m.id).toSet();
      final newOlderMessages = olderMessages.where((m) => !existingIds.contains(m.id)).toList();
      final hasMore = olderMessages.length >= 20;
      final oldestTs = newOlderMessages.isNotEmpty ? newOlderMessages.last.createdAt : state.oldestMessageTimestamp;

      emit(state.copyWith(
        isLoadingMore: false,
        messages: [...newOlderMessages, ...state.messages],
        hasMoreMessages: hasMore,
        oldestMessageTimestamp: oldestTs,
      ));
    } catch (e) {
      debugPrint('[ChatBloc] Load more messages error: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onScrollToBottomRequested(
    ChatScrollToBottomRequested event,
    Emitter<ChatState> emit,
  ) {
    _shouldScrollToBottom = true;
  }

  @override
  Future<void> close() {
    _chatMessageSub?.cancel();
    return super.close();
  }
}
