import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadConversation extends ChatEvent {
  final String orderId;

  const ChatLoadConversation(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class ChatSendMessage extends ChatEvent {
  final String content;

  const ChatSendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class ChatMessageReceived extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final String messageId;
  final DateTime createdAt;

  const ChatMessageReceived({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.messageId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [conversationId, senderId, senderName, senderRole, content, messageId, createdAt];
}

class ChatConnect extends ChatEvent {
  const ChatConnect();
}

class ChatDisconnect extends ChatEvent {
  const ChatDisconnect();
}

class ChatLoadMoreMessages extends ChatEvent {
  const ChatLoadMoreMessages();
}

class ChatScrollToBottomRequested extends ChatEvent {
  const ChatScrollToBottomRequested();
}
