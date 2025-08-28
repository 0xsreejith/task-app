import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/modules/feed/controllers/feed_controller.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/widgets/post_widget.dart';
import 'package:socialmedia_clone/app/services/hive_service.dart';
import 'package:socialmedia_clone/app/data/models/user_model.dart';

class FeedView extends GetView<FeedController> {
  const FeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Get.toNamed(Routes.createPost),
            tooltip: 'Create Post',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: HiveService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = snapshot.data;
          if (currentUser == null) {
            // AuthMiddleware should have prevented this; show info only
            return const Center(
              child: Text('Session not available. Please restart the app.'),
            );
          }

          return Obx(() {
            if (controller.isLoading.value && controller.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No posts yet.\nBe the first to post!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Create First Post'),
                      onPressed: () => Get.toNamed(Routes.createPost),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadPosts,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16.0),
                itemCount: controller.posts.length,
                itemBuilder: (context, index) {
                  final post = controller.posts[index];

                  return PostWidget(
                    post: post,
                    onLike: () => controller.toggleLike(post.id),
                    onComment: () {
                      Get.toNamed(
                        '${Routes.comments}/${post.id}',
                        arguments: post,
                      );
                    },
                    onProfileTap: () {
                      final userId = post.userId;
                      if (userId == currentUser.id) {
                        final mainController = Get.find<MainController>();
                        mainController.changeTab(1);
                      } else {
                        Get.toNamed(
                          '${Routes.profile}/$userId',
                          arguments: userId,
                        );
                      }
                    },
                  );
                },
              ),
            );
          });
        },
      ),
    );
  }
}
