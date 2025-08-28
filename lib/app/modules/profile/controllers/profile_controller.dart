import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';
import 'package:socialmedia_clone/app/services/hive_service.dart' as auth_hive;

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
        final currentUser = await auth_hive.HiveService.getCurrentUser();
        if (currentUser != null) {
          _user.value = currentUser;
          _isCurrentUser.value = true;
          // Load current user's posts
          await _loadUserPosts(userId: currentUser.id);
        } else {
          // No session; leave view in empty state, middleware handles routing
          _user.value = null;
          _userPosts.clear();
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

      final userPosts = allPosts
          .where((post) {
            if (post is Map) {
              return post['userId'] == userId;
            } else if (post is PostModel) {
              return post.userId == userId;
            }
            return false;
          })
          .map((post) {
            final postModel = post is Map
                ? PostModel.fromJson(Map<String, dynamic>.from(post))
                : post as PostModel;
            return postModel;
          })
          .toList();

      _userPosts.value = userPosts;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load posts');
      rethrow;
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
          final appDir = await getApplicationDocumentsDirectory();
          final fileName =
              'profile_${currentUser.id}${path.extension(imageFile.path)}';
          final savedImage = await imageFile.copy('${appDir.path}/$fileName');
          imageUrl = savedImage.path;
        } catch (e) {
          Get.snackbar(
            'Warning',
            'Failed to save profile image, using previous one',
          );
        }
      }

      final updatedUser = currentUser.copyWith(
        username: username,
        bio: bio,
        profileImageUrl: imageUrl,
      );

      await auth_hive.HiveService.setCurrentUser(updatedUser);

      _user.value = updatedUser;

      if (currentUser.username != username) {
        await _updatePostsWithNewUsername(
          userId: currentUser.id,
          newUsername: username,
        );
      }

      await loadUserProfile(userId: currentUser.id);

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.back();
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _updatePostsWithNewUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      final box = await Hive.openBox<PostModel>('posts');
      final userPosts = box.values
          .where((post) => post.userId == userId)
          .toList();

      for (final post in userPosts) {
        final updatedPost = post.copyWith(username: newUsername);
        await box.put(post.id, updatedPost);
      }

      _userPosts.assignAll(
        box.values.where((post) => post.userId == userId).toList(),
      );
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
      if (_isCurrentUser.value) {
        await auth_hive.HiveService.setCurrentUser(updatedUser);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update follow status');
    }
  }

  // Logout
  Future<void> logout() async {
    await auth_hive.HiveService.deleteCurrentUser();
    // Do not navigate; middleware will redirect when needed
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
        final fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(
          image.path,
        ).copy('${appDir.path}/$fileName');

        // Update user's profile image
        final updatedUser = _user.value!.copyWith(
          profileImageUrl: savedImage.path,
        );
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
      final currentUser = await auth_hive.HiveService.getCurrentUser();
      if (currentUser != null && user.id == currentUser.id) {
        await auth_hive.HiveService.setCurrentUser(user);
      }
    } catch (e) {
      throw Exception('Failed to update user');
    }
  }
}
