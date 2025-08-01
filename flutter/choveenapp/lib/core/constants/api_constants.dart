// lib/core/constants/api_constants.dart
class APIConstants {
  // ✅ Base URLs for different environments
  static const String _baseUrlDevelopment = 'http://localhost:8000/api';
  static const String _baseUrlProduction = 'https://your-api-domain.com/api';
  static const String _baseUrlStaging = 'https://staging-api-domain.com/api';

  // ✅ Current environment - change this based on your setup
  static const String baseUrl = _baseUrlDevelopment;

  // ✅ API Endpoints
  static const String authEndpoint = '/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String logoutEndpoint = '$authEndpoint/logout';
  static const String refreshTokenEndpoint = '$authEndpoint/refresh';

  static const String usersEndpoint = '/users';
  static const String userProfileEndpoint = '$usersEndpoint/me';
  static const String updateProfileEndpoint = '$usersEndpoint/me';

  static const String projectsEndpoint = '/projects';
  static const String createProjectEndpoint = projectsEndpoint;
  static const String userProjectsEndpoint = '$projectsEndpoint/user';

  static const String chatEndpoint = '/chat';
  static const String chatListEndpoint = chatEndpoint;
  static const String chatMessagesEndpoint = '$chatEndpoint/{chatId}/messages';

  static const String aiEndpoint = '/ai';
  static const String aiChatEndpoint = '$aiEndpoint/chat';
  static const String aiSuggestionsEndpoint = '$aiEndpoint/suggestions';

  // ✅ Request timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 10);

  // ✅ API Response codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int noContentCode = 204;
  static const int badRequestCode = 400;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int internalServerErrorCode = 500;

  // ✅ Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String appSettingsKey = 'app_settings';

  // ✅ Request headers
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String acceptHeader = 'Accept';
  static const String bearerPrefix = 'Bearer ';

  // ✅ Content types
  static const String jsonContentType = 'application/json';
  static const String formDataContentType = 'multipart/form-data';
  static const String urlEncodedContentType = 'application/x-www-form-urlencoded';

  // ✅ Error messages
  static const String networkErrorMessage = 'Network connection error';
  static const String timeoutErrorMessage = 'Request timeout';
  static const String unauthorizedErrorMessage = 'Unauthorized access';
  static const String serverErrorMessage = 'Server error occurred';
  static const String unknownErrorMessage = 'An unknown error occurred';

  // ✅ Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ✅ Chat constants
  static const int maxMessageLength = 1000;
  static const int chatHistoryLimit = 100;
  static const String aiAssistantId = 'ai_assistant';

  // ✅ File upload constants
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp'
  ];
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ];

  // ✅ Validation constants
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 255;

  // ✅ Cache constants
  static const Duration cacheExpiration = Duration(hours: 1);
  static const String cacheKeyPrefix = 'choveen_cache_';

  // ✅ Notification constants
  static const String fcmTokenKey = 'fcm_token';
  static const String notificationChannelId = 'choveen_notifications';
  static const String notificationChannelName = 'Choveen Notifications';

  // ✅ App configuration
  static const String appName = 'Choveen';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@choveen.com';

  // ✅ Social login
  static const String googleClientId = 'your-google-client-id';
  static const String facebookAppId = 'your-facebook-app-id';

  // ✅ Analytics
  static const String analyticsApiKey = 'your-analytics-key';
  static const bool enableAnalytics = true;

  // ✅ Feature flags
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;
  static const bool enableDarkMode = true;
  static const bool enableBiometricAuth = false;

  // ✅ AI Configuration
  static const int aiResponseTimeout = 30; // seconds
  static const int maxConversationHistory = 10;
  static const String defaultAIModel = 'deepseek-chat';

  // ✅ Helper methods
  static String getChatMessagesUrl(String chatId) {
    return chatMessagesEndpoint.replaceAll('{chatId}', chatId);
  }

  static String getProjectUrl(String projectId) {
    return '$projectsEndpoint/$projectId';
  }

  static String getUserUrl(String userId) {
    return '$usersEndpoint/$userId';
  }

  static Map<String, String> getDefaultHeaders() {
    return {
      contentTypeHeader: jsonContentType,
      acceptHeader: jsonContentType,
    };
  }

  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...getDefaultHeaders(),
      authorizationHeader: '$bearerPrefix$token',
    };
  }

  // ✅ Environment detection
  static bool get isDevelopment => baseUrl == _baseUrlDevelopment;
  static bool get isProduction => baseUrl == _baseUrlProduction;
  static bool get isStaging => baseUrl == _baseUrlStaging;

  // ✅ Debug settings
  static bool get enableLogging => isDevelopment;
  static bool get enableDetailedErrors => isDevelopment;
}