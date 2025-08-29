import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:socialmedia_clone/app/controllers/main_controller.dart';
import 'package:socialmedia_clone/app/data/models/post_model.dart';
import 'package:socialmedia_clone/app/routes/app_pages.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  Future<void> _handleCommentTap() async {
    try {
      debugPrint('=== Comment button tapped ===');
      final mainController = Get.find<MainController>();
      
      // Refresh auth state to ensure it's up to date
      await mainController.refreshAuthState();
      
      // Debug: Print current user and auth state
      debugPrint('Current user: ${mainController.user.value?.toJson()}');
      debugPrint('isAuthenticated: ${mainController.isAuthenticated.value}');
      debugPrint('User value is null: ${mainController.user.value == null}');
      
      // If user is logged in, proceed with comment action
      if (mainController.user.value != null && mainController.isAuthenticated.value) {
        debugPrint('User is authenticated, proceeding with comment');
        onComment();
        return;
      }
      
      // If we get here, user is not properly authenticated
      debugPrint('User not properly authenticated, showing login prompt');
      
      // Show login prompt
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to be logged in to comment. Would you like to log in now?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Log In'),
            ),
          ],
        ),
      );

      if (result == true) {
        // Navigate to login screen
        Get.toNamed(Routes.login);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _handleCommentTap: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to process comment action. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
  final VoidCallback onProfileTap;
  final bool showFullCaption;

  const PostWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onProfileTap,
    this.showFullCaption = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildPostImage(ThemeData theme) {
    // Handle empty or null image URL
    if (post.imageUrl.isEmpty) {
      debugPrint('Post ${post.id}: Empty image URL');
      return _buildErrorWidget();
    }

    // Handle network images (http/https)
    if (post.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: post.imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          debugPrint('Failed to load network image: $url, error: $error');
          return _buildErrorWidget();
        },
      );
    }
    
    // For local files, use a FutureBuilder to handle async operations
    return FutureBuilder<File?>(
      future: _getLocalImageFile(post.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
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
        debugPrint('Loading file URI: $filePath');
      } 
      // Handle direct file paths
      else {
        filePath = imageUrl;
        debugPrint('Loading direct file: $filePath');
      }
      
      // Try to resolve the file
      final file = File(filePath);
      
      // Check if file exists
      if (file.existsSync()) {
        return file;
      }
      
      // Try to find the file in the app's documents directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(filePath);
        final localFile = File('${appDir.path}/$fileName');
        
        if (localFile.existsSync()) {
          return localFile;
        } else {
          debugPrint('File does not exist: ${localFile.path}');
        }
      } catch (e) {
        debugPrint('Error checking app directory: $e');
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting local image file ($imageUrl): $e\n$stackTrace');
      return null;
    }
  }


  Future<void> _reportPost() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Report Post'),
          content: const Text('Are you sure you want to report this post?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Report', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (result == true) {
        // Show loading indicator
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Simulate API call to report the post
        await Future.delayed(const Duration(seconds: 1));

        // Close loading dialog
        Get.back();

        // Show success message
        Get.snackbar(
          'Report Submitted',
          'Thank you for reporting this post. We will review it shortly.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) Get.back();
      
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to report post. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Colors.red),
            title: const Text('Report Post', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _reportPost();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      height: 300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
  
  Future<ImageProvider?> _getProfileImage(String imageUrl) async {
    if (imageUrl.isEmpty) {
      debugPrint('Post: Empty profile image URL provided');
      return null;
    }

    try {
      // Handle network images
      if (imageUrl.startsWith('http')) {
        debugPrint('Post: Loading network image: $imageUrl');
        return NetworkImage(imageUrl);
      }
      
      // Handle file URIs
      if (imageUrl.startsWith('file:')) {
        debugPrint('Post: Loading file URI: $imageUrl');
        final filePath = Uri.parse(imageUrl).toFilePath();
        final file = File(filePath);
        if (await file.exists()) {
          return FileImage(file);
        }
      }
      
      // Handle direct file paths
      if (imageUrl.startsWith('/') || imageUrl.startsWith('storage/')) {
        debugPrint('Post: Loading direct file: $imageUrl');
        final file = File(imageUrl);
        if (await file.exists()) {
          return FileImage(file);
        }
      }
      
      // Handle content URIs (common for gallery images on Android)
      if (imageUrl.startsWith('content:')) {
        debugPrint('Post: Loading content URI: $imageUrl');
        return NetworkImage(imageUrl);
      }
      
      debugPrint('Post: Unsupported image URL format: $imageUrl');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error loading profile image ($imageUrl): $e\n$stackTrace');
      return null;
    }
  }

  
  // Helper method to get image provider synchronously
  ImageProvider _getProfileImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const AssetImage('assets/images/placeholder.png');
    }

    try {
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl);
      } else if (imageUrl.startsWith('file:')) {
        return FileImage(File(Uri.parse(imageUrl).toFilePath()));
      } else if (imageUrl.startsWith('/') || imageUrl.startsWith('storage/')) {
        return FileImage(File(imageUrl));
      } else if (imageUrl.startsWith('content:')) {
        return NetworkImage(imageUrl);
      }
    } catch (e) {
      debugPrint('Error in _getProfileImageProvider: $e');
    }
    
    return const AssetImage('assets/images/placeholder.png');
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainController = Get.find<MainController>();
    final currentUserAvatar = mainController.user.value?.profileImageUrl ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // User avatar
                GestureDetector(
                  onTap: onProfileTap,
                  child: FutureBuilder<ImageProvider?>(
                    future: _getProfileImage(post.userAvatar.isNotEmpty ? post.userAvatar : currentUserAvatar),
                    builder: (context, snapshot) {
                      // If we have data and it's not null
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: snapshot.data,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('Error loading profile image: $exception');
                          },
                          
                        );
                      }
                      
                      // Show the current user's profile image as a fallback while loading or if no data
                      if (currentUserAvatar.isNotEmpty) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: _getProfileImageProvider(currentUserAvatar),
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('Error loading fallback profile image: $exception');
                          },
                          child: const Icon(Icons.person),
                        );
                      }
                      
                      // Default fallback
                      return const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12.0),
                // Username
                Text(
                  post.username.isNotEmpty ? post.username : 'Unknown User',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          
          // Post image
          GestureDetector(
            onDoubleTap: onLike,
            child: post.imageUrl.isNotEmpty
                ? _buildPostImage(theme)
                : Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          
          // Post actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Like button
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : null,
                  ),
                  onPressed: onLike,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 28,
                ),
                const SizedBox(width: 12.0),
                // Comment button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onComment,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 28,
                ),
                const Spacer(),
                // Save button
                const Icon(Icons.bookmark_border, size: 28),
              ],
            ),
          ),
          
          // Likes count
          if (post.likes > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${post.likes} ${post.likes == 1 ? 'like' : 'likes' }',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4.0),
          ],
          
          // Caption
          if (post.caption.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
                maxLines: showFullCaption ? null : 2,
                overflow: showFullCaption ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              _formatDate(post.createdAt),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12.0,
              ),
            ),
          ),
          
          // Add comment (tappable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: _handleCommentTap,
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  SizedBox(width: 12.0),
                  Text(
                    'Add a comment...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
