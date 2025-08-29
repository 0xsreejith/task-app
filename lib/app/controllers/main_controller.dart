import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/services/hive_service.dart';
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';

class MainController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool _isAuthenticated = false.obs;
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Completer<void> _authCompleter = Completer<void>();

  // Getters for auth state
  bool get authState => _isAuthenticated.value;
  RxBool get isAuthenticated => _isAuthenticated;

  // Set user and update auth state
  void setUser(UserModel? newUser) {
    user.value = newUser;
    _isAuthenticated.value = newUser != null;
    if (newUser == null) {
      HiveService.deleteCurrentUser();
    }
  }

  // Getter to wait for initial auth check to complete
  Future<void> get initialAuthCheck => _authCompleter.future;

  static MainController get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    debugPrint('MainController initialized');
    // Initialize with Home tab selected
    selectedIndex.value = 0;
    _checkAuthState();
  }

  @override
  void onReady() {
    super.onReady();
    // Listen to route changes
    ever(selectedIndex, _handleTabChange);
  }

  void _handleTabChange(int index) {
    // Handle any tab-specific logic here if needed
  }

  // Public method to manually refresh auth state
  Future<void> refreshAuthState() async {
    await _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      debugPrint('🔍 Starting auth state check...');
      isLoading.value = true;

      try {
        debugPrint('🔐 Getting current user from Hive...');
        final userData = await HiveService.getCurrentUser();

        if (userData != null) {
          debugPrint('✅ Found authenticated user: ${userData.email}');
          user.value = userData;
          _isAuthenticated.value = true;
          debugPrint(
            '👤 User details - ID: ${userData.id}, Username: ${userData.username}',
          );
        } else {
          debugPrint('⚠️ No authenticated user found');
          user.value = null;
          _isAuthenticated.value = false;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error getting current user: $e');
        debugPrint('Stack trace: $stackTrace');
        _isAuthenticated.value = false;
      }

      // Complete the auth completer if not already completed
      if (!_authCompleter.isCompleted) {
        _authCompleter.complete();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in _checkAuthState: $e');
        print('Stack trace: $stackTrace');
      }
      _isAuthenticated.value = false;
      if (!_authCompleter.isCompleted) {
        _authCompleter.completeError(e, stackTrace);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    if (index != selectedIndex.value) {
      selectedIndex.value = index;
      // Force rebuild of the current tab
      update();
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔄 Starting logout process...');
      
      // Clear user data
      await HiveService.deleteCurrentUser();
      setUser(null);
      
      // Clear any cached data
      if (Get.isRegistered<FeedController>()) {
        final feedController = Get.find<FeedController>();
        feedController.posts.clear();
      }
      
      // Clear all routes and navigate to login screen
      await Future.delayed(Duration.zero); // Ensure UI updates
      Get.offAllNamed(
        Routes.login,
        predicate: (route) => false, // Remove all previous routes
      );
      
      debugPrint('✅ Logout completed successfully');
      
      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    }
  }
}
