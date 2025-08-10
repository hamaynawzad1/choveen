// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';

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
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.post('/api/v1/auth/login', body: {
        'email': email,
        'password': password,
      });
      
      if (response['access_token'] != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        await _saveUserToStorage(_user!, response['access_token']);
        _setLoading(false);
        return true;
      } else {
        _setError('Invalid response from server');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Register
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
      final response = await _apiService.post('/api/v1/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'skills': skills,
        'profile_image': profileImage,
      });
      
      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Verify email
  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.post('/api/v1/auth/verify-email', body: {
        'email': email,
        'verification_code': code,
      });
      
      if (response['access_token'] != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        await _saveUserToStorage(_user!, response['access_token']);
        _setLoading(false);
        return true;
      } else {
        _setError('Verification failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Verification failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Demo login
  Future<bool> demoLogin() async {
    _setLoading(true);
    _clearError();
    
    try {
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
      return true;
    } catch (e) {
      _setError('Demo login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    List<String>? skills,
    String? profileImage,
  }) async {
    if (_user == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (skills != null) updateData['skills'] = skills;
      if (profileImage != null) updateData['profile_image'] = profileImage;
      
      final response = await _apiService.put('/api/v1/users/profile', body: updateData);
      
      if (response['id'] != null) {
        _user = User.fromJson(response);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        await _saveUserToStorage(_user!, token);
        _setLoading(false);
        return true;
      } else {
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
    } catch (e) {
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
  
  // Get current user (refresh from server)
  Future<void> getCurrentUser() async {
    if (_user == null) return;
    
    try {
      final response = await _apiService.get('/api/v1/auth/me');
      
      if (response['id'] != null) {
        _user = User.fromJson(response);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        await _saveUserToStorage(_user!, token);
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
      // Keep existing user data if refresh fails
    }
  }
  
  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      // Try to logout from server (optional)
      await _apiService.post('/api/v1/auth/logout');
    } catch (e) {
      print('Server logout failed: $e');
    }
    
    // Clear local data regardless of server response
    _user = null;
    await _clearUserFromStorage();
    
    _setLoading(false);
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
}