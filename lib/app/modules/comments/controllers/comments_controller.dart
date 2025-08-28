import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/data/models/comment_model.dart' as comment_model;
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart';
import 'package:uuid/uuid.dart';

class CommentsController extends GetxController {
  final String postId;
  CommentsController(this.postId);
  
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
      
      // TODO: Replace with actual API call
      // For now, we'll simulate loading comments
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get comments from Hive
      final allComments = await HiveService.getComments();
      _comments.value = allComments.where((c) => c.postId == postId).toList();
      
    } catch (e) {
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
      
      // Get current user (in a real app, this would come from auth)
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
      
      // Notify listeners
      update();
      
    } catch (e) {
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
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment');
    }
  }
}
