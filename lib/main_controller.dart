import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:flutter/material.dart';

// Add this line to ensure MainController is properly initialized
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

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      isLoading.value = true;
      final user = await HiveService.getCurrentUser();
      isAuthenticated.value = user != null;

      if (!isAuthenticated.value) {
        // Only navigate to login if not already there to prevent infinite loops
        if (Get.currentRoute != Routes.login) {
          Get.offAllNamed(Routes.login);
        }
      }
      // If authenticated, MainScreen will be shown automatically
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      isAuthenticated.value = false;
      if (Get.currentRoute != Routes.login) {
        Get.offAllNamed(Routes.login);
      }
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
      final user = await HiveService.getCurrentUser();
      isAuthenticated.value = user != null;
      
      if (isAuthenticated.value) {
        // Navigate to main screen
        Get.offAllNamed(Routes.main);
      }
    } catch (e) {
      debugPrint('Error handling login: $e');
      isAuthenticated.value = false;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await HiveService.logout();
      isAuthenticated.value = false;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      debugPrint('Error during logout: $e');
      Get.snackbar('Error', 'Failed to logout');
    } finally {
      isLoading.value = false;
    }
  }
}
