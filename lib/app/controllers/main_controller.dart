import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';

class MainController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool _isAuthenticated = false.obs;
  final Completer<void> _authCompleter = Completer<void>();
  
  // Getter for auth state
  bool get authState => _isAuthenticated.value;
  RxBool get isAuthenticated => _isAuthenticated;
  
  // Getter to wait for initial auth check to complete
  Future<void> get initialAuthCheck => _authCompleter.future;
  
  static MainController get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    debugPrint('MainController initialized');
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
  
  Future<void> _checkAuthState() async {
    try {
      if (kDebugMode) {
        print('🔍 Starting auth state check...');
      }
      
      isLoading.value = true;
      final user = await HiveService.getCurrentUser();
      _isAuthenticated.value = user != null;
      
      if (kDebugMode) {
        print(_isAuthenticated.value 
          ? '✅ User is authenticated: ${user?.email}'
          : '🔐 No authenticated user found');
      }
      
      // Complete the auth completer if not already completed
      if (!_authCompleter.isCompleted) {
        _authCompleter.complete();
      }
      
      // Handle routing based on auth state
      if (_isAuthenticated.value) {
        // If user is authenticated, go to main screen if not already there
        if (Get.currentRoute == Routes.login || Get.currentRoute == '/') {
          if (kDebugMode) {
            print('🔄 Redirecting to main screen');
          }
          // Use a small delay to ensure UI is built before navigation
          await Future.delayed(const Duration(milliseconds: 100));
          Get.offAllNamed(Routes.main);
        }
      } else {
        // If user is not authenticated, go to login screen if not already there
        if (Get.currentRoute != Routes.login) {
          if (kDebugMode) {
            print('🔒 User not authenticated, redirecting to login');
          }
          // Use a small delay to ensure UI is built before navigation
          await Future.delayed(const Duration(milliseconds: 100));
          Get.offAllNamed(Routes.login);
        }
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
      Get.offAllNamed(Routes.login);
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    if (index != selectedIndex.value) {
      selectedIndex.value = index;
    }
  }
  
  void logout() {
    try {
      HiveService.logout();
      _isAuthenticated.value = false;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout');
    }
  }
}
