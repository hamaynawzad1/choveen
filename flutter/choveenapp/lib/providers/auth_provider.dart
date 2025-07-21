import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../core/services/backend_service.dart';


class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  final BackendService _backendService = BackendService();
  
  // ✅ FIXED: Update user profile with proper backend sync
  Future<void> updateUserProfile({
    required String name,
    required List<String> skills,
    String? profileImage,
  }) async {
    if (!_isAuthenticated || _user == null) {
      throw Exception('User not authenticated');
    }

    _setLoading(true);
    try {
      // Update via backend service for persistence
      final result = await _backendService.updateUserProfile(
        userId: _user!.id,
        name: name.trim(),
        skills: skills.where((skill) => skill.trim().isNotEmpty).toList(),
        profileImage: profileImage ?? _user!.profileImage,
      );

      if (result['success'] == true && result['user'] != null) {
        // Update local user object
        _user = User.fromJson(result['user']);
        
        // Save to local storage
        await _storage.saveUser(result['user']);
        
        // Notify listeners for UI update
        notifyListeners();
        
        // Try to sync with API backend (optional)
        try {
          await _authService.updateProfile(
            name: name,
            skills: skills,
            profileImage: profileImage,
          );
          print('✅ Profile synced with API backend');
        } catch (e) {
          print('⚠️ API sync failed, but local update successful');
        }
        
        _error = null;
        print('✅ Profile updated successfully: $name, ${skills.length} skills');
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _error = 'Failed to update profile: $e';
      print('❌ Profile update error: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Initialize backend on app start
  Future<void> initializeBackend() async {
    await _backendService.initializeDemoData();
  }
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.getToken();
      final userData = await _storage.getUser();
      
      if (token != null && userData != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Auth check error: $e');
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _authService.login(email, password);
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required List<String> skills,
    String? profileImage,
  }) async {
    _setLoading(true);
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        skills: skills,
        profileImage: profileImage,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyEmail(email, code);
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Force refresh user data
  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;
    
    try {
      final userData = await _storage.getUser();
      if (userData != null) {
        _user = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      print('User refresh error: $e');
    }
  }

  // ✅ NEW: Update profile picture only
  Future<void> updateProfilePicture(String imageUrl) async {
    if (!_isAuthenticated || _user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Update local user object
      final updatedUserData = {
        'id': _user!.id,
        'name': _user!.name,
        'email': _user!.email,
        'skills': _user!.skills,
        'profileImage': imageUrl,
        'isVerified': _user!.isVerified,
        'createdAt': _user!.createdAt,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      _user = User.fromJson(updatedUserData);
      await _storage.saveUser(updatedUserData);
      notifyListeners();

      // Sync with backend
      await _authService.updateProfile(profileImage: imageUrl);
      
    } catch (e) {
      print('Profile picture update error: $e');
      throw Exception('Failed to update profile picture: $e');
    }
  }

  // ✅ NEW: Get user stats
  Map<String, dynamic> getUserStats() {
    if (_user == null) return {};
    
    return {
      'skillCount': _user!.skills.length,
      'joinDate': _user!.createdAt,
      'lastUpdate': DateTime.now().toIso8601String(),
      'isVerified': _user!.isVerified,
    };
  }

  // ✅ NEW: Check if profile is complete
  bool isProfileComplete() {
    if (_user == null) return false;
    
    return _user!.name.isNotEmpty && 
           _user!.email.isNotEmpty && 
           _user!.skills.isNotEmpty;
  }

  // ✅ NEW: Add skill to user
  Future<void> addSkill(String skill) async {
    if (_user == null || skill.trim().isEmpty) return;
    
    final newSkills = List<String>.from(_user!.skills);
    if (!newSkills.contains(skill.trim())) {
      newSkills.add(skill.trim());
      await updateUserProfile(
        name: _user!.name,
        skills: newSkills,
      );
    }
  }

  // ✅ NEW: Remove skill from user
  Future<void> removeSkill(String skill) async {
    if (_user == null) return;
    
    final newSkills = List<String>.from(_user!.skills);
    newSkills.remove(skill);
    await updateUserProfile(
      name: _user!.name,
      skills: newSkills,
    );
  }
}