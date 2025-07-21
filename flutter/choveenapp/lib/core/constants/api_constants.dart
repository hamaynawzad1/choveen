// lib/core/constants/api_constants.dart
class ApiConstants {
  // ✅ مۆبایل ئیمولەیتەر بۆ localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  
  // ✅ یان ئەگەر بە IP ی تایبەت دەیەوێت:
  // static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String verifyEmail = '/auth/verify-email';
  
  // Profile endpoints
  static const String updateProfile = '/users/profile';
  static const String uploadAvatar = '/users/avatar';
  
  // AI endpoints
  static const String aiChat = '/ai/chat';
  static const String aiSuggestions = '/ai/suggestions';
  static const String aiHealth = '/ai/health';
  static const String aiTest = '/ai/test';
  
  // Notification endpoints
  static const String fcmToken = '/users/fcm-token';
  static const String notificationSettings = '/users/notifications';

  // Project endpoints
  static const String projects = '/projects';
  static const String projectSuggestions = '/projects/suggestions';
  static const String suggestions = '/projects/suggestions';
  
  // Chat endpoints
  static const String chats = '/chat';
  static const String aiChatMessages = '/ai/chat';
  
  // User endpoints
  static const String users = '/users';
  static const String profile = '/users/profile';
  
  // File upload
  static const String upload = '/upload';
  
  // Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Default headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
  
  // Helper methods
  static String getProjectUrl(String projectId) => '$projects/$projectId';
  static String getJoinProjectUrl(String projectId) => '$projects/$projectId/join';
  static String getChatMessagesUrl(String chatId) => '$chats/$chatId/messages';
  static String getAIChatMessagesUrl(String projectId) => '$aiChatMessages/$projectId/messages';
  
  // ✅ Debug info
  static void printDebugInfo() {
    print('🔧 API Configuration:');
    print('   Base URL: $baseUrl');
    print('   Login: $baseUrl$login');
    print('   Register: $baseUrl$register');
    print('   Headers: $headers');
  }
}