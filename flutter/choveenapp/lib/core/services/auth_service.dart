import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      requireAuth: false,
    );
    
    if (response['access_token'] != null) {
      await _storage.saveToken(response['access_token']);
      await _storage.saveUser(response['user']);
    }
    
    return response;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required List<String> skills,
    String? profileImage,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'skills': skills,
    };
    
    if (profileImage != null) {
      body['profile_image'] = profileImage;
    }
    
    return await _apiService.post(
      ApiConstants.register,
      body: body,
      requireAuth: false,
    );
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final response = await _apiService.post(
      ApiConstants.verifyEmail,
      body: {'email': email, 'verification_code': code},
      requireAuth: false,
    );
    
    // Save user data after verification
    if (response['access_token'] != null) {
      await _storage.saveToken(response['access_token']);
      await _storage.saveUser(response['user']);
    }
    
    return response;
  }

  // ✅ NEW: Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    List<String>? skills,
    String? profileImage,
  }) async {
    final body = <String, dynamic>{};
    
    if (name != null) body['name'] = name;
    if (skills != null) body['skills'] = skills;
    if (profileImage != null) body['profile_image'] = profileImage;
    
    final response = await _apiService.post(
      ApiConstants.updateProfile, // You need to add this to ApiConstants
      body: body,
      requireAuth: true,
    );
    
    // Update stored user data
    if (response['user'] != null) {
      await _storage.saveUser(response['user']);
    }
    
    return response;
  }

  // ✅ NEW: Update FCM token for notifications
  Future<void> updateFCMToken(String token) async {
    try {
      await _apiService.post(
        '${ApiConstants.users}/fcm-token',
        body: {'fcm_token': token},
        requireAuth: true,
      );
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // ✅ NEW: Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.users}/me',
        requireAuth: true,
      );
      
      if (response['data'] != null) {
        await _storage.saveUser(response['data']);
        return response['data'];
      }
      
      return null;
    } catch (e) {
      print('Failed to get current user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }
}