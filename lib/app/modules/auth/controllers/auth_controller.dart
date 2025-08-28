import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/services/hive_service.dart';

class AuthController extends GetxController {
  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // UI state
  final isLoading = false.obs;
  final isLogin = true.obs;
  final isPasswordVisible = false.obs;

  // Mock user data - these should match the default admin in HiveService
  static const String mockEmail = 'admin@gmail.com';
  static const String mockPassword = 'Sree@2005';

  @override
  void onInit() {
    super.onInit();
    _checkExistingAuth();
  }

  @override
  void onClose() {
    // Clean up controllers
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void _checkExistingAuth() async {
    try {
      debugPrint('🔍 Checking for existing auth session...');
      final currentUser = await HiveService.getCurrentUser();

      if (currentUser != null) {
        debugPrint('✅ Found existing session for user: ${currentUser.email}');
        debugPrint('🔄 Navigating to main screen...');
        if (Get.currentRoute != Routes.main) {
          await Get.offAllNamed(Routes.main);
        }
      } else {
        debugPrint('ℹ️ No existing session found');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking existing auth: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Toggle between login and signup mode
  void toggleAuthMode() {
    isLogin.toggle();
    emailController.clear();
    passwordController.clear();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  // Show error message
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Show success message
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Handle form submission
  Future<void> submitForm() async {
    if (isLoading.value) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    isLoading.value = true;

    try {
      // Check if it's a login attempt
      if (isLogin.value) {
        await _login(email, password);
      } else {
        // For signup, we'll just show a message since we're doing mock login
        _showError('Please use the login with the provided mock credentials');
      }
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Handle login with mock data
  Future<void> _login(String email, String password) async {
    try {
      debugPrint('🔑 Attempting login with email: $email');

      // Find user by email
      debugPrint('🔍 Looking up user in database...');
      final user = await HiveService.findUserByEmail(email);

      if (user != null) {
        debugPrint('✅ User found: ${user.email}');
        debugPrint('🔐 Verifying password...');

        // Check if user exists and password matches
        if (email == mockEmail && password == mockPassword) {
          debugPrint('🔑 Password verified');

          // Save user to Hive as current user
          debugPrint('💾 Saving user session...');
          await HiveService.setCurrentUser(user);

          // Verify user was saved
          final currentUser = await HiveService.getCurrentUser();
          debugPrint(
            '👤 Current user after save: ${currentUser?.email ?? 'None'}',
          );
          if (currentUser == null) {
            debugPrint('❌ Failed to retrieve current user after save');
          }

          debugPrint('🔄 Navigating to main screen...');
          // Navigate to main screen and remove all previous routes
          await Get.offAllNamed(
            Routes.main,
            predicate: (route) => false, // This removes all previous routes
          );

          debugPrint('🎉 Login successful!');
          // Show welcome message
          _showSuccess('Welcome back, ${user.username}!');
        } else {
          debugPrint('❌ Invalid password');
          _showError(
            'Invalid email or password. Use admin@gmail.com / Sree@2005',
          );
        }
      } else {
        debugPrint('❌ User not found with email: $email');
        _showError(
          'Invalid email or password. Use admin@gmail.com / Sree@2005',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e\n$stackTrace');
      _showError('An error occurred during login. Please try again.');
    }
  }

  // Simple logout function
  Future<void> logout() async {
    try {
      // Clear current user from Hive
      await HiveService.deleteCurrentUser();

      // Clear form fields
      emailController.clear();
      passwordController.clear();

      // Toggle back to login view
      isLogin.value = true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      _showError('Failed to logout. Please try again.');
    }
  }
}
