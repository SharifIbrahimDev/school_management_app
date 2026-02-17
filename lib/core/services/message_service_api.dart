import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import '../models/message_model.dart';
import '../utils/storage_helper.dart';

class MessageServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get list of conversations with offline caching
  Future<List<dynamic>> getConversations() async {
    const cacheKey = 'conversations_list';
    try {
      final response = await _apiService.get(ApiConfig.messages);
      final data = response['data'] as List? ?? [];
      
      // Save to cache
      await StorageHelper.saveCache(cacheKey, data);
      
      return data;
    } catch (e) {
      // Try loading from cache
      final cachedData = await StorageHelper.getCache(cacheKey);
      if (cachedData != null) {
        return cachedData as List<dynamic>;
      }
      throw Exception('Error loading conversations (offline): $e');
    }
  }

  /// Get chat history with another user with offline caching
  Future<List<dynamic>> getConversation(int otherUserId) async {
    final cacheKey = 'conversation_$otherUserId';
    try {
      final response = await _apiService.get('${ApiConfig.messages}/conversation/$otherUserId');
      final data = response['data'] as List? ?? [];
      
      // Save to cache
      await StorageHelper.saveCache(cacheKey, data);
      
      return data;
    } catch (e) {
      // Try loading from cache
      final cachedData = await StorageHelper.getCache(cacheKey);
      if (cachedData != null) {
        return cachedData as List<dynamic>;
      }
      throw Exception('Error loading chat history (offline): $e');
    }
  }

  /// Get inbox messages
  Future<List<MessageModel>> getInbox() async {
    try {
      final response = await _apiService.get('${ApiConfig.messages}/inbox');
      final List data = response['data'] as List? ?? [];
      return data.map((json) => MessageModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Error loading inbox: $e');
    }
  }

  /// Get sent messages
  Future<List<MessageModel>> getSent() async {
    try {
      final response = await _apiService.get('${ApiConfig.messages}/sent');
      final List data = response['data'] as List? ?? [];
      return data.map((json) => MessageModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Error loading sent messages: $e');
    }
  }

  /// Search users to message
  Future<List<UserSelectModel>> searchUsers({String? query}) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.messages}/search', 
        queryParameters: query != null ? {'query': query} : null
      );
      final List data = response['data'] as List? ?? [];
      return data.map((json) => UserSelectModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  /// Get specific message details
  Future<MessageModel> getMessage(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.messages}/$id');
      return MessageModel.fromMap(response['data']);
    } catch (e) {
      throw Exception('Error loading message: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int id) async {
    try {
      await _apiService.delete('${ApiConfig.messages}/$id');
      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  /// Send a new message
  Future<Map<String, dynamic>> sendMessage({
    required int recipientId,
    required String body,
    String? subject,
    int? parentMessageId,
  }) async {
    try {
      final data = {
        'recipient_id': recipientId,
        'body': body,
        if (subject != null) 'subject': subject,
        if (parentMessageId != null) 'parent_message_id': parentMessageId,
      };
      final response = await _apiService.post(ApiConfig.messages, body: data);
      notifyListeners();
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Mark message as read
  Future<void> markAsRead(int messageId) async {
    try {
      await _apiService.post('${ApiConfig.messages}/$messageId/read');
    } catch (e) {
      // Ignore read errors for now
    }
  }

  /// Get contacts available to message
  Future<List<dynamic>> getContacts() async {
    try {
      final response = await _apiService.get('${ApiConfig.messages}/contacts');
      return response['data'] as List? ?? [];
    } catch (e) {
      throw Exception('Error loading contacts: $e');
    }
  }

  /// Broadcast message to a section/role
  Future<void> broadcastMessage({
    required int sectionId,
    required String role,
    required String subject,
    required String body,
  }) async {
    try {
      final data = {
        'section_id': sectionId,
        'role': role,
        'subject': subject,
        'body': body,
      };
      await _apiService.post('${ApiConfig.messages}/broadcast', body: data);
      notifyListeners();
    } catch (e) {
      throw Exception('Error sending broadcast: $e');
    }
  }
}
