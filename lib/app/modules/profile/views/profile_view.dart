import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
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
    debugPrint('Profile: Building post image with URL: $imageUrl');

    // Handle empty or null image URL
    if (imageUrl.isEmpty) {
      debugPrint('Post: Empty image URL');
      return _buildErrorWidget();
    }

    // Handle network images (http/https)
    if (imageUrl.startsWith('http')) {
      debugPrint('Profile: Loading network image: $imageUrl');
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          debugPrint('Failed to load network image: $imageUrl, error: $error');
          return _buildErrorWidget();
        },
      );
    }

    // For local files, use a FutureBuilder to handle async operations
    debugPrint('Profile: Loading local file: $imageUrl');
    return FutureBuilder<File?>(
      future: _getLocalImageFile(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            debugPrint(
              'Profile: Successfully loaded file: ${snapshot.data!.path}',
            );
            return Image.file(
              snapshot.data!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading file: $error');
                return _buildErrorWidget();
              },
            );
          }
          debugPrint('Profile: File not found for URL: $imageUrl');
          return _buildErrorWidget();
        }
        return _buildLoadingWidget();
      },
    );
  }

  Future<File?> _getLocalImageFile(String imageUrl) async {
    try {
      String? filePath;

      // Handle file:// URIs
      if (imageUrl.startsWith('file:')) {
        filePath = Uri.parse(imageUrl).toFilePath();
        debugPrint('Profile: Loading file URI: $filePath');
      }
      // Handle direct file paths
      else {
        filePath = imageUrl;
        debugPrint('Profile: Loading direct file: $filePath');
      }

      // Try to resolve the file
      final file = File(filePath);
      debugPrint('Profile: Checking if file exists: ${file.path}');

      // Check if file exists
      if (file.existsSync()) {
        debugPrint('Profile: File exists at: ${file.path}');
        return file;
      }

      debugPrint('Profile: File does not exist at: ${file.path}');

      // Try to find the file in the app's documents directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(filePath);
        final localFile = File('${appDir.path}/$fileName');

        debugPrint('Profile: Checking app directory: ${localFile.path}');

        if (localFile.existsSync()) {
          debugPrint('Profile: File found in app directory: ${localFile.path}');
          return localFile;
        } else {
          debugPrint(
            'Profile: File does not exist in app directory: ${localFile.path}',
          );
        }
      } catch (e) {
        debugPrint('Profile: Error checking app directory: $e');
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint(
        'Profile: Error getting local image file ($imageUrl): $e\n$stackTrace',
      );
      return null;
    }
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

  Widget _buildLoadingWidget() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
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
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext contexFt) {
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
        title: Obx(
          () => Text(
            controller.user?.username ?? 'Profile',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
                          onTap: controller.isCurrentUser
                              ? () => controller.pickAndUpdateProfileImage()
                              : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _getProfileImage(
                              user.profileImageUrl,
                            ),
                            child: controller.isCurrentUser
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 30,
                                    ),
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
                              _buildStatColumn(
                                'Followers',
                                user.followersCount,
                              ),
                              _buildStatColumn(
                                'Following',
                                user.followingCount,
                              ),
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
                              controller.isCurrentUser
                                  ? 'Edit Profile'
                                  : 'Follow',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                      if (controller.isLoading &&
                          controller.userPosts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (controller.userPosts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(fontSize: 16),
                              ),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                        Icon(
                          Icons.bookmark_border,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Saved posts will appear here',
                          style: TextStyle(fontSize: 16),
                        ),
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
