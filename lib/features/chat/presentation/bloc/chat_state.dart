import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final String orderId;
  final String currentUserId;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final DateTime? oldestMessageTimestamp;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversation,
    this.messages = const [],
    this.errorMessage,
    this.orderId = '',
    this.currentUserId = '',
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
    this.oldestMessageTimestamp,
  });

  ChatState copyWith({
    ChatStatus? status,
    Conversation? conversation,
    List<ChatMessage>? messages,
    String? errorMessage,
    String? orderId,
    String? currentUserId,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    DateTime? oldestMessageTimestamp,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      orderId: orderId ?? this.orderId,
      currentUserId: currentUserId ?? this.currentUserId,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      oldestMessageTimestamp: oldestMessageTimestamp ?? this.oldestMessageTimestamp,
    );
  }

  @override
  List<Object?> get props => [status, conversation, messages, errorMessage, orderId, currentUserId, hasMoreMessages, isLoadingMore, oldestMessageTimestamp];
}
