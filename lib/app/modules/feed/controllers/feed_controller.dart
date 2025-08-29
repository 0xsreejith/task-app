import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart'
    as data_hive;
import 'package:socialmedia_clone/app/services/hive_service.dart' as auth_hive;
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';

class FeedController extends GetxController {
  final RxList<PostModel> posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load posts when controller initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPosts();
    });
  }

  Future<void> loadPosts() async {
    try {
      // Only show loading indicator if we don't have any posts yet
      if (posts.isEmpty) {
        isLoading.value = true;
      } else {
        isRefreshing.value = true;
      }

      // Notify listeners that we're loading
      update();

      // Get current user (auth storage)
      final currentUser = await auth_hive.HiveService.getCurrentUser();
      if (currentUser == null) {
        // Not authenticated; let AuthMiddleware handle routing
        return;
      }

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Get posts from legacy provider
      final fetchedPosts = await data_hive.HiveService.getPosts();

      if (fetchedPosts.isNotEmpty) {
        // Sort by creation date (newest first)
        fetchedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Update the reactive list
        posts.value = fetchedPosts;
      } else {
        // If no posts, clear the list
        posts.clear();
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading posts: $e\n$stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load posts: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshPosts() async {
    await loadPosts();
  }

  /// Clears all posts from the feed
  Future<void> clearAllPosts() async {
    try {
      // Clear the posts list
      posts.clear();
      
      // Show success message
      Get.snackbar(
        'Success',
        'All posts have been cleared',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear posts: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToCreatePost() {
    Get.toNamed(Routes.createPost);
  }

  Future<void> logout() async {
    try {
      // Clear user data (auth storage)
      await auth_hive.HiveService.deleteCurrentUser();

      // Update MainController authentication state
      final mainController = Get.find<MainController>();
      mainController.isAuthenticated.value = false;

      // Use Future.delayed to avoid navigation lock
      // Let middleware/initial route handle navigation on next build

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
      final currentUser = await auth_hive.HiveService.getCurrentUser();
      if (currentUser == null) {
        // Not authenticated; ignore action
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
        await data_hive.HiveService.savePost(updatedPost);
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
