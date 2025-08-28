import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
import 'package:flutter/material.dart';

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
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      isAuthenticated.value = false;
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
    } catch (e) {
      debugPrint('Error during logout: $e');
      Get.snackbar('Error', 'Failed to logout');
    } finally {
      isLoading.value = false;
    }
  }
}
