import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Initialize auth state
  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');

      if (token != null && userJson != null) {
        _token = token;
        final userData = json.decode(userJson);
        _user = User.fromJson(userData);
        print('✅ Auth state restored: ${_user?.email}');
      } else {
        print('📝 No saved auth state');
      }
    } catch (e) {
      print('❌ Auth initialization error: $e');
    }
    notifyListeners();
  }

  // Register user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required List<String> skills,
    String? profileImage,
  }) async {
    try {
      _setLoading(true);
      clearError();

      print('📡 Starting registration API call...');
      print('🔗 URL: ${ApiConstants.registerUrl}');
      
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'skills': skills,
        if (profileImage != null) 'profile_image': profileImage,
      };
      
      print('📤 Request body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(ApiConstants.timeout);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ Registration successful');
          _setLoading(false);
          return true;
        } else {
          _setError(data['message'] ?? 'Registration failed');
          return false;
        }
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['detail'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      _setError('Registration failed: $e');
      return false;
    }
  }

  // Verify email
  Future<bool> verifyEmail(String email, String code) async {
    try {
      _setLoading(true);
      clearError();

      print('📧 Verifying email...');
      print('📧 Email: $email');
      print('🔑 Code: $code');

      final response = await http.post(
        Uri.parse(ApiConstants.verifyEmailUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'verification_code': code,
        }),
      ).timeout(ApiConstants.timeout);

      print('📡 Verify response status: ${response.statusCode}');
      print('📡 Verify response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['access_token'] != null) {
          _token = data['access_token'];
          _user = User.fromJson(data['user']);
          
          // Save to preferences
          await _saveAuthData(_token!, _user!);
          
          print('✅ Email verification successful');
          _setLoading(false);
          return true;
        } else {
          _setError('Invalid response format');
          return false;
        }
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['detail'] ?? 'Email verification failed');
        return false;
      }
    } catch (e) {
      print('❌ Email verification error: $e');
      _setError('Email verification failed: $e');
      return false;
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      clearError();

      print('🔐 Starting login...');
      print('📧 Email: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConstants.timeout);

      print('📡 Login response status: ${response.statusCode}');
      print('📡 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['access_token'] != null && data['user'] != null) {
          _token = data['access_token'];
          _user = User.fromJson(data['user']);
          
          // Save to preferences
          await _saveAuthData(_token!, _user!);
          
          print('✅ Login successful');
          _setLoading(false);
          return true;
        } else {
          _setError('Invalid response format');
          return false;
        }
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['detail'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      _setError('Login failed: $e');
      return false;
    }
  }

  // Demo login
  Future<void> demoLogin() async {
    try {
      _setLoading(true);
      clearError();

      print('🎭 Demo login started');

      // Simulate demo user
      _user = User(
        id: 'demo_user_1',
        name: 'Demo User',
        email: 'demo@choveen.com',
        skills: ['Flutter', 'Python', 'AI', 'Project Management'],
        isVerified: true,
        createdAt: DateTime.now(),
      );

      _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';

      // Save demo data
      await _saveAuthData(_token!, _user!);

      print('✅ Demo login successful');
      _setLoading(false);
    } catch (e) {
      print('❌ Demo login error: $e');
      _setError('Demo login failed: $e');
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    List<String>? skills,
    String? profileImage,
  }) async {
    try {
      _setLoading(true);
      clearError();

      if (_user == null || _token == null) {
        _setError('Not authenticated');
        return false;
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (skills != null) body['skills'] = skills;
      if (profileImage != null) body['profile_image'] = profileImage;

      print('📡 Updating profile...');
      print('📤 Update body: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse(ApiConstants.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(body),
      ).timeout(ApiConstants.timeout);

      print('📡 Update response status: ${response.statusCode}');
      print('📡 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        
        // Update saved data
        await _saveAuthData(_token!, _user!);
        
        print('✅ Profile updated successfully');
        _setLoading(false);
        return true;
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['detail'] ?? 'Profile update failed');
        return false;
      }
    } catch (e) {
      print('❌ Profile update error: $e');
      _setError('Profile update failed: $e');
      return false;
    }
  }

  // Save auth data to preferences
  Future<void> _saveAuthData(String token, User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', json.encode(user.toJson()));
      print('💾 Auth data saved');
    } catch (e) {
      print('❌ Failed to save auth data: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      // Clear provider state
      _user = null;
      _token = null;
      _error = null;
      
      print('👋 User logged out');
      _setLoading(false);
    } catch (e) {
      print('❌ Logout error: $e');
      _setLoading(false);
    }
  }

  // Get current user from backend
  Future<void> getCurrentUser() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        await _saveAuthData(_token!, _user!);
        notifyListeners();
        print('✅ User data refreshed');
      } else {
        print('❌ Failed to get current user: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get current user error: $e');
    }
  }
}