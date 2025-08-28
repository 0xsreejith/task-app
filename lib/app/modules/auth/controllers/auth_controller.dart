import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/bindings/main_binding.dart';
import 'package:socialmedia_clone/main.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show utf8;

class AuthController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final isLoading = false.obs;
  final isLogin = true.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkExistingAuth();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void _checkExistingAuth() {
    try {
      final currentUser = HiveService.getCurrentUser();
      if (currentUser != null) {
        _navigateToMain();
      }
    } catch (e) {
      debugPrint('Error checking existing auth: $e');
    }
  }

  void toggleAuthMode() {
    isLogin.toggle();
    _clearForm();
    _resetValidation();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.toggle();
  }

  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    confirmPasswordController.clear();
  }

  void _resetValidation() {
    formKey.currentState?.reset();
  }

  Future<void> submitForm() async {
    try {
      // First validate the form
      if (formKey.currentState == null || !formKey.currentState!.validate()) {
        debugPrint('Form validation failed');
        return;
      }

      // Save the form state
      formKey.currentState!.save();
      
      // Set loading state
      isLoading.value = true;
      
      // Process login or signup
      if (isLogin.value) {
        await _login();
      } else {
        await _signup();
      }
    } catch (e) {
      debugPrint('Error in submitForm: $e');
      _showErrorSnackbar(e.toString());
    } finally {
      if (isLoading.isTrue) {
        isLoading.value = false;
      }
    }
  }

  // Hardcoded mock user credentials
  static const String mockEmail = 'user@gmail.com';
  static const String mockPassword = 'Sree@20005';
  static const String mockUsername = 'testuser';
  
  // Hash password for storage
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verify password against hash
  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword || 
           password == hashedPassword; // Support legacy plain text
  }
  
  // Check if password meets strength requirements
  bool _isPasswordStrong(String password) {
    // At least 8 characters, one uppercase, one lowercase, one number
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }
  
  // Show error message
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
  
  // Show success message
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
  
  // Navigate to main screen
  Future<void> _navigateToMain() async {
    try {
      await Get.offAllNamed(Routes.main);
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to main: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _login() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    
    // Check for mock credentials
    if (email == mockEmail && password == mockPassword) {
      try {
        if (kDebugMode) {
          print('🔐 Mock login with hardcoded credentials');
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
        
        // Clear form and navigate
        _clearForm();
        await _navigateToMain();
        return;
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ Mock login error: $e');
        }
        _showErrorSnackbar('Mock login failed: $e');
        return;
      } finally {
        isLoading.value = false;
      }
    }

    try {
      if (kDebugMode) {
        print('🔐 Attempting login for email: $email');
      }

      // Input validation
      _validateLoginInputs(email, password);

      // Find user by email
      final user = await HiveService.findUserByEmail(email);
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user found with email: $email');
        }
        throw 'No account found with this email address';
      }

      // Verify password
      if (!_verifyPassword(password, user.password)) {
        if (kDebugMode) {
          print('❌ Incorrect password for user: ${user.email}');
        }
        throw 'Incorrect password. Please try again.';
      }

      // Set as logged in user
      await HiveService.setCurrentUser(user);
      
      // Update auth state in MainController
      final mainController = Get.find<MainController>();
      mainController.isAuthenticated.value = true;
      
      if (kDebugMode) {
        print('✅ Login successful for user: ${user.email}');
      }

      // Show success message
      _showSuccessSnackbar('Welcome back, ${user.username}!');

      // Clear form and navigate
      _clearForm();
      
      // Add a small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to main screen
      await _navigateToMain();

    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      _showErrorSnackbar(e.toString());
      rethrow;
    } finally {
      if (isLoading.isTrue) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _signup() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    final email = emailController.text.trim().toLowerCase();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    try {
      // Input validation
      _validateSignupInputs(email, username, password, confirmPassword);

      // Check password strength
      if (!_isPasswordStrong(password)) {
        throw 'Password must be at least 8 characters long and include a mix of letters, numbers, and special characters';
      }

      // Check if user with this email or username already exists
      final existingUser = await HiveService.findUserByEmail(email);
      if (existingUser != null) {
        throw 'An account with this email already exists';
      }

      // Check if username is already taken
      final usernameExists = await checkUsernameExists(username);
      if (usernameExists) {
        throw 'This username is already taken';
      }

      // Create new user with hashed password
      final newUser = UserModel(
        id: const Uuid().v4(),
        username: username,
        email: email,
        password: _hashPassword(password),
        profileImageUrl: _getDefaultProfileImage(),
        bio: '',
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        isFollowing: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Save new user to Hive
      await HiveService.saveNewUser(newUser);

      // Set as logged in user
      await HiveService.setCurrentUser(newUser);
      Get.find<MainController>().isAuthenticated.value = true;

      // Show success message
      _showSuccessSnackbar('Account created successfully! Welcome, ${newUser.username}!');

      // Clear form and navigate
      _clearForm();
      await _navigateToMain();

    } catch (e) {
      debugPrint('Signup error: $e');
      _showErrorSnackbar(e.toString());
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void _validateLoginInputs(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      throw 'Please enter both email and password';
    }

    if (!GetUtils.isEmail(email)) {
      throw 'Please enter a valid email address';
    }

    if (password.length < 8) {
      throw 'Password must be at least 8 characters long';
    }
  }

  void _validateSignupInputs(String email, String username, String password, String confirmPassword) {
    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw 'Please fill in all fields';
    }

    if (email.isEmpty) {
      throw 'Email is required';
    }

    if (!GetUtils.isEmail(email)) {
      throw 'Please enter a valid email';
    }

    if (password.isEmpty) {
      throw 'Password is required';
    }

    if (password.length < 8) {
      throw 'Password must be at least 8 characters long';
    }

    if (!_isPasswordStrong(password)) {
      throw 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }

    if (password != confirmPassword) {
      throw 'Passwords do not match';
    }
  }

  String _getDefaultProfileImage() {
    // Return a default avatar URL or empty string
    return 'https://ui-avatars.com/api/?name=${usernameController.text}&background=6366f1&color=fff&size=200';
  }
  
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }
  
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }
  
  Future<void> _navigateToMain() async {
    if (kDebugMode) {
      print('🔄 Attempting to navigate to main screen...');
      print('Current route: ${Get.currentRoute}');
    }
    
    try {
      // Add a small delay to ensure UI updates are processed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // First try with named route and proper predicate
      await Get.offAllNamed(
        Routes.main,
        predicate: (route) => route.settings.name == Routes.main,
      );
      
      // Force a rebuild of the main controller
      try {
        final mainController = Get.find<MainController>();
        mainController.update();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not update MainController: $e');
        }
      }
      
      if (kDebugMode) {
        print('✅ Successfully navigated to main screen');
        print('New route: ${Get.currentRoute}');
      }
      
      return;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Primary navigation failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
    
    // Fallback 1: Try with direct route name
    try {
      if (kDebugMode) {
        print('🔄 Attempting fallback navigation with direct route name...');
      }
      
      await Get.offAllNamed('/main');
      
      if (kDebugMode) {
        print('✅ Fallback navigation successful');
      }
      
      return;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Fallback navigation failed: $e');
      }
    }
    
    // Fallback 2: Try with direct widget instantiation
    try {
      if (kDebugMode) {
        print('🔄 Attempting fallback with direct widget instantiation...');
      }
      
      await Get.offAll(
        () => const MainScreen(),
        binding: MainBinding(),
        routeName: Routes.main,
      );
      
      if (kDebugMode) {
        print('✅ Direct widget navigation successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ All navigation attempts failed: $e');
        }
      }
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await HiveService.logout();
      final mainController = Get.find<MainController>();
      mainController.isAuthenticated.value = false;
      _clearForm();
      Get.offAllNamed(Routes.login);
      _showSuccessSnackbar('Logged out successfully');
    } catch (e) {
      _showErrorSnackbar('Error logging out: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Enhanced Form validation methods
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    
    final email = value.trim();
    
    if (!GetUtils.isEmail(email)) {
      return 'Please enter a valid email';
    }
    
    if (email.length > 254) {
      return 'Email is too long';
    }
    
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (isLogin.value) {
      return null; // For login, just check if not empty
    }
    
    // For signup, apply stronger validation
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (value.length > 128) {
      return 'Password is too long';
    }
    
    if (!_isPasswordStrong(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (isLogin.value) return null;
    
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  String? validateUsername(String? value) {
    if (isLogin.value) return null;
    
    if (value == null || value.trim().isEmpty) {
      return 'Please choose a username';
    }
    
    final username = value.trim();
    
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (username.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    if (RegExp(r'^\d+$').hasMatch(username)) {
      return 'Username cannot be only numbers';
    }
    
    return null;
  }

  // Utility methods
  bool get isFormValid {
    return formKey.currentState?.validate() ?? false;
  }

  void clearAllFields() {
    _clearForm();
    _resetValidation();
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final user = await HiveService.findUserByEmail(email.trim().toLowerCase());
      return user != null;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final users = await HiveService.getUsers();
      return users.any((user) => 
        user.username.toLowerCase() == username.trim().toLowerCase()
      );
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }
}