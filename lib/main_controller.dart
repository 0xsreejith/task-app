import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/services/hive_service.dart' as auth_hive;
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController(), fenix: true);
  }
}

class MainController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxInt selectedIndex = 0.obs;
  final RxBool isAuthenticated = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      isLoading.value = true;
      final user = await auth_hive.HiveService.getCurrentUser();
      isAuthenticated.value = user != null;
      currentUser.value = user;
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      isAuthenticated.value = false;
      currentUser.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    if (index != selectedIndex.value) {
      selectedIndex.value = index;
    }
  }

  Future<void> handleSuccessfulLogin() async {
    try {
      isLoading.value = true;
      final user = await auth_hive.HiveService.getCurrentUser();
      isAuthenticated.value = user != null;
      currentUser.value = user;
    } catch (e) {
      debugPrint('Error handling login: $e');
      isAuthenticated.value = false;
      currentUser.value = null;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      
      // Clear user data
      await auth_hive.HiveService.deleteCurrentUser();
      currentUser.value = null;
      isAuthenticated.value = false;
      
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
      
      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Ensure loading is always set to false
      isLoading.value = false;
    }
  }
}
