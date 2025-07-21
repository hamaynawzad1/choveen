import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // ✅ ADD THIS for Color class
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // ✅ CRITICAL FIX: Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('🔔 Background message received: ${message.messageId}');
    await _showNotification(message);
  }

  // ✅ CRITICAL FIX: Proper initialization
  static Future<void> initialize() async {
    try {
      print('🚀 Initializing notification service...');

      // Initialize Firebase if not already done
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      // Request permissions first
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up Firebase messaging
      await _initializeFirebaseMessaging();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Notification service initialization failed: $e');
    }
  }

  // ✅ FIXED: Request permissions properly
  static Future<bool> _requestPermissions() async {
    try {
      print('📱 Requesting notification permissions...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permissions granted');
        
        // Save permission status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', true);
        
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Provisional notification permissions granted');
        return true;
      } else {
        print('❌ Notification permissions denied');
        
        // Save permission status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', false);
        
        return false;
      }
    } catch (e) {
      print('❌ Permission request failed: $e');
      return false;
    }
  }

  // ✅ FIXED: Local notifications initialization
  static Future<void> _initializeLocalNotifications() async {
    try {
      print('📲 Initializing local notifications...');

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Local notifications initialization failed: $e');
    }
  }

  // ✅ FIXED: Firebase messaging setup
  static Future<void> _initializeFirebaseMessaging() async {
    try {
      print('🔥 Setting up Firebase messaging...');

      // Set foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get and save FCM token
      await _updateFCMToken();

      // Listen for token updates
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      print('✅ Firebase messaging configured');
    } catch (e) {
      print('❌ Firebase messaging setup failed: $e');
    }
  }

  // ✅ FIXED: Foreground message handler
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received: ${message.messageId}');
    print('📨 Title: ${message.notification?.title}');
    print('📨 Body: ${message.notification?.body}');
    print('📨 Data: ${message.data}');

    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (notificationsEnabled) {
      await _showNotification(message);
    }
  }

  // ✅ FIXED: Show notification with proper formatting
  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'choveen_channel',
        'Choveen Notifications',
        channelDescription: 'Notifications for Choveen app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3), // Blue color
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Choveen',
        message.notification?.body ?? 'You have a new notification',
        details,
        payload: json.encode(message.data),
      );

      print('✅ Notification displayed successfully');
    } catch (e) {
      print('❌ Failed to show notification: $e');
    }
  }

  // ✅ FIXED: Notification tap handler
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        print('❌ Failed to parse notification payload: $e');
      }
    }
  }

  // ✅ FIXED: Handle notification tap when app is opened
  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 App opened from notification: ${message.messageId}');
    _handleNotificationData(message.data);
  }

  // ✅ NEW: Handle notification data and navigation
  static void _handleNotificationData(Map<String, dynamic> data) {
    print('📊 Processing notification data: $data');

    final type = data['type'] as String?;
    final projectId = data['project_id'] as String?;
    final messageId = data['message_id'] as String?;

    switch (type) {
      case 'project_message':
        if (projectId != null) {
          // Navigate to project chat
          _navigateToProjectChat(projectId);
        }
        break;
      case 'project_invite':
        if (projectId != null) {
          // Navigate to project details
          _navigateToProjectDetails(projectId);
        }
        break;
      case 'ai_response':
        if (projectId != null) {
          // Navigate to AI chat
          _navigateToAIChat(projectId);
        }
        break;
      default:
        // Navigate to home
        _navigateToHome();
    }
  }

  // ✅ NEW: Navigation helpers (implement based on your routing)
  static void _navigateToProjectChat(String projectId) {
    // TODO: Implement navigation to project chat
    print('🚀 Navigate to project chat: $projectId');
  }

  static void _navigateToProjectDetails(String projectId) {
    // TODO: Implement navigation to project details
    print('🚀 Navigate to project details: $projectId');
  }

  static void _navigateToAIChat(String projectId) {
    // TODO: Implement navigation to AI chat
    print('🚀 Navigate to AI chat: $projectId');
  }

  static void _navigateToHome() {
    // TODO: Implement navigation to home
    print('🚀 Navigate to home');
  }

  // ✅ FIXED: FCM token management
  static Future<void> _updateFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔑 FCM Token: $token');
        
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        
        // Send token to backend
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  // ✅ NEW: Send token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to save token
      print('📤 Sending FCM token to backend: $token');
      
      // Example implementation:
      // final authService = AuthService();
      // await authService.updateFCMToken(token);
      
    } catch (e) {
      print('❌ Failed to send token to backend: $e');
    }
  }

  // ✅ FIXED: Token refresh handler
  static Future<void> _onTokenRefresh(String token) async {
    print('🔄 FCM Token refreshed: $token');
    await _sendTokenToBackend(token);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // ✅ PUBLIC METHODS

  // Get current FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  // Enable/disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      
      if (enabled) {
        await _requestPermissions();
      }
      
      print('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Failed to update notification settings: $e');
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      print('❌ Failed to check notification settings: $e');
      return false;
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Failed to clear notifications: $e');
    }
  }

  // Show custom local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'choveen_local',
        'Choveen Local Notifications',
        channelDescription: 'Local notifications for Choveen app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: data != null ? json.encode(data) : null,
      );

      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Failed to show local notification: $e');
    }
  }

  // Schedule notification
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'choveen_scheduled',
        'Choveen Scheduled Notifications',
        channelDescription: 'Scheduled notifications for Choveen app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Note: You'll need to add flutter_local_notifications scheduling
      // This is a simplified version
      print('📅 Scheduled notification for: $scheduledDate');
      print('📅 Title: $title, Body: $body');
      
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
    }
  }

  // Get notification permission status
  static Future<String> getPermissionStatus() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus.toString();
    } catch (e) {
      print('❌ Failed to get permission status: $e');
      return 'unknown';
    }
  }

  // Handle app lifecycle changes
  static Future<void> handleAppStateChange(String state) async {
    print('📱 App state changed: $state');
    
    switch (state) {
      case 'resumed':
        // App came to foreground
        await clearAllNotifications();
        break;
      case 'paused':
        // App went to background
        break;
      case 'detached':
        // App is being terminated
        break;
    }
  }

  // Debug method to test notifications
  static Future<void> testNotification() async {
    await showLocalNotification(
      title: '🧪 Test Notification',
      body: 'This is a test notification from Choveen!',
      data: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
    );
  }
}