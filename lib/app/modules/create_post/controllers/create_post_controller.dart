import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/data/providers/local/hive_service.dart'
    as data_hive;
import 'package:socialmedia_clone/app/services/hive_service.dart' as auth_hive;
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';

class CreatePostController extends GetxController {
  final captionController = TextEditingController();
  final isPosting = false.obs;
  final selectedImage = Rxn<File>();
  final errorMessage = ''.obs;
  final ImagePicker _picker = ImagePicker();
  final formKey = GlobalKey<FormState>();

  @override
  void onClose() {
    captionController.dispose();
    errorMessage.close();
    super.onClose();
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> createPost() async {
    errorMessage.value = '';

    if (selectedImage.value == null) {
      errorMessage.value = 'Please select an image';
      return;
    }

    if (captionController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter a caption';
      return;
    }

    try {
      isPosting.value = true;

      final currentUser = await auth_hive.HiveService.getCurrentUser();
      if (currentUser == null) {
        // Not authenticated; let middleware handle routing
        return;
      }

      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newImagePath = '${appDir.path}/$fileName';

      // Copy the image to app's documents directory
      await selectedImage.value!.copy(newImagePath);

      // Store the path relative to the app's documents directory
      final String imageUrl = fileName;

      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.id,
        username: currentUser.username,
        userAvatar: currentUser.profileImageUrl,
        imageUrl: imageUrl,
        caption: captionController.text.trim(),
        likes: 0,
        isLiked: false,
        comments: [],
        createdAt: DateTime.now(),
      );

      await data_hive.HiveService.savePost(newPost);

      // Refresh the feed
      if (Get.isRegistered<FeedController>()) {
        final feedController = Get.find<FeedController>();
        // Add the new post to the beginning of the list
        feedController.posts.insert(0, newPost);
      }

      // Clear the form
      captionController.clear();
      selectedImage.value = null;

      // Navigate back to feed
      Get.back(result: true);

      Get.snackbar(
        'Success',
        'Post created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create post. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPosting.value = false;
    }
  }

  // Form validation
  String? validateCaption(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a caption';
    }
    if (value.length > 500) {
      return 'Caption is too long (max 500 characters)';
    }
    return null;
  }
}
