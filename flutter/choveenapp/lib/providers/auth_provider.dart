// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../core/services/backend_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BackendService _backendService = BackendService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  String? _token;

  // Getters
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  String? get token => _token;
  String? get userId => _user?['id'];

  // ✅ Initialize auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Check if user is already logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _token = await _authService.getToken();
        final userData = await _authService.getUserData();
        
        if (userData.isNotEmpty) {
          _user = userData;
          _isLoggedIn = true;
          print('✅ User restored from storage: ${_user!['name']}');
        }
      }
      
      _error = null;
    } catch (e) {
      print('❌ Auth Provider initialization error: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        _user = result['user'];
        _token = result['token'];
        _isLoggedIn = true;
        _error = null;
        
        print('✅ User logged in successfully: ${_user!['name']}');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Login error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Register user
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.register(name, email, password);
      
      if (result['success'] == true) {
        // If registration includes automatic login
        if (result['user'] != null) {
          _user = result['user'];
          _isLoggedIn = true;
          
          // Get token if provided
          if (result['token'] != null) {
            _token = result['token'];
          }
        }
        
        _error = null;
        print('✅ User registered successfully: $name');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Registration error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    _setLoading(true);
    try {
      if (_user == null) {
        _error = 'No user logged in';
        notifyListeners();
        return false;
      }

      final result = await _backendService.updateUserProfile(_user!['id'], userData);
      
      if (result['success'] == true) {
        _user = result['user'];
        _error = null;
        
        print('✅ Profile updated successfully');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Profile update failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Profile update error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      
      _user = null;
      _token = null;
      _isLoggedIn = false;
      _error = null;
      
      print('✅ User logged out successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ Logout error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Verify email
  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    try {
      final result = await _authService.verifyEmail(email, code);
      
      if (result['success'] == true) {
        _error = null;
        print('✅ Email verified successfully');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Email verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Email verification error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      final result = await _authService.changePassword(currentPassword, newPassword);
      
      if (result['success'] == true) {
        _error = null;
        print('✅ Password changed successfully');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Password change failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Password change error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      final result = await _authService.forgotPassword(email);
      
      if (result['success'] == true) {
        _error = null;
        print('✅ Password reset instructions sent');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to send reset instructions';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Forgot password error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Reset password
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _setLoading(true);
    try {
      final result = await _authService.resetPassword(email, code, newPassword);
      
      if (result['success'] == true) {
        _error = null;
        print('✅ Password reset successfully');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Password reset failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Password reset error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Delete account
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    try {
      final result = await _authService.deleteAccount(password);
      
      if (result['success'] == true) {
        _user = null;
        _token = null;
        _isLoggedIn = false;
        _error = null;
        
        print('✅ Account deleted successfully');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Account deletion failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Account deletion error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Refresh token
  Future<bool> refreshToken() async {
    try {
      final result = await _authService.refreshToken();
      
      if (result['success'] == true) {
        _token = result['token'];
        print('✅ Token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    }
  }

  // ✅ Validate token
  Future<bool> validateToken() async {
    try {
      return await _authService.validateToken();
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  // ✅ Update FCM token
  Future<void> updateFCMToken(String fcmToken) async {
    try {
      await _authService.updateFCMToken(fcmToken);
      print('✅ FCM token updated');
    } catch (e) {
      print('❌ FCM token update error: $e');
    }
  }

  // ✅ Get current user
  Future<void> getCurrentUser() async {
    _setLoading(true);
    try {
      final result = await _authService.getCurrentUser();
      
      if (result['success'] == true) {
        _user = result['user'];
        _isLoggedIn = true;
        _error = null;
        
        print('✅ Current user retrieved');
        notifyListeners();
      } else {
        _error = result['message'] ?? 'Failed to get current user';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Get current user error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Quick login for demo
  Future<void> demoLogin() async {
    _setLoading(true);
    try {
      // Set demo user data
      _user = {
        'id': 'user_demo_1',
        'name': 'Demo User',
        'email': 'demo@choveen.com',
        'skills': ['Flutter', 'Dart', 'Mobile Development'],
        'avatar': 'https://via.placeholder.com/150?text=DU',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      _isLoggedIn = true;
      _error = null;
      
      // Save to auth service
      await _authService.login('demo@choveen.com', 'demo123');
      
      print('✅ Demo login successful');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ Demo login error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _user = null;
    _token = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  // ✅ User convenience methods
  String get userName => _user?['name'] ?? 'User';
  String get userEmail => _user?['email'] ?? '';
  String get userAvatar => _user?['avatar'] ?? 'https://via.placeholder.com/150';
  List<String> get userSkills => List<String>.from(_user?['skills'] ?? []);
  
  bool get hasSkill => userSkills.isNotEmpty;
  bool get isProfileComplete => _user != null && 
      _user!['name'] != null && 
      _user!['email'] != null;
}