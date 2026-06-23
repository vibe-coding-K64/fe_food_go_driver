import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/base_remote_datasource.dart';
import '../../domain/entities/chat_message.dart';

class ChatRemoteDataSource extends BaseRemoteDataSource {
  ChatRemoteDataSource({
    http.Client? httpClient,
    String? baseApiUrl,
    required Future<String> Function() getToken,
    required FlutterSecureStorage secureStorage,
  }) : super(
          httpClient: httpClient,
          baseApiUrl: baseApiUrl,
          getToken: getToken,
          secureStorage: secureStorage,
        );

  Future<List<Conversation>> getConversations() async {
    log('GET /chat/conversations');
    try {
      final response = await requestGet('/chat/conversations');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? [])
            : (decoded is List ? decoded : []);
        if (data is List) {
          return data.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      log('Exception getConversations: $e');
      return [];
    }
  }

  Future<Conversation?> getOrCreateConversation(String orderId) async {
    log('GET /chat/conversations/order/$orderId');
    try {
      final response = await requestGet('/chat/conversations/order/$orderId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          return Conversation.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      log('Exception getOrCreateConversation: $e');
      return null;
    }
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 20, DateTime? before}) async {
    String path = '/chat/conversations/$conversationId/messages?limit=$limit';
    if (before != null) {
      path += '&before=${before.millisecondsSinceEpoch}';
    }
    log('GET $path');
    try {
      final response = await requestGet(path);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? [])
            : (decoded is List ? decoded : []);
        if (data is List) {
          return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      log('Exception getMessages: $e');
      return [];
    }
  }

  Future<ChatMessage?> sendMessage(String orderId, String content) async {
    log('POST /chat/send - orderId=$orderId, contentLen=${content.length}');
    try {
      final response = await requestPost('/chat/send', body: {
        'orderId': orderId,
        'content': content,
      });
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          return ChatMessage.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      log('Exception sendMessage: $e');
      return null;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    log('PUT /chat/conversations/$conversationId/read');
    try {
      await requestPut('/chat/conversations/$conversationId/read');
    } catch (e) {
      log('Exception markAsRead: $e');
    }
  }
}
