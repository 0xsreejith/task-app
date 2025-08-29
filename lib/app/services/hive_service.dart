import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/data/models/comment_model.dart' as comment_model;

class HiveService {
  // Box names
  static const String _userBox = 'user_box';
  static const String _commentsBox = 'comments_box';
  
  // Keys
  static const String _currentUserKey = 'current_user';
  static const String _commentsKey = 'comments';

  // Box instances
  static late Box _box;
  static late Box _commentsStorage;

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(comment_model.CommentAdapter());
      }
      
      _box = await Hive.openBox(_userBox);
      _commentsStorage = await Hive.openBox(_commentsBox);
      
      debugPrint('✅ HiveService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  // User related methods
  static Future<void> setCurrentUser(dynamic user) async {
    try {
      final UserModel userModel;
      if (user is UserModel) {
        userModel = user;
      } else if (user is Map<String, dynamic>) {
        userModel = UserModel.fromJson(user);
      } else {
        throw Exception('Invalid user data type: ${user.runtimeType}');
      }

      debugPrint('💾 Saving current user to Hive: ${userModel.email}');
      await _box.put(_currentUserKey, userModel.toJson());
      debugPrint('✅ Successfully saved current user');
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving current user: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<UserModel?> getCurrentUser() async {
    try {
      final userData = _box.get(_currentUserKey);
      if (userData == null) return null;

      if (userData is UserModel) {
        return userData;
      } else if (userData is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Get the current user synchronously
  static UserModel? getCurrentUserSync() {
    try {
      final userData = _box.get(_currentUserKey);
      if (userData == null) return null;

      if (userData is UserModel) {
        return userData;
      } else if (userData is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current user (sync): $e');
      return null;
    }
  }

  /// Delete the current user from Hive
  static Future<void> deleteCurrentUser() async {
    try {
      await _box.delete(_currentUserKey);
      debugPrint('✅ Current user deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting current user: $e');
      rethrow;
    }
  }

  /// Find a user by email
  static Future<UserModel?> findUserByEmail(String email) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser.email == email) {
        return currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error finding user by email: $e');
      return null;
    }
  }

  // Comment related methods
  static Future<void> saveComment(comment_model.Comment comment) async {
    try {
      final comments = _commentsStorage.get(_commentsKey, defaultValue: <Map>[]) as List;
      comments.add(comment.toJson());
      await _commentsStorage.put(_commentsKey, comments);
      debugPrint('✅ Comment saved: ${comment.id}');
    } catch (e) {
      debugPrint('❌ Error saving comment: $e');
      rethrow;
    }
  }

  /// Get all comments for a specific post
  static List<comment_model.Comment> getCommentsForPost(String postId) {
    try {
      final comments = _commentsStorage.get(_commentsKey, defaultValue: <Map>[]) as List;
      return comments
          .map((e) => comment_model.Comment.fromJson(Map<String, dynamic>.from(e)))
          .where((comment) => comment.postId == postId)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting comments for post: $e');
      return [];
    }
  }

  /// Delete a comment by its ID
  static Future<void> deleteComment(String commentId) async {
    try {
      final comments = _commentsStorage.get(_commentsKey, defaultValue: <Map>[]) as List;
      comments.removeWhere((c) => c['id'] == commentId);
      await _commentsStorage.put(_commentsKey, comments);
      debugPrint('✅ Comment deleted: $commentId');
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      rethrow;
    }
  }

  // Clear all data (for testing/logout)
  static Future<void> clearAllData() async {
    try {
      await _box.clear();
      await _commentsStorage.clear();
      debugPrint('✅ Cleared all Hive data');
    } catch (e) {
      debugPrint('❌ Error clearing Hive data: $e');
      rethrow;
    }
  }
}
