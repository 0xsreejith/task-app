import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/models/comment_model.dart' as comment_model;

class HiveService {
  static const String authBox = 'auth';
  static const String usersBox = 'users';
  static const String appSettingsBox = 'app_settings';
  static const String postsBox = 'posts';
  static const String commentsBox = 'comments';
  
  static Future<void> init() async {
    try {
      // Initialize Hive with the app's documents directory
      await Hive.initFlutter();
      
      // Register adapters with unique typeIds
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
      }
      
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PostModelAdapter());
      }
      
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(comment_model.CommentAdapter());
      }
      
      // Open boxes with error handling
      await _openBox(authBox);
      await _openBox(usersBox);
      await _openBox(appSettingsBox);
      await _openBox(postsBox);
      await _openBox(commentsBox);
      
      if (kDebugMode) {
        print('✅ Hive initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hive initialization failed: $e');
      }
      rethrow;
    }
  }
  
  // Helper method to open a Hive box with retry logic
  static Future<Box> _openBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
      
      // Try to open the box
      final box = await Hive.openBox(boxName);
      if (kDebugMode) {
        print('📦 Opened Hive box: $boxName');
      }
      return box;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening box $boxName: $e');
      }
      
      // If opening fails, try deleting the box and recreating it
      try {
        if (kDebugMode) {
          print('🔄 Attempting to delete and recreate box: $boxName');
        }
        await Hive.deleteBoxFromDisk(boxName);
        final newBox = await Hive.openBox(boxName);
        if (kDebugMode) {
          print('✅ Successfully recreated box: $boxName');
        }
        return newBox;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to recreate box $boxName: $e');
        }
        rethrow;
      }
    }
  }
  
  // Helper method to get a Hive box
  static Future<Box> _getBox(String boxName) async {
    try {
      return await _openBox(boxName);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _getBox($boxName): $e');
      }
      rethrow;
    }
  }
  
  // Auth methods
  static Future<void> saveUser(UserModel user, {bool saveToUsersBox = true}) async {
    if (kDebugMode) {
      print('💾 Saving user: ${user.email}');
    }
    
    try {
      final box = await _getBox(authBox);
      final userJson = user.toJson();
      
      if (kDebugMode) {
        print('📝 User JSON: $userJson');
      }
      
      await box.put('user', userJson);
      
      if (kDebugMode) {
        print('✅ User saved to auth box');
      }
      
      // Only save to users box if explicitly requested to prevent loops
      if (saveToUsersBox) {
        await saveNewUser(user, skipAuthSave: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving user: $e');
      }
      rethrow;
    }
  }
  
  static Future<void> setCurrentUser(UserModel user) async {
    if (kDebugMode) {
      print('🔐 Setting current user: ${user.email}');
    }
    
    try {
      // Ensure the auth box is open
      final authBoxInstance = await _getBox(authBox);
      
      // Convert user to JSON and save to auth box
      final userJson = user.toJson();
      if (kDebugMode) {
        print('📝 User JSON for auth box: $userJson');
      }
      
      await authBoxInstance.put('user', userJson);
      
      // Verify the user was saved to auth box
      final savedUser = authBoxInstance.get('user');
      if (savedUser == null) {
        throw 'Failed to save user to auth box';
      }
      
      // Save to users box
      final userBox = await _getBox(usersBox);
      await userBox.put(user.id, userJson);
      
      // Verify the user was saved to users box
      final savedInUsers = userBox.get(user.id);
      if (savedInUsers == null) {
        throw 'Failed to save user to users box';
      }
      
      if (kDebugMode) {
        print('✅ Successfully set current user: ${user.email}');
        print('🔑 User ID: ${user.id}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error setting current user: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
  
  static Future<UserModel?> getCurrentUser() async {
    try {
      final box = await _getBox(authBox);
      final userData = box.get('user');
      
      if (userData != null) {
        try {
          if (userData is Map) {
            return UserModel.fromJson(Map<String, dynamic>.from(userData));
          } else if (userData is UserModel) {
            return userData;
          } else if (userData is Map<dynamic, dynamic>) {
            return UserModel.fromJson(userData.cast<String, dynamic>());
          }
          debugPrint('Unexpected user data type: ${userData.runtimeType}');
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
  
  /// Synchronously gets the current user from Hive
  /// Returns null if user is not authenticated or if there's an error
  static UserModel? getCurrentUserSync() {
    try {
      if (!Hive.isBoxOpen(authBox)) {
        return null;
      }
      
      final box = Hive.box(authBox);
      final userData = box.get('user');
      
      if (userData != null) {
        try {
          if (userData is Map) {
            return UserModel.fromJson(Map<String, dynamic>.from(userData));
          } else if (userData is UserModel) {
            return userData;
          } else if (userData is Map<dynamic, dynamic>) {
            return UserModel.fromJson(userData.cast<String, dynamic>());
          }
          debugPrint('Unexpected user data type: ${userData.runtimeType}');
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user synchronously: $e');
      return null;
    }
  }
  
  static Future<void> updateUser(UserModel updatedUser) async {
    try {
      final box = await _getBox(authBox);
      await box.put('user', updatedUser.toJson());
      // Also update in users box
      await saveNewUser(updatedUser);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }
  
  static Future<void> logout() async {
    try {
      final box = await _getBox(authBox);
      await box.clear();
    } catch (e) {
      debugPrint('Error during logout: $e');
      rethrow;
    }
  }
  
  static Future<void> clearUser() async {
    try {
      final box = await _getBox(authBox);
      await box.delete('user');
    } catch (e) {
      debugPrint('Error clearing user: $e');
      rethrow;
    }
  }
  
  // User management methods
  static Future<void> saveNewUser(UserModel user, {bool skipAuthSave = false}) async {
    try {
      // Ensure the users box is open
      final userBox = await _getBox(usersBox);
      
      // Convert user to JSON and save to users box
      await userBox.put(user.id, user.toJson());
      
      if (kDebugMode) {
        print('Saved user to users box: ${user.id}');
        print('User data: ${user.toJson()}');
      }
      
      // Only save to auth box if not explicitly skipped
      if (!skipAuthSave) {
        await saveUser(user, saveToUsersBox: false);
      }
      
      // Verify the user was saved
      final savedUser = userBox.get(user.id);
      if (savedUser == null) {
        throw 'Failed to verify user was saved';
      }
      
      if (kDebugMode) {
        print('Successfully saved and verified new user: ${user.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveNewUser: $e');
      }
      rethrow;
    }
  }

  static Future<UserModel?> findUserByEmail(String email) async {
    try {
      if (!Hive.isBoxOpen(usersBox)) {
        await Hive.openBox(usersBox);
      }
      
      final box = Hive.box(usersBox);
      final users = box.values.toList();
      
      if (kDebugMode) {
        print('🔍 Searching for user with email: $email');
        print('📊 Total users in database: ${users.length}');
      }
      
      for (var userData in users) {
        try {
          if (userData == null) continue;
          
          // Handle different possible data types
          if (userData is UserModel) {
            if (userData.email.toLowerCase() == email.toLowerCase()) {
              if (kDebugMode) print('✅ Found user: ${userData.email}');
              return userData;
            }
          } 
          else if (userData is Map) {
            final userMap = userData is Map<String, dynamic> 
                ? userData 
                : Map<String, dynamic>.from(userData);
                
            if (userMap['email']?.toString().toLowerCase() == email.toLowerCase()) {
              if (kDebugMode) print('✅ Found user in map: ${userMap['email']}');
              return UserModel.fromJson(userMap);
            }
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Error processing user data: $e');
          continue;
        }
      }
      
      if (kDebugMode) print('❌ No user found with email: $email');
      return null;
    } catch (e) {
      if (kDebugMode) print('🔥 Error in findUserByEmail: $e');
      rethrow; // Rethrow to handle in the calling function
    }
  }
  
  // Users methods
  static Future<List<UserModel>> getUsers() async {
    // In a real app, this would fetch from a backend API
    // For now, return the current user if exists
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      return [currentUser];
    }
    return [];
  }
  
  // Post methods
  static Future<void> savePost(PostModel post) async {
    final box = Hive.box(postsBox);
    await box.put(post.id, post);
  }
  
  static Future<List<PostModel>> getPosts() async {
    final box = Hive.box(postsBox);
    return box.values.cast<PostModel>().toList();
  }
  
  static Future<PostModel?> getPost(String postId) async {
    final box = Hive.box(postsBox);
    return box.get(postId);
  }
  
  static Future<void> deletePost(String postId) async {
    final box = Hive.box(postsBox);
    await box.delete(postId);
  }
  
  // Comment methods
  static Future<void> saveComment(comment_model.Comment comment) async {
    final box = Hive.box(commentsBox);
    await box.put(comment.id, comment);
  }
  
  static Future<List<comment_model.Comment>> getComments() async {
    final box = Hive.box(commentsBox);
    return box.values.cast<comment_model.Comment>().toList();
  }
  
  static Future<comment_model.Comment?> getComment(String commentId) async {
    final box = Hive.box(commentsBox);
    return box.get(commentId);
  }
  
  static Future<void> deleteComment(String commentId) async {
    final box = Hive.box(commentsBox);
    await box.delete(commentId);
  }
  
  // Settings methods
  static Future<void> setDarkMode(bool value) async {
    final box = Hive.box(appSettingsBox);
    await box.put('isDarkMode', value);
  }
  
  static bool getDarkMode() {
    final box = Hive.box(appSettingsBox);
    return box.get('isDarkMode', defaultValue: false);
  }
}
