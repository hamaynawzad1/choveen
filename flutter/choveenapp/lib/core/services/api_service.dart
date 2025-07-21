import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      Map<String, String> headers = Map.from(ApiConstants.headers);
      
      if (requireAuth) {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      print('GET Request: $url');
      print('Headers: $headers');

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      print('API GET Error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      Map<String, String> headers = Map.from(ApiConstants.headers);
      
      if (requireAuth) {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      print('POST Request: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      print('API POST Error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    try {
      final responseBody = response.body;
      
      if (responseBody.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true};
        } else {
          throw Exception('HTTP ${response.statusCode}: Empty response');
        }
      }

      final data = json.decode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'data': data};
      } else {
        final errorMessage = data is Map<String, dynamic> 
            ? (data['detail'] ?? data['message'] ?? 'Unknown error')
            : 'HTTP ${response.statusCode}';
        throw Exception('API Error: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to parse response: ${e.toString()}');
    }
  }
}

