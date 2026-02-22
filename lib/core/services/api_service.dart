import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  Box? _cacheBox;

  // Initialize cache box if not already open (though main.dart should handle this)
  Future<Box> get _box async {
    if (_cacheBox != null && _cacheBox!.isOpen) return _cacheBox!;
    _cacheBox = await Hive.openBox('api_cache');
    return _cacheBox!;
  }

  // Get stored token
  Future<String?> getToken() async {
    _token ??= await StorageHelper.getToken();
    return _token;
  }
  
  // Set token
  Future<void> setToken(String token) async {
    _token = token;
    await StorageHelper.saveToken(token);
  }
  
  // Clear token
  Future<void> clearToken() async {
    _token = null;
    await StorageHelper.clearToken();
  }
  
  // GET request with Caching
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    bool forceRefresh = false,
    bool cacheEnabled = true, // Default to true for offline support
    Duration? cacheDuration, // Optional custom cache duration
  }) async {
    final uri = Uri.parse('${ApiConfig.currentBaseUrl}$endpoint')
        .replace(queryParameters: queryParameters);
    final cacheKey = uri.toString();

    // 1. Try to return from cache if not forcing refresh
    if (!forceRefresh && cacheEnabled) {
      try {
        final box = await _box;
        if (box.containsKey(cacheKey)) {
          final cachedData = box.get(cacheKey);
          final timestamp = cachedData['timestamp'] as int;
          // Using jsonDecode(jsonEncode()) to deeply cast all nested Map<dynamic, dynamic> to Map<String, dynamic>
          final content = jsonDecode(jsonEncode(cachedData['content'])) as Map<String, dynamic>;
          
          // Check if cache is valid (default 1 hour if not specified)
          final duration = cacheDuration ?? const Duration(hours: 1);
          final isExpired = DateTime.now().millisecondsSinceEpoch - timestamp > duration.inMilliseconds;

          if (!isExpired) {
            return content;
          } else {
             // Cache is expired, but we might keep it as fallback if network fails
             // Proceed to fetch
          }
        }
      } catch (e) {
        // Silently fail on cache read and proceed to network
        print('Cache read error: $e');
      }
    }

    // 2. Network Request
    try {
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getToken() ?? '')
          : ApiConfig.headers;
      
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);
      
      final data = _handleResponse(response);

      // 3. Save to cache on success
      if (cacheEnabled) {
        try {
          final box = await _box;
          await box.put(cacheKey, {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'content': data,
          });
        } catch (e) {
          print('Cache write error: $e');
        }
      }

      return data;
    } catch (e) {
      // 4. On failure, try to return stale cache if available
      if (cacheEnabled) {
        try {
          final box = await _box;
          if (box.containsKey(cacheKey)) {
             final cachedData = box.get(cacheKey);
             // Using jsonDecode(jsonEncode()) for deep casting
             return jsonDecode(jsonEncode(cachedData['content'])) as Map<String, dynamic>;
          }
        } catch (_) {}
      }
      
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.currentBaseUrl}$endpoint');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getToken() ?? '')
          : ApiConfig.headers;
      
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.currentBaseUrl}$endpoint');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getToken() ?? '')
          : ApiConfig.headers;
      
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.currentBaseUrl}$endpoint');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getToken() ?? '')
          : ApiConfig.headers;
      
      final response = await http
          .delete(uri, headers: headers)
          .timeout(ApiConfig.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // MULTIPART request
  Future<Map<String, dynamic>> multipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.currentBaseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      if (fields != null) request.fields.addAll(fields);
      if (files != null) request.files.addAll(files);
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getToken() ?? '')
          : ApiConfig.headers;
      
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('API Response [${response.statusCode}] ${response.request?.url}');
    
    // Try to decode json, if it fails, it might be an HTML error page or empty
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON Decode Error: $e');
      debugPrint('Raw Body snippet: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      
       body = {
        'message': response.statusCode >= 500 ? 'Server Error' : 'Unexpected response format',
        'raw_body': response.body,
      };
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      debugPrint('API Error Body: $body');
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'An error occurred',
        errors: body['errors'],
      );
    }
  }
  
  // Handle errors
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error is http.ClientException || error is SocketException) {
      return ApiException(
        statusCode: 0,
        message: 'Network error. Please check your connection.',
      );
    } else if (error is TimeoutException) {
       return ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    } else {
      return ApiException(
        statusCode: 0,
        message: 'An unexpected error occurred: $error',
      );
    }
  }
}

// API Exception class
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });
  
  @override
  String toString() {
    if (errors != null) {
      return '$message\n${errors!.entries.map((e) => '${e.key}: ${e.value}').join('\n')}';
    }
    return message;
  }
  
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode >= 500;
}
