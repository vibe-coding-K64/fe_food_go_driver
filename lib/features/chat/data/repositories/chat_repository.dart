import '../datasources/chat_remote_datasource.dart';
import '../../domain/entities/chat_message.dart';

class ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepository(this._remoteDataSource);

  Future<List<Conversation>> getConversations() => _remoteDataSource.getConversations();

  Future<Conversation?> getOrCreateConversation(String orderId) =>
      _remoteDataSource.getOrCreateConversation(orderId);

  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 20, DateTime? before}) =>
      _remoteDataSource.getMessages(conversationId, limit: limit, before: before);

  Future<ChatMessage?> sendMessage(String orderId, String content) =>
      _remoteDataSource.sendMessage(orderId, content);

  Future<void> markAsRead(String conversationId) =>
      _remoteDataSource.markAsRead(conversationId);
}
