// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final APIService _apiService = APIService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() {
    _loadUserFromStorage();
    _testBackendConnection(); // ✅ Test connection on startup
  }
  
  // ✅ Test backend connection
  Future<void> _testBackendConnection() async {
    try {
      final isConnected = await _apiService.testConnection();
      print(isConnected ? '✅ Backend connected' : '❌ Backend not accessible');
    } catch (e) {
      print('⚠️ Backend connection test failed: $e');
    }
  }
  
  // Load user from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final token = prefs.getString('auth_token');
      
      if (userData != null && token != null) {
        final userJson = json.decode(userData);
        _user = User.fromJson(userJson);
        print('✅ User loaded from storage: ${_user?.email}');
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user from storage: $e');
    }
  }
  
  // Save user to local storage
  Future<void> _saveUserToStorage(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(user.toJson()));
      await prefs.setString('auth_token', token);
      print('✅ User saved to storage');
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }
  
  // Clear user from local storage
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      print('✅ User cleared from storage');
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }
  
  // ✅ Login with proper endpoint
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🔐 Attempting login with fixed endpoint...');
      print('📧 Email: $email');
      print('🌐 URL: ${APIConstants.baseUrl}${APIConstants.login}');
      
      final response = await _apiService.post(APIConstants.login, body: {
        'email': email,
        'password': password,
      });
      
      print('📦 Login response: $response');
      
      if (response['access_token'] != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        await _saveUserToStorage(_user!, response['access_token']);
        _setLoading(false);
        print('✅ Login successful');
        return true;
      } else {
        _setError('Invalid response from server');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // ✅ Register with proper endpoint
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required List<String> skills,
    String? profileImage,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('📝 Attempting registration...');
      print('📧 Email: $email');
      print('👤 Name: $name');
      print('🌐 URL: ${APIConstants.baseUrl}${APIConstants.register}');
      
      final response = await _apiService.post(APIConstants.register, body: {
        'name': name,
        'email': email,
        'password': password,
        'skills': skills,
        'profile_image': profileImage,
      });
      
      print('📦 Registration response: $response');
      
      if (response['success'] == true) {
        _setLoading(false);
        print('✅ Registration successful');
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // ✅ Verify email with proper endpoint
  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('✉️ Attempting email verification...');
      print('📧 Email: $email');
      print('🔢 Code: $code');
      print('🌐 URL: ${APIConstants.baseUrl}${APIConstants.verifyEmail}');
      
      final response = await _apiService.post(APIConstants.verifyEmail, body: {
        'email': email,
        'verification_code': code,
      });
      
      print('📦 Verification response: $response');
      
      if (response['access_token'] != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        await _saveUserToStorage(_user!, response['access_token']);
        _setLoading(false);
        print('✅ Email verification successful');
        return true;
      } else {
        _setError('Verification failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Verification error: $e');
      _setError('Verification failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Demo login (unchanged but with logging)
  Future<bool> demoLogin() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🎭 Demo login started...');
      
      // Simulate demo user
      final demoUser = User(
        id: 'demo_user_123',
        name: 'Demo User',
        email: 'demo@example.com',
        skills: ['Flutter', 'Dart', 'Firebase', 'UI/UX'],
        isVerified: true,
        createdAt: DateTime.now(),
      );
      
      _user = demoUser;
      await _saveUserToStorage(_user!, 'demo_token_123');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      _setLoading(false);
      print('✅ Demo login successful');
      return true;
    } catch (e) {
      print('❌ Demo login error: $e');
      _setError('Demo login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // ✅ Update user profile with proper endpoint
  Future<bool> updateUserProfile({
    String? name,
    List<String>? skills,
    String? profileImage,
  }) async {
    if (_user == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('👤 Updating user profile...');
      
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (skills != null) updateData['skills'] = skills;
      if (profileImage != null) updateData['profile_image'] = profileImage;
      
      print('📤 Update data: $updateData');
      print('🌐 URL: ${APIConstants.baseUrl}${APIConstants.profile}');
      
      final response = await _apiService.put(APIConstants.profile, body: updateData);
      
      print('📦 Profile update response: $response');
      
      if (response['id'] != null) {
        _user = User.fromJson(response);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        await _saveUserToStorage(_user!, token);
        _setLoading(false);
        print('✅ Profile updated successfully');
        return true;
      } else {
        // Fallback: update locally
        print('⚠️ Server update failed, updating locally');
        if (name != null) _user = _user!.copyWith(name: name);
        if (skills != null) _user = _user!.copyWith(skills: skills);
        if (profileImage != null) _user = _user!.copyWith(profileImage: profileImage);
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        await _saveUserToStorage(_user!, token);
        
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      print('❌ Profile update error: $e');
      // Fallback: update locally
      if (name != null) _user = _user!.copyWith(name: name);
      if (skills != null) _user = _user!.copyWith(skills: skills);
      if (profileImage != null) _user = _user!.copyWith(profileImage: profileImage);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      await _saveUserToStorage(_user!, token);
      
      notifyListeners();
      _setLoading(false);
      return true;
    }
  }
  
  // ✅ Get current user with proper endpoint
  Future<void> getCurrentUser() async {
    if (_user == null) return;
    
    try {
      print('👤 Fetching current user info...');
      print('🌐 URL: ${APIConstants.baseUrl}${APIConstants.me}');
      
      final response = await _apiService.get(APIConstants.me);
      
      print('📦 Current user response: $response');
      
      if (response['id'] != null) {
        _user = User.fromJson(response);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        await _saveUserToStorage(_user!, token);
        notifyListeners();
        print('✅ User info refreshed');
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
      // Keep existing user data if refresh fails
    }
  }
  
  // ✅ Logout with proper endpoint
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      print('🚪 Logging out...');
      // Try to logout from server (optional)
      await _apiService.post(APIConstants.logout);
      print('✅ Server logout successful');
    } catch (e) {
      print('⚠️ Server logout failed: $e');
    }
    
    // Clear local data regardless of server response
    _user = null;
    await _clearUserFromStorage();
    
    _setLoading(false);
    print('✅ Local logout completed');
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearError() {
    _clearError();
  }
  
  // ✅ Debug method
  void printDebugInfo() {
    print('\n🔍 AUTH PROVIDER DEBUG INFO:');
    print('   User: ${_user?.email ?? 'null'}');
    print('   Authenticated: $isAuthenticated');
    print('   Loading: $isLoading');
    print('   Error: ${_error ?? 'none'}');
    print('   Base URL: ${APIConstants.baseUrl}');
    print('');
  }
}