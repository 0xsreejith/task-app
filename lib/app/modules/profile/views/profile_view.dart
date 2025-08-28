import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPostImage(String imageUrl) {
    // Handle network images
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } 
    // Handle file paths (with or without file:// prefix)
    else if (imageUrl.startsWith('file:') || imageUrl.startsWith('/')) {
      try {
        final file = imageUrl.startsWith('file:') 
            ? File(Uri.parse(imageUrl).toFilePath())
            : File(imageUrl);
            
        return Image.file(
          file,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image file: $error');
            return _buildErrorWidget();
          },
        );
      } catch (e) {
        debugPrint('Error loading file: $e');
        return _buildErrorWidget();
      }
    }
    
    // Fallback for unsupported image types
    debugPrint('Unsupported image URL format: $imageUrl');
    return _buildErrorWidget();
  }
  
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      height: 300,
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.grey, size: 40),
      ),
    );
  }

  // Helper method to get the appropriate image provider
  ImageProvider? _getProfileImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('file:')) {
      return FileImage(File(Uri.parse(imageUrl).toFilePath()));
    } else if (imageUrl.startsWith('/') || imageUrl.startsWith('storage/')) {
      return FileImage(File(imageUrl));
    }
    
    // For any other case, try as a network image
    return NetworkImage(imageUrl);
  }

  // Profile stats column
  Widget _buildStatColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          controller.user?.username ?? 'Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        actions: [
          if (controller.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.user == null) {
          return const Center(child: Text('User not found'));
        }
        
        final user = controller.user!;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header
                    Row(
                      children: [
                        // Profile image
                        GestureDetector(
                          onTap: controller.isCurrentUser ? () => controller.pickAndUpdateProfileImage() : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _getProfileImage(user.profileImageUrl),
                            child: controller.isCurrentUser
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        
                        // Stats
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn('Posts', user.postsCount),
                              _buildStatColumn('Followers', user.followersCount),
                              _buildStatColumn('Following', user.followingCount),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // User info
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(user.bio),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Follow/Edit profile button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isCurrentUser
                            ? () => Get.to(() => const EditProfileView())
                            : controller.toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isCurrentUser
                              ? Colors.grey[200]
                              : Theme.of(context).primaryColor,
                          foregroundColor: controller.isCurrentUser
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (controller.isCurrentUser) 
                              const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              controller.isCurrentUser ? 'Edit Profile' : 'Follow',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on)),
                        Tab(icon: Icon(Icons.bookmark_border)),
                      ],
                      labelColor: Colors.black,
                      indicatorColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
            
            // Tab bar view
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Posts grid with pull-to-refresh
                  RefreshIndicator(
                    onRefresh: () => controller.loadUserProfile(),
                    child: Obx(() {
                      if (controller.isLoading && controller.userPosts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (controller.userPosts.isEmpty) {
                        return  Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library, size: 50, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No posts yet', style: TextStyle(fontSize: 16)),
                              if (controller.isCurrentUser) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Share your first photo or video',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          childAspectRatio: 1,
                        ),
                        itemCount: controller.userPosts.length,
                        itemBuilder: (context, index) {
                          final post = controller.userPosts[index];
                          return GestureDetector(
                            onTap: () => Get.toNamed('/post/${post.id}'),
                            child: Hero(
                              tag: 'post_${post.id}',
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Post image
                                  _buildPostImage(post.imageUrl),
                                  
                                  // Multiple posts indicator (placeholder for future implementation)
                                  // if (post.mediaUrls != null && post.mediaUrls!.length > 1)
                                  //   const Positioned(
                                  //     top: 8,
                                  //     right: 8,
                                  //     child: Icon(Icons.layers, color: Colors.white, size: 20),
                                  //   ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  
                  // Saved posts tab (placeholder)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 50, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Saved posts will appear here', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                          'Save photos and videos that you want to see again',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
  
}
