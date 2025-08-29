import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class MockAuthService {
  // Hardcoded mock user credentials
  static const String mockEmail = 'admin@gmail.com';
  static const String mockPassword = 'Sree@2005';
  static const String mockUsername = 'testuser';

  // Hash password for storage
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if provided credentials match mock credentials
  static bool isMockUser(String email, String password) {
    return email.toLowerCase() == mockEmail && password == mockPassword;
  }

  // Perform mock login
  static Future<void> mockLogin() async {
    try {
      if (kDebugMode) {
        print('🔐 Attempting mock login with hardcoded credentials');
      }
      
      // Create a mock user
      final mockUser = UserModel(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        email: mockEmail,
        username: mockUsername,
        password: _hashPassword(mockPassword),
        profileImageUrl: '',
        bio: 'Mock user for testing',
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isFollowing: false,
      );
      
      // Save the mock user
      await HiveService.setCurrentUser(mockUser);
      
      // Update auth state
      Get.find<MainController>().isAuthenticated.value = true;
      
      if (kDebugMode) {
        print('✅ Mock login successful');
      }
      
      // Navigate to main screen
      await _navigateToMain();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mock login error: $e');
      }
      rethrow;
    }
  }
  
  // Navigate to main screen
  static Future<void> _navigateToMain() async {
    try {
      await Get.offAllNamed(Routes.main);
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to main: $e');
      }
      rethrow;
    }
  }
}
