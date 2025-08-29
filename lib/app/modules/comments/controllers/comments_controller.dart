import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/comment_model.dart'
    as comment_model;
import 'package:socialmedia_clone/app/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class CommentsController extends GetxController {
  final String postId;
  CommentsController(this.postId);

  @override
  String get tag => postId;

  // Comments list
  final RxList<comment_model.Comment> _comments = <comment_model.Comment>[].obs;
  List<comment_model.Comment> get comments => _comments;

  // Comment text controller
  final TextEditingController commentController = TextEditingController();

  // Loading states
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  final RxBool _isPosting = false.obs;
  bool get isPosting => _isPosting.value;

  @override
  void onInit() {
    super.onInit();
    loadComments();
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  // Load comments for the post
  Future<void> loadComments() async {
    try {
      _isLoading.value = true;
      
      // Get comments from Hive
      final comments = await HiveService.getCommentsForPost(postId);
      _comments.value = comments;
      
      debugPrint('✅ Loaded ${comments.length} comments for post $postId');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading comments: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar('Error', 'Failed to load comments');
    } finally {
      _isLoading.value = false;
    }
  }

  // Add a new comment
  Future<void> addComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    try {
      _isPosting.value = true;

      // Get current user
      final currentUser = await HiveService.getCurrentUser();
      if (currentUser == null) {
        Get.snackbar('Error', 'Please login to comment');
        return;
      }

      // Create new comment
      final newComment = comment_model.Comment(
        id: const Uuid().v4(),
        postId: postId,
        userId: currentUser.id,
        username: currentUser.username,
        userAvatar: currentUser.profileImageUrl,
        text: text,
      );

      // Save comment to Hive
      await HiveService.saveComment(newComment);

      // Update local list
      _comments.insert(0, newComment);

      // Clear text field
      commentController.clear();

      // Refresh comments
      await loadComments();
      
      debugPrint('Successfully added comment to post $postId');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      Get.snackbar('Error', 'Failed to post comment');
    } finally {
      _isPosting.value = false;
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      // In a real app, check if current user is the author or has permission
      await HiveService.deleteComment(commentId);
      _comments.removeWhere((c) => c.id == commentId);
      update();
      debugPrint('Successfully deleted comment $commentId');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      Get.snackbar('Error', 'Failed to delete comment');
    }
  }
}
