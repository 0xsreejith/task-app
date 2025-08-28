import 'dart:async';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';

class FeedController extends GetxController {
  final RxList<PostModel> posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  Future<void> loadPosts() async {
    try {
      if (posts.isEmpty) {
        isLoading.value = true;
      } else {
        isRefreshing.value = true;
      }

      // Get current user
      final currentUser = HiveService.getCurrentUser();
      if (currentUser == null) {
        Get.offAllNamed(Routes.login);
        return;
      }

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Get posts from Hive
      final fetchedPosts = await HiveService.getPosts();
      
      // Sort by creation date (newest first)
      fetchedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Update the reactive list
      posts.value = fetchedPosts;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load posts',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshPosts() async {
    await loadPosts();
  }

  void navigateToCreatePost() {
    Get.toNamed(Routes.createPost);
  }

  Future<void> logout() async {
    try {
      // Clear user data
      await HiveService.logout();
      
      // Update MainController authentication state
      final mainController = Get.find<MainController>();
      mainController.isAuthenticated.value = false;
      
      // Use Future.delayed to avoid navigation lock
      Future.delayed(Duration.zero, () {
        Get.offAllNamed(Routes.login);
      });
      
      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToComments(PostModel post) {
    Get.toNamed('${Routes.comments}/${post.id}');
  }

  void navigateToProfile(String userId) {
    Get.toNamed('${Routes.profile}/$userId');
  }

  Future<void> toggleLike(String postId) async {
    try {
      final currentUser = HiveService.getCurrentUser();
      if (currentUser == null) {
        Get.offAllNamed(Routes.login);
        return;
      }
      
      final postIndex = posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = posts[postIndex];
        final updatedPost = post.copyWith(
          isLiked: !post.isLiked,
          likes: post.isLiked ? post.likes - 1 : post.likes + 1,
        );
        
        posts[postIndex] = updatedPost;
        await HiveService.savePost(updatedPost);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to like post',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
