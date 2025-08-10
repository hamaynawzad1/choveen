// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class APIService {
  static final APIService _instance = APIService._internal();
  factory APIService() => _instance;
  APIService._internal();

  final String baseUrl = APIConstants.baseUrl;

  // ✅ Get auth token from storage
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // ✅ Get headers with auth token
  Future<Map<String, String>> _getHeaders({Map<String, String>? additionalHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if available
    final token = await _getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // ✅ Enhanced error handling
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('🌐 API Response: ${response.statusCode} - ${response.reasonPhrase}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        print('❌ JSON decode error: $e');
        return {'message': 'Success', 'data': response.body};
      }
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
      } catch (e) {
        print('❌ Error parsing error response: $e');
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final fullUrl = '$baseUrl$endpoint';
      print('🔗 GET Request: $fullUrl');
      
      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      print('📋 Headers: $requestHeaders');
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: requestHeaders,
      ).timeout(APIConstants.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Request failed: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final fullUrl = '$baseUrl$endpoint';
      print('🔗 POST Request: $fullUrl');
      print('📤 Request body: ${body != null ? json.encode(body) : 'null'}');
      
      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      print('📋 Headers: $requestHeaders');
      
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      ).timeout(APIConstants.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Request failed: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final fullUrl = '$baseUrl$endpoint';
      print('🔗 PUT Request: $fullUrl');
      print('📤 Request body: ${body != null ? json.encode(body) : 'null'}');
      
      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      
      final response = await http.put(
        Uri.parse(fullUrl),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      ).timeout(APIConstants.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ PUT Request failed: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final fullUrl = '$baseUrl$endpoint';
      print('🔗 DELETE Request: $fullUrl');
      
      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      
      final response = await http.delete(
        Uri.parse(fullUrl),
        headers: requestHeaders,
      ).timeout(APIConstants.timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ DELETE Request failed: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ AI Chat Implementation
  Future<Map<String, dynamic>> sendAIChatMessage(String projectId, String message) async {
    try {
      return await post('/api/v1/ai/chat', body: {
        'message': message,
        'project_id': projectId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ AI Chat failed: $e');
      throw Exception('AI Chat error: $e');
    }
  }

  // ✅ Chat Messages Implementation
  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      return await get('/api/v1/chats/$chatId/messages');
    } catch (e) {
      print('❌ Get chat messages failed: $e');
      throw Exception('Chat messages error: $e');
    }
  }

  // ✅ Chat List Implementation
  Future<Map<String, dynamic>> getChatList() async {
    try {
      return await get('/api/v1/chats');
    } catch (e) {
      print('❌ Get chat list failed: $e');
      throw Exception('Chat list error: $e');
    }
  }

  // ✅ Send Message Implementation
  Future<Map<String, dynamic>> sendMessage(String chatId, String message) async {
    try {
      return await post('/api/v1/chats/$chatId/messages', body: {
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Send message failed: $e');
      throw Exception('Send message error: $e');
    }
  }

  // ✅ Connection Test
  Future<bool> testConnection() async {
    try {
      final response = await get('/health');
      print('✅ Backend connection successful: ${response}');
      return true;
    } catch (e) {
      print('❌ Backend connection failed: $e');
      return false;
    }
  }
}