import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';
import 'package:socialmedia_clone/app/modules/search/controllers/search_controller.dart' as search_controller;
import 'package:socialmedia_clone/app/widgets/loading_indicator.dart';
import 'package:socialmedia_clone/app/widgets/post_widget.dart';

class SearchView extends GetView<search_controller.SearchController> {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: controller.updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search users or posts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[200]
                        : Colors.grey[800],
                  ),
                ),
              ),
              // Search type toggle
              Obx(
                () => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'users',
                      label: Text('Users'),
                      icon: Icon(Icons.people),
                    ),
                    ButtonSegment(
                      value: 'posts',
                      label: Text('Posts'),
                      icon: Icon(Icons.post_add),
                    ),
                  ],
                  selected: {controller.searchType},
                  onSelectionChanged: (Set<String> selection) {
                    controller.setSearchType(selection.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        if (controller.searchQuery.isEmpty) {
          return const Center(
            child: Text('Search for users or posts'),
          );
        }

        if (controller.searchType == 'users') {
          if (controller.searchUsers.isEmpty) {
            return const Center(
              child: Text('No users found'),
            );
          }
          return _buildUsersList();
        } else {
          if (controller.searchPosts.isEmpty) {
            return const Center(
              child: Text('No posts found'),
            );
          }
          return _buildPostsList();
        }
      }),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      itemCount: controller.searchUsers.length,
      itemBuilder: (context, index) {
        final user = controller.searchUsers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(user.profileImageUrl),
            child: null,
          ),
          title: Text(user.username),
          onTap: () {
            Get.toNamed(
              '${Routes.profile}/${user.id}',
            );
          },
        );
      },
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      itemCount: controller.searchPosts.length,
      itemBuilder: (context, index) {
        final post = controller.searchPosts[index];
        return PostWidget(
          post: post,
          onLike: () {
            // TODO: Implement like functionality
            // We'll need to update the FeedController to handle this
          },
          onComment: () {
            // Navigate to comments
            Get.toNamed(
              '${Routes.comments}/${post.id}',
            );
          },
          onProfileTap: () {
            // Navigate to user profile
            Get.toNamed(
              '${Routes.profile}/${post.userId}',
            );
          },
        );
      },
    );
  }
}
