// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class APIService {
  final String baseUrl = APIConstants.baseUrl;
  
  // Singleton pattern
  static final APIService _instance = APIService._internal();
  factory APIService() => _instance;
  APIService._internal();

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _headersWithAuth(String? token) => {
    ..._headers,
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // ✅ AI Chat Methods
  Future<Map<String, dynamic>> sendAIMessage(
    String projectId, 
    String message, {
    String? token,
    String? projectTitle,
    String? projectContext,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ai/chat');
      
      final requestBody = {
        'project_id': projectId,
        'message': message,
        'project_title': projectTitle ?? '',
        'project_context': projectContext ?? '',
        'conversation_history': conversationHistory ?? [],
      };

      final response = await http.post(
        url,
        headers: _headersWithAuth(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send AI message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error sending AI message: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ Get AI Suggestions
  Future<Map<String, dynamic>> getAISuggestions({
    required List<String> userSkills,
    List<String>? interests,
    String difficultyLevel = 'intermediate',
    bool forceRefresh = false,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ai/suggestions');
      
      final requestBody = {
        'user_skills': userSkills,
        'interests': interests ?? [],
        'difficulty_level': difficultyLevel,
        'force_refresh': forceRefresh,
      };

      final response = await http.post(
        url,
        headers: _headersWithAuth(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get AI suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error getting AI suggestions: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ Chat Methods
  Future<Map<String, dynamic>> getChatList({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/chat/');
      
      final response = await http.get(
        url,
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get chat list: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error getting chat list: $e');
      return {'data': []};
    }
  }

  Future<Map<String, dynamic>> getChatMessages(
    String chatId, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/chat/$chatId/messages');
      
      final response = await http.get(
        url,
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error getting messages: $e');
      return {'messages': []};
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    String chatId,
    String content, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/chat/$chatId/messages');
      
      final requestBody = {
        'content': content,
      };

      final response = await http.post(
        url,
        headers: _headersWithAuth(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error sending message: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ Authentication Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      
      final requestBody = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error login: $e');
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      
      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error register: $e');
      throw Exception('Registration error: $e');
    }
  }

  // ✅ Project Methods
  Future<Map<String, dynamic>> getProjects({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/projects/');
      
      final response = await http.get(
        url,
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get projects: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error getting projects: $e');
      return {'projects': []};
    }
  }

  Future<Map<String, dynamic>> createProject(
    Map<String, dynamic> projectData, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/projects/');
      
      final response = await http.post(
        url,
        headers: _headersWithAuth(token),
        body: json.encode(projectData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error creating project: $e');
      throw Exception('Project creation error: $e');
    }
  }

  // ✅ User Methods
  Future<Map<String, dynamic>> getUserProfile({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/users/me');
      
      final response = await http.get(
        url,
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error getting user profile: $e');
      throw Exception('Profile error: $e');
    }
  }

  // ✅ Utility Methods
  bool isValidResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Map<String, dynamic> handleError(dynamic error) {
    print('❌ API Service Error: $error');
    return {
      'success': false,
      'error': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}