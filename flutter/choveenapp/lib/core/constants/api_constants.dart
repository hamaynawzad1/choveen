class APIConstants {
  static const String baseUrl = 'http://192.168.100.100:8000'; // Change to your backend URL
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  // Auth endpoints - FIXED URLs
  static const String login = '/api/v1/auth/login';        // ✅ Fixed
  static const String register = '/api/v1/auth/register';
  static const String verifyEmail = '/api/v1/auth/verify-email';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';
  
  // Project endpoints
  static const String projects = '/api/v1/projects';
  static const String suggestions = '/api/v1/projects/suggestions';
  
  // User endpoints
  static const String users = '/api/v1/users';
  static const String profile = '/api/v1/users/profile';
  
  // Chat endpoints
  static const String chats = '/api/v1/chats';
  static const String messages = '/api/v1/messages';
  
  // AI endpoints
  static const String aiChat = '/api/v1/ai/chat';
}