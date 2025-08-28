import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';

class ProfileController extends GetxController {
  // User data
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  UserModel? get user => _user.value;
  
  // User posts
  final RxList<PostModel> _userPosts = <PostModel>[].obs;
  List<PostModel> get userPosts => _userPosts;
  
  // Loading states
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  
  final RxBool _isCurrentUser = true.obs;
  bool get isCurrentUser => _isCurrentUser.value;
  
  @override
  void onInit() {
    super.onInit();
    // Get userId from arguments if provided
    final String? userId = Get.arguments as String?;
    loadUserProfile(userId: userId);
  }
  
  // Load user profile data
  Future<void> loadUserProfile({String? userId}) async {
    try {
      _isLoading.value = true;
      
      // If no userId is provided, get current user
      if (userId == null || userId.isEmpty) {
        final currentUser = await HiveService.getCurrentUser();
        if (currentUser != null) {
          _user.value = currentUser;
          _isCurrentUser.value = true;
          // Load current user's posts
          await _loadUserPosts(userId: currentUser.id);
        } else {
          // No user logged in, navigate to login
          Get.offAllNamed('/login');
        }
      } else {
        // Load user by ID
        final user = await _getUserById(userId);
        if (user != null) {
          _user.value = user;
          _isCurrentUser.value = false;
          // Load user's posts
          await _loadUserPosts(userId: userId);
        } else {
          throw 'User not found';
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile');
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get user by ID from Hive
  Future<UserModel?> _getUserById(String userId) async {
    try {
      final box = await Hive.openBox('users');
      final userData = box.get(userId);
      if (userData != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Load user's posts
  Future<void> _loadUserPosts({String? userId}) async {
    try {
      if (userId == null) {
        _userPosts.clear();
        _isLoading.value = false;
        return;
      }
      
      final box = await Hive.openBox('posts');
      final allPosts = box.values.toList();
      
      print('Loading posts for user $userId');
      print('Total posts in database: ${allPosts.length}');
      
      final userPosts = allPosts
          .where((post) {
            // Handle both Map and PostModel cases
            if (post is Map) {
              return post['userId'] == userId;
            } else if (post is PostModel) {
              return post.userId == userId;
            }
            return false;
          })
          .map((post) {
            // Convert to PostModel if it's a Map
            final postModel = post is Map 
                ? PostModel.fromJson(Map<String, dynamic>.from(post)) 
                : post as PostModel;
                
            // Debug log the post data
            print('Post ID: ${postModel.id}');
            print('Image URL: ${postModel.imageUrl}');
            print('User ID: ${postModel.userId}');
            print('---');
            
            return postModel;
          })
          .toList();
          
      print('Found ${userPosts.length} posts for user $userId');
      _userPosts.value = userPosts;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load posts');
      rethrow; // Rethrow to be caught by the calling function
    }
  }
  
  // Update user profile
  Future<void> updateProfile({
    required String username,
    required String bio,
    File? imageFile,
  }) async {
    try {
      _isLoading.value = true;
      
      final currentUser = _user.value;
      if (currentUser == null) return;
      
      // Handle image file
      String? imageUrl = currentUser.profileImageUrl;
      if (imageFile != null) {
        try {
          // Save image to app's documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'profile_${currentUser.id}${path.extension(imageFile.path)}';
          final savedImage = await imageFile.copy('${appDir.path}/$fileName');
          imageUrl = savedImage.path;
        } catch (e) {
          Get.snackbar('Warning', 'Failed to save profile image, using previous one');
        }
      }
      
      // Create updated user
      final updatedUser = currentUser.copyWith(
        username: username,
        bio: bio,
        profileImageUrl: imageUrl,
      );
      
      // Save updated user
      await HiveService.updateUser(updatedUser);
      
      // Update local state
      _user.value = updatedUser;
      
      // Update posts if username changed
      if (currentUser.username != username) {
        await _updatePostsWithNewUsername(userId: currentUser.id, newUsername: username);
      }
      
      // Refresh the user data
      await loadUserProfile(userId: currentUser.id);
      
      // Navigate back
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.back(); // Return to profile screen
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Update posts with new username when username changes
  Future<void> _updatePostsWithNewUsername({required String userId, required String newUsername}) async {
    try {
      final box = await Hive.openBox<PostModel>('posts');
      final userPosts = box.values.where((post) => post.userId == userId).toList();
      
      for (final post in userPosts) {
        final updatedPost = post.copyWith(
          username: newUsername,
        );
        await box.put(post.id, updatedPost);
      }
      
      // Refresh the posts list
      _userPosts.assignAll(box.values.where((post) => post.userId == userId).toList());
    } catch (e) {
      Get.snackbar('Error', 'Failed to update posts with new username');
      rethrow;
    }
  }
  
  // Toggle follow status
  Future<void> toggleFollow() async {
    if (_user.value == null) return;
    
    try {
      final updatedUser = _user.value!.toggleFollow();
      _user.value = updatedUser;
      
      // TODO: Update follow status in backend
      
      // Update user in local storage if it's the current user
      if (_isCurrentUser.value) {
        await HiveService.saveUser(updatedUser);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update follow status');
    }
  }
  
  // Logout
  void logout() {
    HiveService.clearUser();
    Get.offAllNamed('/login'); // Using direct route name instead of Routes constant
  }

  // Pick and update profile image
  Future<void> pickAndUpdateProfileImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        _isLoading.value = true;
        
        // Get the app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        // Update user's profile image
        final updatedUser = _user.value!.copyWith(profileImageUrl: savedImage.path);
        await _updateUser(updatedUser);
        
        _user.value = updatedUser;
        _isLoading.value = false;
      }
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar('Error', 'Failed to update profile image');
    }
  }

  // Update user in Hive
  Future<void> _updateUser(UserModel user) async {
    try {
      final box = await Hive.openBox('users');
      await box.put(user.id, user.toJson());
      // Update current user in Hive if it's the current user
      final currentUser = await HiveService.getCurrentUser();
      if (currentUser != null && user.id == currentUser.id) {
        await HiveService.setCurrentUser(user);
      }
    } catch (e) {
      throw Exception('Failed to update user');
    }
  }
}
